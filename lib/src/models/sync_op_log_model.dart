import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

class SyncOperation extends Equatable {
  const SyncOperation({
    @required this.logicalClock,
    @required this.timestamp,
    @required this.operationType,
    @required this.operationLocation,
    @required this.operationInput,
    @required this.owner,
  });

  final int logicalClock, timestamp;
  final String operationType;
  final String operationLocation;
  final Map operationInput;
  final String owner;

  @override
  List<Object> get props => [logicalClock];
}
