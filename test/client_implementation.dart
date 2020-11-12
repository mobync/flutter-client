import 'package:mobync/mobync.dart';
import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/models.dart';

import 'local_server_mockup.dart';

class MyMobyncClient extends MobyncClient {
  Map<String, List> db = {
    'model1': <Map>[],
    SyncMetaData.tableName: <Map>[],
    SyncDiff.tableName: <Map>[],
  };

  @override
  Future<int> commitLocalCreate(String model, Map data) {
    for (int i = 0; i < db[model].length; i++)
      if (db[model][i]['id'] == data['id']) {
        throw Exception('Id already exists for $model and $data!');
      }

    db[model].add(data);

    return Future.value(1);
  }

  @override
  Future<int> commitLocalUpdate(String model, Map data) {
    for (int i = 0; i < db[model].length; i++)
      if (db[model][i]['id'] == data['id']) {
        data.forEach((key, value) {
          db[model][i][key] = value;
        });
        return Future.value(1);
      }
    return Future.value(0);
  }

  @override
  Future<int> commitLocalDelete(String model, String id) {
    for (int i = 0; i < db[model].length; i++)
      if (db[model][i]['id'] == id) {
        db[model].removeAt(i);
        return Future.value(1);
      }
    return Future.value(0);
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

  @override
  Future<String> getAuthToken() {
    return Future.value('asdf');
  }

  String get syncEndpoint => "http://127.0.0.1:5000/sync";

  @override
  Future<ServerSyncResponse> postSyncEndpoint(
      int logicalClock, List<SyncDiff> localDiffs, String authToken) async {
    ServerMockup instance = ServerMockup.instance;
    ServerSyncResponse res =
    await instance.syncEndpoint(logicalClock, localDiffs);
    return Future.value(res);
  }
}
