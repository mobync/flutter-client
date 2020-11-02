import 'dart:math';

import 'package:mobync/mobync.dart';
import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/models.dart';

class ServerMockup {
  ServerMockup._privateConstructor();
  static final ServerMockup instance = ServerMockup._privateConstructor();

  List<SyncDiff> serverDiffs = [];
  int serverLogicalClock = 0;

  void mergeDiffs(
    int userLogicalClock,
    List<SyncDiff> userDiffs,
  ) {
    if (userDiffs.length > 0) {
      serverLogicalClock = max(serverLogicalClock, userLogicalClock) + 1;

      userDiffs.forEach((e) {
        e.logicalClock = serverLogicalClock;
        serverDiffs.add(e);
      });
      serverDiffs.sort();

      serverLogicalClock = max(serverLogicalClock, userLogicalClock) + 1;
    }
  }

  Future<ServerSyncResponse> syncEndpoint(
    int userLogicalClock,
    List<SyncDiff> userDiffs,
  ) {
    var diffs =
        serverDiffs.where((e) => e.logicalClock > userLogicalClock).toList();

    mergeDiffs(userLogicalClock, userDiffs ?? []);

    return Future.value(ServerSyncResponse(serverLogicalClock, diffs));
  }

  void reset() {
    serverDiffs = [];
    serverLogicalClock = 0;
  }
}

class MyMobyncClient extends MobyncClient {
  Map<String, List> db = {
    'model1': <Map>[],
    SyncMetaData.tableName: <Map>[],
    SyncDiff.tableName: <Map>[],
  };

  @override
  Future<Map> commitLocalCreate(String model, Map data) {
    for (int i = 0; i < db[model].length; i++)
      if (db[model][i]['id'] == data['id']) {
        throw Exception('Id already exists for $model and $data!');
      }

    db[model].add(data);

    return Future.value(db[model][db[model].length - 1]);
  }

  @override
  Future<Map> commitLocalUpdate(String model, Map data) {
    for (int i = 0; i < db[model].length; i++)
      if (db[model][i]['id'] == data['id']) {
        data.forEach((key, value) {
          db[model][i][key] = value;
        });
        return Future.value(db[model][i]);
      }
    return Future.value(null);
  }

  @override
  Future<Map> commitLocalDelete(String model, String id) {
    var removedAt;
    for (int i = 0; i < db[model].length; i++)
      if (db[model][i]['id'] == id) {
        removedAt = db[model].removeAt(i);
      }

    return Future.value(removedAt);
  }

  @override
  Future<List<Map>> executeLocalRead(String model, {List<ReadFilter> filters}) {
    List<Map> filteredData = db[model];
    if (filters != null)
      filters.forEach((filter) {
        switch (filter.filterBy) {
          case FilterType.inside:
            filteredData = filteredData.where((v) {
              return filter.data.contains(v[filter.fieldName]);
            }).toList();
            break;
          case FilterType.major:
            filteredData = filteredData.where((v) {
              return v[filter.fieldName] > filter.data;
            }).toList();
            break;
          case FilterType.majorOrEqual:
            filteredData = filteredData.where((v) {
              return v[filter.fieldName] >= filter.data;
            }).toList();
            break;
          case FilterType.minor:
            filteredData = filteredData.where((v) {
              return v[filter.fieldName] < filter.data;
            }).toList();
            break;
          case FilterType.minorOrEqual:
            filteredData = filteredData.where((v) {
              return v[filter.fieldName] <= filter.data;
            }).toList();
            break;
          default:
            break;
        }
      });

    filteredData.sort((a, b) => (a['id'] as String).compareTo(b['id']));

    return Future.value(filteredData);
  }

  Future<ServerSyncResponse> postSyncEndpoint(
      int logicalClock, List<SyncDiff> localDiffs) async {
    ServerMockup instance = ServerMockup.instance;
    ServerSyncResponse res =
        await instance.syncEndpoint(logicalClock, localDiffs);
    return Future.value(res);
  }
}
