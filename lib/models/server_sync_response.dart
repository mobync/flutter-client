import 'package:mobync/models/models.dart';

/// Typed response to be returned when performing Mobync operations on the Flutter app.
/// The [success] flag can not not be null.
class ServerSyncResponse {
  ServerSyncResponse({
    this.success,
    this.message,
    this.logicalClock,
    this.diffs,
  }) : assert((success == false) ||
            (success == true && logicalClock >= 0 && diffs is List));

  /// Flag to indicate if the operation succeeded.
  final bool success;

  /// Message in case it has failed.
  final String message;

  /// Logical clock from upstream.
  final int logicalClock;

  /// Diffs from upstream to be executed on the local storage.
  final List<SyncDiff> diffs;

  @override
  String toString() {
    return 'ServerSyncResponse: {logicalClock: $logicalClock, diffs: $diffs}';
  }
}
