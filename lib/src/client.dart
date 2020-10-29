library mobync;

import 'package:mobync/src/constants/message_contants.dart';
import 'package:mobync/src/constants/sync_op_log_constants.dart';
import 'package:mobync/src/models/models.dart';
import 'package:mobync/src/utils/utils.dart';
import 'package:synchronized/synchronized.dart';

/// Mobync Client absctract class
abstract class MobyncClient {
  Lock _lock;

  Lock get lock {
    if (_lock == null) _lock = new Lock();
    return _lock;
  }

  void _addSyncOperationLog(SyncOperation log) {}

  Future<void> _logOperation(
    String opType,
    String where,
    Map what,
  ) async {
    final log = new SyncOperation(
      logicalClock: 123,
      timestamp: getCurrentTimestamp(),
      operationType: opType,
      operationLocation: where,
      operationInput: what,
    );
    _addSyncOperationLog(log);
  }

  Future<MobyncResponse> runOperation(
    String opType,
    String where,
    Map what,
    Function runOp,
  ) async {
    return await lock.synchronized(() async {
      await runOp();
      await _logOperation(opType, where, what);

      var response = MobyncResponse(
        success: true,
        message: K_CLIENT_OP_SUCCESS,
      );
      return Future.value(response);
    });
  }

  Future<MobyncResponse> create(String where, Map what);
  Future<MobyncResponse> update(String where, Map what);
  Future<MobyncResponse> delete(String where, String uid);
}
