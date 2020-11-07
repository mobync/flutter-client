# Mobync

[![Build Status](https://travis-ci.com/mobync/flutter-client.svg?token=zEuAJYpGFRGA9Uoccaqu&branch=master)](https://travis-ci.com/mobync/flutter-client)

## Introduction 

Mobync is a protocol that allows mobile applications running on distributed clients to get synced to a single source of truth to manage users’ data using any storage type. Mobync users Dart and Flutter to implement this protocol and communicate to a web server written in Python.

## Mobync Flutter Client Package

Using Mobync, you will wrap your database operations in such a way that any local data will get synced to a remote server, what will allow users from multiple clients to have an offline-online experience.

## Common usage

You might implement the ```MobyncClient``` abstract class. At this moment we do not support any migration system so it is up to the developer to use one from his preferences. Despite of that, the developer still have to implement the library-specific models. 

```dart
    MyMobyncClient client = MyMobyncClient.instance;
    
    /// Create an instance.
    final obj1 = {'id': 'uuid1', 'field1': 'a', 'field2': 'b'};
    MobyncResponse res1 = await client1.create('model1', obj1);
    
    /// Update an instance.
    final obj = {'id': 'uuid1', 'field1': 'x'};
    MobyncResponse res = await client2.update('model1', obj);

    /// Delete an instance.
    MobyncResponse res = await client1.delete('model1', 'uuid3');

    /// Synchronize.
    await client1.synchronize();
```

## Models
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
}
```

Then you can support the Mobync syncing for a local SQLite database as the example below.

```dart
import 'package:mobync/mobync.dart';
import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlitemobyncdemo/myModel.dart';

class MyMobyncClient extends MobyncClient {
  MyMobyncClient._privateConstructor();
  static final MyMobyncClient instance = MyMobyncClient._privateConstructor();

  String get syncEndpoint => 'http://192.168.0.70:5000/sync';

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
    List<Map> filteredData = [];
    for (Map v in data) {
      bool accepted = filters == null;
      if (filters != null)
        filters.forEach((filter) {
          switch (filter.filterBy) {
            case FilterType.inside:
              accepted = filter.data.contains(v[filter.fieldName]);
              break;
            case FilterType.major:
              accepted = v[filter.fieldName] > filter.data;
              break;
            case FilterType.majorOrEqual:
              accepted = v[filter.fieldName] >= filter.data;
              break;
            case FilterType.minor:
              accepted = v[filter.fieldName] < filter.data;
              break;
            case FilterType.minorOrEqual:
              accepted = v[filter.fieldName] <= filter.data;
              break;
            default:
              break;
          }
        });
      if (accepted) filteredData.add(v);
    }

    filteredData.sort((a, b) => (a['id'] as String).compareTo(b['id']));

    return Future.value(filteredData);
  }
}

```

