import 'package:mobync/mobync.dart';
import 'package:mobync/src/models/meta_sync_model.dart';
import 'package:mobync/src/models/models.dart';

class MyMobyncClient extends MobyncClient {
  MyMobyncClient._privateConstructor();
  static final MyMobyncClient instance = MyMobyncClient._privateConstructor();

  Map<String, List> _data = {
    'model1': [],
    SyncMetaData.tableName: [],
    SyncOperation.tableName: [],
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
  Future<MobyncResponse> read(String where) {
    try {
      return Future.value(MobyncResponse(
        success: true,
        data: _data[where],
      ));
    } catch (e) {
      return Future.value(MobyncResponse(
        success: false,
        message: e.toString(),
      ));
    }
  }
}
