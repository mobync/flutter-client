library mobync;

import 'package:mobync/src/client_helper.dart';
import 'package:mobync/src/models/models.dart';
import 'package:mobync/src/utils/utils.dart';

/// Mobync Client absctract class
abstract class MobyncClient {
  Future<void> logSyncOperation(
    String opType,
    String where,
    Map what,
  ) async {
    MobyncClientHelper helper = MobyncClientHelper.instance;

    final log = new SyncOperation(
      logicalClock: helper.logicalClock,
      timestamp: getCurrentTimestamp(),
      operationType: opType,
      operationLocation: where,
      operationInput: what,
    );

    helper.addSyncOperation(log);
  }

  Future<MobyncResponse> create(String where, Map what);
  Future<MobyncResponse> update(String where, Map what);
  Future<MobyncResponse> delete(String where, String uid);
}
