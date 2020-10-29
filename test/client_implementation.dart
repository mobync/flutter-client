import 'package:mobync/mobync.dart';
import 'package:mobync/src/models/models.dart';

class MyMobyncClient extends MobyncClient {
  MyMobyncClient._privateConstructor();
  static final MyMobyncClient instance = MyMobyncClient._privateConstructor();

  Map<String, Map> _data = {};

  @override
  Future<MobyncResponse> create(String where, Map what) {
    /// Check if model exists.
    if (!_data.containsKey(where)) _data[where] = {};

    if (what.containsKey('id') && _data[where].containsKey(what['id']))
      return Future.value(MobyncResponse(
        success: false,
        message: 'Object id already exists',
      ));

    _data[where][what['id']] = what;

    return Future.value(MobyncResponse(
      success: true,
      message: 'Objected created.',
    ));
  }

  @override
  Future<MobyncResponse> update(String where, Map what) {
    if (!_data.containsKey(where) || _data[where][what['id']] == null)
      return Future.value(MobyncResponse(
        success: false,
        message: 'Object id doesnt exist',
      ));

    what.forEach((key, value) {
      _data[where][what['id']][key] = value;
    });

    return Future.value(MobyncResponse(
      success: true,
      message: 'Objected updated.',
    ));
  }

  @override
  Future<MobyncResponse> delete(String where, String id) {
    if (!_data.containsKey(where) || !_data[where].containsKey(id))
      return Future.value(MobyncResponse(
        success: false,
        message: 'Object id doesnt exist',
      ));

    _data[where].remove(id);

    return Future.value(MobyncResponse(
      success: true,
      message: 'Objected deleted.',
    ));
  }

  Future<MobyncResponse> read(String where) {
    if (!_data.containsKey(where))
      return Future.value(MobyncResponse(
        success: false,
      ));

    return Future.value(MobyncResponse(
      success: true,
      data: _data[where].values.toList(),
    ));
  }
}
