import 'dart:math';

import 'package:mobync/mobync.dart';
import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/meta_sync_model.dart';
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
    serverLogicalClock = max(serverLogicalClock, userLogicalClock) + 1;

    userDiffs.forEach((e) {
      e.logicalClock = serverLogicalClock;
      serverDiffs.add(e);
    });
    serverDiffs.sort();
  }

  Future<ServerSyncResponse> syncEndpoint(
    int userLogicalClock,
    List<SyncDiff> userDiffs,
  ) {
    var diffs = serverDiffs
        .where((e) => e.logicalClock > userLogicalClock + 1)
        .toList();

    mergeDiffs(userLogicalClock, userDiffs);

    return Future.value(ServerSyncResponse(serverLogicalClock, diffs));
  }
}

class MyMobyncClient extends MobyncClient {
  MyMobyncClient._privateConstructor();
  static final MyMobyncClient instance = MyMobyncClient._privateConstructor();

  Map<String, List> _data = {
    'model1': <Map>[],
    SyncMetaData.tableName: <Map>[],
    SyncDiff.tableName: <Map>[],
  };

  @override
  Future<Map> createExecute(String model, Map metadata) {
    for (int i = 0; i < _data[model].length; i++)
      if (_data[model][i]['id'] == metadata['id']) {
        throw Exception('Id already exists!');
      }

    _data[model].add(metadata);

    return Future.value(_data[model][_data[model].length - 1]);
  }

  @override
  Future<Map> updateExecute(String model, Map metadata) {
    for (int i = 0; i < _data[model].length; i++)
      if (_data[model][i]['id'] == metadata['id']) {
        _data[model][i].addAll(metadata);
        return Future.value(_data[model][i]);
      }
    return Future.value(null);
  }

  @override
  Future<Map> deleteExecute(String model, String id) {
    var removedAt;
    for (int i = 0; i < _data[model].length; i++)
      if (_data[model][i]['id'] == id) {
        removedAt = _data[model].removeAt(i);
      }

    return Future.value(removedAt);
  }

  @override
  Future<List<Map>> readExecute(String model, {List<ReadFilter> filters}) {
    List<Map> _filteredData = _data[model];
    if (filters != null)
      filters.forEach((filter) {
        switch (filter.filterBy) {
          case FilterType.inside:
            _filteredData = _filteredData.where((v) {
              return filter.data.contains(v[filter.fieldName]);
            }).toList();
            break;
          case FilterType.major:
            _filteredData = _filteredData.where((v) {
              return v[filter.fieldName] > filter.data;
            }).toList();
            break;
          case FilterType.majorOrEqual:
            _filteredData = _filteredData.where((v) {
              return v[filter.fieldName] >= filter.data;
            }).toList();
            break;
          case FilterType.minor:
            _filteredData = _filteredData.where((v) {
              return v[filter.fieldName] < filter.data;
            }).toList();
            break;
          case FilterType.minorOrEqual:
            _filteredData = _filteredData.where((v) {
              return v[filter.fieldName] <= filter.data;
            }).toList();
            break;
          default:
            break;
        }
      });

    return Future.value(_filteredData);
  }

  Future<ServerSyncResponse> fetchUpstreamData(
      int logicalClock, List<SyncDiff> localDiffs) async {
    ServerMockup instance = ServerMockup.instance;
    ServerSyncResponse res =
        await instance.syncEndpoint(logicalClock, localDiffs);
    return Future.value(res);
  }
}
