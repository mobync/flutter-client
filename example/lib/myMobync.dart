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

    filteredData.sort((a, b) => (a['id'] as String).compareTo(b['id']));

    return Future.value(filteredData);
  }

  @override
  Future<String> getAuthToken() {
    return Future.value('asdf');
  }
}
