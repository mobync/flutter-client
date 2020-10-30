import 'package:mobync/mobync.dart';
import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/meta_sync_model.dart';
import 'package:mobync/models/models.dart';

class MyMobyncClient extends MobyncClient {
  MyMobyncClient._privateConstructor();
  static final MyMobyncClient instance = MyMobyncClient._privateConstructor();

  Map<String, List> _data = {
    'model1': [],
    SyncMetaData.tableName: [],
    SyncDiff.tableName: [],
  };

  @override
  Future<void> createExecute(String where, Map what) {
    for (int i = 0; i < _data[where].length; i++)
      if (_data[where][i]['id'] == what['id']) {
        throw Exception('Id already exists!');
      }

    _data[where].add(what);
  }

  @override
  Future<void> updateExecute(String where, Map what) {
    for (int i = 0; i < _data[where].length; i++)
      if (_data[where][i]['id'] == what['id']) {
        what.forEach((key, value) {
          _data[where][i][key] = value;
        });
      }
  }

  @override
  Future<void> deleteExecute(String where, String id) {
    var removedAt;
    for (int i = 0; i < _data[where].length; i++)
      if (_data[where][i]['id'] == id) {
        removedAt = _data[where].removeAt(i);
      }

    if (removedAt == null) throw Exception('Element not found.');
  }

  @override
  Future<List> readExecute(String where, {List<ReadFilter> filters}) {
    List _filteredData = _data[where];
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
}
