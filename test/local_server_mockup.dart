import 'dart:math';
import 'package:mobync/models/models.dart';

class ServerMockup {
  ServerMockup._privateConstructor();
  static final ServerMockup instance = ServerMockup._privateConstructor();

  List<SyncDiff> serverDiffs = [];
  int serverLogicalClock = 0;

  void mergeDiffs(
    int userLogicalClock,
    List<SyncDiff> userDiffs,
  ) {
    if (userDiffs.length > 0) {
      userDiffs.forEach((e) {
        e.logicalClock = serverLogicalClock;
        serverDiffs.add(e);
      });
      serverLogicalClock = max(serverLogicalClock, userLogicalClock) + 1;
    }
  }

  Future<ServerSyncResponse> syncEndpoint(
    int userLogicalClock,
    List<SyncDiff> userDiffs,
  ) {
    var diffs =
        serverDiffs.where((e) => e.logicalClock >= userLogicalClock).toList();

    mergeDiffs(userLogicalClock, userDiffs ?? []);

    return Future.value(ServerSyncResponse(
      success: true,
      logicalClock: serverLogicalClock,
      diffs: diffs,
    ));
  }

  void reset() {
    serverDiffs = [];
    serverLogicalClock = 0;
  }
}
