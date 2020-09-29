library mobync;

import 'package:mobync/src/constants/sync_op_log_constants.dart';
import 'package:mobync/src/models/models.dart';
import 'package:mobync/src/utils/utils.dart';


/// Mobync Client absctract class
abstract class MobyncClient {
  void _addSyncOperationLog(SyncOperation log){

  }

  Map create(String where, Map what){

    final log = new SyncOperation(
      logicalClock: 123,
      timestamp: getCurrentTimestamp(),
      operationType: K_SYNC_OP_CREATE,
      operationLocation: where,
      operationInput: what,
    );
    _addSyncOperationLog(log);
    /// then sync
  }

  Map update(String where, Map what){
    final log = new SyncOperation(
      logicalClock: 123,
      timestamp: getCurrentTimestamp(),
      operationType: K_SYNC_OP_UPDATE,
      operationLocation: where,
      operationInput: what,
    );
    _addSyncOperationLog(log);
    /// then sync
  }

  bool delete(String where, Map what){
    final log = new SyncOperation(
      logicalClock: 123,
      timestamp: getCurrentTimestamp(),
      operationType: K_SYNC_OP_DELETE,
      operationLocation: where,
      operationInput: what,
    );
    _addSyncOperationLog(log);
    /// then sync
  }

  Map read(String where, Map what){

  }
}
