import 'package:mobync/models/models.dart';

class ServerSyncResponse {
  ServerSyncResponse(
    this.logicalClock,
    this.diffs,
  );

  final int logicalClock;
  final List<SyncDiff> diffs;

  @override
  String toString() {
    return 'ServerSyncResponse: {logicalClock: $logicalClock, diffs: $diffs}';
  }
}
