# Mobync

## Introduction 

Mobync is a protocol that allows mobile applications running on distributed clients to get synced to a single source of truth to manage users’ data using any storage type. Mobync users Dart and Flutter to implement this protocol and communicate to a web server written in Python.

## Mobync Flutter Client Package

Using Mobync, you will wrap your database operations in such a way that any local data will get synced to a remote server, what will allow users from multiple clients to have an offline-online experience.

## Integration Test for multiple clients syncing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobync/models/models.dart';

import 'client_implementation.dart';

void main() {
  MyMobyncClient client1, client2;

  setUpAll(() async {
    client1 = MyMobyncClient();
    client2 = MyMobyncClient();
  });

  test('client 1 creates local object and synchronizes', () async {
    final obj1 = {'id': 'uuid1', 'field1': 'a'};
    MobyncResponse res1 = await client1.create('model1', obj1);
    expect(res1.success, true);

    await client1.synchronize();

    MobyncResponse res = await client1.read('model1');
    expect(res.success, true);
    expect(res.data, [
      {'id': 'uuid1', 'field1': 'a'},
    ]);
  });

  test('client 1 and 2 create local objects but neither synchronize', () async {
    final obj1 = {'id': 'uuid2', 'field1': 'b'};
    MobyncResponse res1 = await client1.create('model1', obj1);
    expect(res1.success, true);

    final obj2 = {'id': 'uuid3', 'field1': 'c'};
    MobyncResponse res2 = await client2.create('model1', obj2);
    expect(res2.success, true);
  });

  test('client 2 synchonizes', () async {
    await client2.synchronize();

    MobyncResponse res = await client2.read('model1');
    expect(res.success, true);
    expect(res.data, [
      {'id': 'uuid1', 'field1': 'a'},
      {'id': 'uuid3', 'field1': 'c'},
    ]);
  });

  test('client 1 synchronizes', () async {
    await client1.synchronize();

    MobyncResponse res = await client1.read('model1');
    expect(res.success, true);
    expect(res.data, [
      {'id': 'uuid1', 'field1': 'a'},
      {'id': 'uuid2', 'field1': 'b'},
      {'id': 'uuid3', 'field1': 'c'},
    ]);
  });

  test('client 2 synchronizes', () async {
    await client2.synchronize();

    MobyncResponse res = await client2.read('model1');
    expect(res.success, true);
    expect(res.data, [
      {'id': 'uuid1', 'field1': 'a'},
      {'id': 'uuid2', 'field1': 'b'},
      {'id': 'uuid3', 'field1': 'c'},
    ]);
  });

  test('client 2 updates client 1 object and both synchronizes', () async {
    final obj = {'id': 'uuid1', 'field1': 'x'};
    MobyncResponse res = await client2.update('model1', obj);
    expect(res.success, true);

    await client2.synchronize();
    await client1.synchronize();

    MobyncResponse res1 = await client1.read('model1');
    expect(res1.success, true);
    expect(res1.data, [
      {'id': 'uuid1', 'field1': 'x'},
      {'id': 'uuid2', 'field1': 'b'},
      {'id': 'uuid3', 'field1': 'c'},
    ]);

    MobyncResponse res2 = await client2.read('model1');
    expect(res2.success, true);
    expect(res2.data, [
      {'id': 'uuid1', 'field1': 'x'},
      {'id': 'uuid2', 'field1': 'b'},
      {'id': 'uuid3', 'field1': 'c'},
    ]);
  });

  test('client 1 deletes client 2 object and both synchronizes', () async {
    MobyncResponse res = await client1.delete('model1', 'uuid3');
    expect(res.success, true);

    await client1.synchronize();
    await client2.synchronize();

    MobyncResponse res1 = await client1.read('model1');
    expect(res1.success, true);
    expect(res1.data, [
      {'id': 'uuid1', 'field1': 'x'},
      {'id': 'uuid2', 'field1': 'b'},
    ]);

    MobyncResponse res2 = await client2.read('model1');
    expect(res2.success, true);
    expect(res2.data, [
      {'id': 'uuid1', 'field1': 'x'},
      {'id': 'uuid2', 'field1': 'b'},
    ]);
  });
}

```

## Common usage

You might implement the ```Mobync Client``` abstract class. At this moment we do not support any migration system so it is up to the developer to use one from his preferences. See the example below for a SQLite local storage.

Suppose you have a model like the following

```dart
class MyModel {
  MyModel({
    this.id,
    this.field1,
  });

  static final String tableName = 'MyModel';
  String id, field1;

  MyModel.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    field1 = map['field1'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'id': id,
      'field1': field1,
    };

    return map;
  }

  @override
  String toString() {
    return 'SyncDiff: {'
        'id: $id,'
        'field1: $field1,'
        '}';
  }
}
```

Then you can support the Mobync syncing for a local SQLite database as the example below.


```dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mobync/mobync.dart';
import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlitemobyncdemo/myModel.dart';
import 'package:http/http.dart' as http;

class MyMobyncClient extends MobyncClient {
  MyMobyncClient._privateConstructor();
  static final MyMobyncClient instance = MyMobyncClient._privateConstructor();

  Database _database;
  Future<Database> get database async {
    if (_database == null) {
      var databasesPath = await getDatabasesPath();
      String path = '$databasesPath/demo.db';
      _database = await openDatabase(path, version: 1, onCreate: _onCreate);
    }

    return _database;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE ${MyModel.tableName} (
          id TEXT PRIMARY KEY,
          field1 TEXT
        )''');
    await db.execute('''
        CREATE TABLE ${SyncDiff.tableName} (
          id TEXT PRIMARY KEY,
          logicalClock INTEGER,
          utcTimestamp INTEGER,
          type TEXT,
          model TEXT,
          jsonData TEXT
        )''');
    await db.execute('''
        CREATE TABLE ${SyncMetaData.tableName} (
          id TEXT PRIMARY KEY,
          logicalClock INTEGER
        )''');
  }

  @override
  Future<Map> commitLocalCreate(String model, Map<String, dynamic> data) async {
    Database db = await database;
    int res = await db.insert(model, data);
    if (res == 0) return null;
  }

  @override
  Future<Map> commitLocalUpdate(String model, Map<String, dynamic> data) async {
    Database db = await database;
    int res =
        await db.update(model, data, where: 'id=?', whereArgs: [data['id']]);
    if (res == 0) return null;
    return {};
  }

  @override
  Future<Map> commitLocalDelete(String model, String id) async {
    Database db = await database;
    int res = await db.delete(model, where: 'id=?', whereArgs: [id]);
    if (res == 0) return null;
    return {};
  }

  @override
  Future<List<Map>> executeLocalRead(String model,
      {List<ReadFilter> filters}) async {
    Database db = await database;
    List<Map> data = await db.query(model);

    if (filters != null)
      filters.forEach((filter) {
        switch (filter.filterBy) {
          case FilterType.inside:
            data = data.where((v) {
              return filter.data.contains(v[filter.fieldName]);
            }).toList();
            break;
          case FilterType.major:
            data = data.where((v) {
              return v[filter.fieldName] > filter.data;
            }).toList();
            break;
          case FilterType.majorOrEqual:
            data = data.where((v) {
              return v[filter.fieldName] >= filter.data;
            }).toList();
            break;
          case FilterType.minor:
            data = data.where((v) {
              return v[filter.fieldName] < filter.data;
            }).toList();
            break;
          case FilterType.minorOrEqual:
            data = data.where((v) {
              return v[filter.fieldName] <= filter.data;
            }).toList();
            break;
          default:
            break;
        }
      });

    return Future.value(data);
  }

  Future<ServerSyncResponse> postSyncEndpoint(
      int logicalClock, List<SyncDiff> localDiffs) async {
    try {
      List<SyncDiff> diffs = await getSyncDiffs();
      String body = jsonEncode({
        'logicalClock': await getLogicalClock(),
        'diffs': diffs.map((e) => e.toMap()).toList(),
      });
      print(body);

      var resp = await http.post('http://192.168.0.70:5000/sync',
          headers: {
            'Content-Type': 'application/json',
          },
          body: body);
      if (resp.statusCode != 200) throw Exception('xxxx');
      Map res = jsonDecode(resp.body);
      List<SyncDiff> syncDiffs =
          (res['diffs'] as List).map((e) => SyncDiff.fromMap(e)).toList();
      syncDiffs.sort();
      return Future.value(ServerSyncResponse(res['logicalClock'], syncDiffs));
    } catch (e) {
      print(e);
    }
    return Future.value(ServerSyncResponse(0, []));
  }
}
```

