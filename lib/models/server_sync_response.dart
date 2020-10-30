import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobync/models/models.dart';

class ServerSyncResponse extends Equatable {
  ServerSyncResponse({
    @required this.logicalClock,
    @required this.diffs,
  });

  final int logicalClock;
  final List<SyncDiff> diffs;

  @override
  List<Object> get props => [logicalClock, diffs];
}
