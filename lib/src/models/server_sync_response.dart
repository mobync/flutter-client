import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobync/src/models/models.dart';

class ServerSyncResponse extends Equatable {
  const ServerSyncResponse({
    @required this.logicalClock,
    @required this.syncOperationList,
  });

  final int logicalClock;
  final List<SyncOperation> syncOperationList;

  @override
  List<Object> get props => [logicalClock, syncOperationList];
}
