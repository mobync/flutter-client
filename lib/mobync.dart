library mobync;

import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/models.dart';

abstract class MobyncClient {
  Future<void> createExecute(String where, Map what);
  Future<void> updateExecute(String where, Map what);
  Future<void> deleteExecute(String where, String uid);
  Future<List> readExecute(String where, {List<ReadFilter> filters});

  Future<List> getSyncOperations({int logicalClock}) async {
    if (logicalClock == null) logicalClock = await getLogicalClock();
    return await readExecute(
      SyncDiff.tableName,
      filters: [
        ReadFilter('logicalClock', FilterType.majorOrEqual, logicalClock)
      ],
    );
  }

  Future<int> getLogicalClock() async {
    return await readExecute(SyncMetaData.tableName).then((value) {
      return value.length > 0 ? value[0] : 0;
    });
  }

  Future<void> setLogicalClock(int logicalClock) async {
    await updateExecute(
      SyncMetaData.tableName,
      {'id': SyncMetaData.id, 'logicalClock': logicalClock},
    );
  }

  Future<MobyncResponse> create(String where, Map what) async {
    try {
      await createExecute(where, what);
      await createExecute(
          SyncDiff.tableName,
          SyncDiff(
            logicalClock: await getLogicalClock(),
            timestamp: DateTime.now().millisecondsSinceEpoch,
            operationType: CREATE_OPERATION,
            modelName: where,
            operationMetadata: what,
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
      await updateExecute(where, what);
      await createExecute(
          SyncDiff.tableName,
          SyncDiff(
            logicalClock: await getLogicalClock(),
            timestamp: DateTime.now().millisecondsSinceEpoch,
            operationType: UPDATE_OPERATION,
            modelName: where,
            operationMetadata: what,
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

  Future<MobyncResponse> delete(String where, String id) async {
    try {
      await deleteExecute(where, id);
      await createExecute(
          SyncDiff.tableName,
          SyncDiff(
            logicalClock: await getLogicalClock(),
            timestamp: DateTime.now().millisecondsSinceEpoch,
            operationType: DELETE_OPERATION,
            modelName: where,
            operationMetadata: {'id': id},
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

  Future<MobyncResponse> read(String where, {List<ReadFilter> filters}) async {
    try {
      List _filteredData = await readExecute(where, filters: filters);
      return Future.value(MobyncResponse(
        success: true,
        data: _filteredData,
      ));
    } catch (e) {
      return Future.value(MobyncResponse(
        success: false,
        message: e.toString(),
      ));
    }
  }
}
