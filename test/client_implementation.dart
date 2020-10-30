import 'package:mobync/mobync.dart';
import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/meta_sync_model.dart';
import 'package:mobync/models/models.dart';

class ServerMockup {
  ServerMockup._privateConstructor();
  static final ServerMockup instance = ServerMockup._privateConstructor();

  List<SyncDiff> data = [];

  Future<List<SyncDiff>> syncEndpoint(List<SyncDiff> userDiffs) {
    return Future.value(data);
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

  Future<List<SyncDiff>> fetchUpstreamDiffs(List<SyncDiff> localDiffs) async {
    ServerMockup instance = ServerMockup.instance;
    List<SyncDiff> upstreamDiffs = await instance.syncEndpoint(localDiffs);
    return Future.value(upstreamDiffs);
  }
}
