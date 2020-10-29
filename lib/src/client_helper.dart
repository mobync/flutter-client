import 'dart:math';

import 'package:mobync/src/models/models.dart';

class MobyncClientHelper {
  MobyncClientHelper._privateConstructor();
  static final MobyncClientHelper instance =
      MobyncClientHelper._privateConstructor();

  int logicalClock = 0;
  List<SyncOperation> syncOperationList = [];

  void _updateLogicalClock(int upstreamLogicalClock) {
    logicalClock = max(logicalClock, upstreamLogicalClock);
  }

  Future<void> addSyncOperation(SyncOperation syncOperation) {
    syncOperationList.add(syncOperation);
  }

  Future<List<SyncOperation>> getSyncOperationList() {
    syncOperationList.sort();
    return Future.value(syncOperationList);
  }
}
