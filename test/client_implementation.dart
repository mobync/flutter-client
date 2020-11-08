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
      userDiffs.forEach((e) {
        e.logicalClock = serverLogicalClock;
        serverDiffs.add(e);
      });
//      serverDiffs.sort();

      serverLogicalClock = max(serverLogicalClock, userLogicalClock) + 1;
    }
  }

  Future<ServerSyncResponse> syncEndpoint(
    int userLogicalClock,
    List<SyncDiff> userDiffs,
  ) {
    var diffs =
        serverDiffs.where((e) => e.logicalClock >= userLogicalClock).toList();

    mergeDiffs(userLogicalClock, userDiffs ?? []);

    return Future.value(ServerSyncResponse(
      success: true,
      logicalClock: serverLogicalClock,
      diffs: diffs,
    ));
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
    List<Map> filteredData = [];
    for (Map v in db[model]) {
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

  String get syncEndpoint => "http://127.0.0.1:5000/sync";

//  @override
//  Future<ServerSyncResponse> postSyncEndpoint(
//      int logicalClock, List<SyncDiff> localDiffs) async {
//    ServerMockup instance = ServerMockup.instance;
//    ServerSyncResponse res =
//        await instance.syncEndpoint(logicalClock, localDiffs);
//    return Future.value(res);
//  }
}
