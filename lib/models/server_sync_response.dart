import 'package:mobync/models/models.dart';

class ServerSyncResponse {
  ServerSyncResponse({
    this.success,
    this.message,
    this.logicalClock,
    this.diffs,
  }) : assert((success == false) ||
            (success == true && logicalClock >= 0 && diffs is List));

  final bool success;
  final String message;
  final int logicalClock;
  final List<SyncDiff> diffs;

  @override
  String toString() {
    return 'ServerSyncResponse: {logicalClock: $logicalClock, diffs: $diffs, success: $success, message: $message}';
  }
}
