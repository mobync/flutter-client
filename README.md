<div align="center">
<p>
    <img width="80" src="https://raw.githubusercontent.com/mobync/python-server/master/examples/in_memory_server_example/example_data/images/logo-round.png">
</p>
<h1>The Mobync Flutter Lib</h1>
</div>

<div align="center">

[![Build Status](https://travis-ci.com/mobync/flutter-client.svg?token=zEuAJYpGFRGA9Uoccaqu&branch=master)](https://travis-ci.com/mobync/flutter-client)

</div>

## Why use mobync

Mobync is a synchronization library aimed to facilitate online-offline sync between multiple devices for any frontend, any backend, and any database.

This repository implements the Mobync client library in Flutter, which means you can start using Mobync sync on your client regardless of which backend you might be using or even which database.

As Mobync aims to provide online-offline sync between client and server, you will need to use the mobync library both on your frontend application and backend.

Currently, Mobync has a Dart client implementation and a Python server implementation. That means you can plug Mobync on your Flutter app and provide online-offline synchronization.

### Online-offline synchronization

Online-offline synchronization means that your app will work seamlessly both online and offline, the user can use without noticing any difference, and you can implement your app not worrying about this when using Mobync.

Mobync will automatically make your app store your changes locally on your app's database when the user has no connection, and automatically sync the data to the backend when the user has internet.

### Multiple devices support

Your user can use your service across multiple devices at the same time and all will have their data synchronized with Mobync.

Mobync implements a protocol that merges the user data and resolves conflicts. 

Mobync's protocol allows mobile applications running on distributed clients to get synced to a single source of truth to manage users’ data using any storage type. Mobync users Dart and Flutter to implement this protocol and communicate to a web server written in Python.

## Example projects

You can see some example projects using mobync on [Examples](https://github.com/mobync/flutter-client/blob/master/example).


## Mobync Flutter Client Package

Using Mobync, you will wrap your database operations in such a way that any local data will get synced to a remote server, what will allow users from multiple clients to have an offline-online experience.

## Common usage
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

You might implement the ```MobyncClient``` abstract class. At this moment we do not support any migration system so it is up to the developer to use one from his preferences. Despite of that, the developer still have to implement the library-specific models. 

On the following snippet you can check out a Mobync implementation using SQLite on the client storage.

```dart
import 'package:mobync/mobync.dart';
import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:example/myModel.dart';

class MyMobyncClient extends MobyncClient {
  MyMobyncClient._privateConstructor();
  static final MyMobyncClient instance = MyMobyncClient._privateConstructor();

  String get syncEndpoint => 'http://127.0.0.1:5000/sync';

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
    await _createMyTables(db, version);
  }
  
  Future<void> _createMyTables(Database db, int version) async {
    /// ...
  }

  @override
  Future<int> commitLocalCreate(String model, Map<String, dynamic> data) async {
    Database db = await database;
    return await db.insert(model, data);
  }

  @override
  Future<int> commitLocalUpdate(String model, Map<String, dynamic> data) async {
    Database db = await database;
    return await db.update(model, data, where: 'id=?', whereArgs: [data['id']]);
  }

  @override
  Future<int> commitLocalDelete(String model, String id) async {
    Database db = await database;
    return await db.delete(model, where: 'id=?', whereArgs: [id]);
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
    return Future.value(filteredData);
  }

  @override
  Future<String> getAuthToken() {
    return Future.value('asdf');
  }
}

```