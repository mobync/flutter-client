import 'dart:math';

import 'package:mobync/models/models.dart';

class ServerMockup {
  ServerMockup._privateConstructor();
  static final ServerMockup instance = ServerMockup._privateConstructor();

  /// Mockup for the SyncOperation lists from each user
  Map<String, List<SyncDiff>> syncOperationListByOwner = {};

  /// Mockup for the LogicalClock from each user
  Map<String, int> logicalClockByOwner = {};

  void _updateLogicalClockForOwner(String owner, int clientLogicalClock) {
    if (!logicalClockByOwner.containsKey(owner)) logicalClockByOwner[owner] = 0;

    logicalClockByOwner[owner] =
        max(logicalClockByOwner[owner], clientLogicalClock) + 1;
  }

  Future<ServerSyncResponse> sync({
    String owner,
    int clientLogicalClock,
    List<SyncDiff> userSyncOperationList,
  }) {
    if (!syncOperationListByOwner.containsKey(owner)) {
      syncOperationListByOwner[owner] = [];
    }
    if (!logicalClockByOwner.containsKey(owner)) {
      logicalClockByOwner[owner] = 0;
    }

    if (userSyncOperationList.length > 0) {
      _updateLogicalClockForOwner(owner, clientLogicalClock);

      /// Silly merge, just sort by logical clock and timestamp.
      syncOperationListByOwner[owner].addAll(userSyncOperationList);
      syncOperationListByOwner[owner].sort();
    }

    var syncOperationResponseList = syncOperationListByOwner[owner]
        .where((el) => el.logicalClock > clientLogicalClock)
        .toList();
    var response = ServerSyncResponse(
      logicalClock: logicalClockByOwner[owner],
      diffs: syncOperationResponseList,
    );
    return Future.value(response);
  }
}
