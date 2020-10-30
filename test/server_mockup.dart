import 'dart:math';

import 'package:mobync/models/models.dart';

class ServerMockup {
  ServerMockup._privateConstructor();
  static final ServerMockup instance = ServerMockup._privateConstructor();

  /// Mockup for the SyncDiffs from each user
  Map<String, List<SyncDiff>> syncDiffsByOwner = {};

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
    List<SyncDiff> userSyncDiffs,
  }) {
    if (!syncDiffsByOwner.containsKey(owner)) {
      syncDiffsByOwner[owner] = [];
    }
    if (!logicalClockByOwner.containsKey(owner)) {
      logicalClockByOwner[owner] = 0;
    }

    if (userSyncDiffs.length > 0) {
      _updateLogicalClockForOwner(owner, clientLogicalClock);

      /// Silly merge, just sort by logical clock and timestamp.
      syncDiffsByOwner[owner].addAll(userSyncDiffs);
      syncDiffsByOwner[owner].sort();
    }

    var syncDiffsResponse = syncDiffsByOwner[owner]
        .where((el) => el.logicalClock > clientLogicalClock)
        .toList();
    var response = ServerSyncResponse(
      logicalClock: logicalClockByOwner[owner],
      diffs: syncDiffsResponse,
    );
    return Future.value(response);
  }
}
