library mobync;

import 'package:mobync/src/constants/constants.dart';
import 'package:mobync/src/models/meta_sync_model.dart';
import 'package:mobync/src/models/models.dart';

abstract class MobyncClient {
  Future<void> createExecute(String where, Map what);
  Future<void> updateExecute(String where, Map what);
  Future<void> deleteExecute(String where, String uid);
  Future<MobyncResponse> read(String where);

  Future<int> getLogicalClock() async {
    return await read(SyncMetaData.tableName).then((value) {
      if (value.success && value.data.length > 0)
        return value.data[0];
      else
        return 0;
    });
  }

  Future<void> setLogicalClock(int logicalClock) async {
    await update(
        SyncMetaData.tableName, {'id': '0', 'logicalClock': logicalClock});
  }

  Future<MobyncResponse> create(String where, Map what) async {
    try {
      createExecute(where, what);
      createExecute(
          SyncOperation.tableName,
          SyncOperation(
            logicalClock: await getLogicalClock(),
            timestamp: DateTime.now().millisecondsSinceEpoch,
            operationType: K_SYNC_OP_CREATE,
            operationLocation: where,
            operationInput: what,
          ).toMap());

      return Future.value(MobyncResponse(
        success: true,
        message: 'Objected created.',
      ));
    } catch (e) {
      return Future.value(MobyncResponse(
        success: false,
        message: e.toString(),
      ));
    }
  }

  Future<MobyncResponse> update(String where, Map what) async {
    try {
      updateExecute(where, what);
      createExecute(
          SyncOperation.tableName,
          SyncOperation(
            logicalClock: await getLogicalClock(),
            timestamp: DateTime.now().millisecondsSinceEpoch,
            operationType: K_SYNC_OP_UPDATE,
            operationLocation: where,
            operationInput: what,
          ).toMap());

      return Future.value(MobyncResponse(
        success: true,
        message: 'Objected updated.',
      ));
    } catch (e) {
      return Future.value(MobyncResponse(
        success: false,
        message: e.toString(),
      ));
    }
  }

  Future<MobyncResponse> delete(String where, String uuid) async {
    try {
      deleteExecute(where, uuid);
      createExecute(
          SyncOperation.tableName,
          SyncOperation(
            logicalClock: await getLogicalClock(),
            timestamp: DateTime.now().millisecondsSinceEpoch,
            operationType: K_SYNC_OP_DELETE,
            operationLocation: where,
            operationInput: {},
          ).toMap());

      return Future.value(MobyncResponse(
        success: true,
        message: 'Objected updated.',
      ));
    } catch (e) {
      return Future.value(MobyncResponse(
        success: false,
        message: e.toString(),
      ));
    }
  }
}
