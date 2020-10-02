import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

class SyncOperation extends Comparable with EquatableMixin {
  SyncOperation({
    @required this.logicalClock,
    @required this.timestamp,
    @required this.operationType,
    @required this.operationLocation,
    @required this.operationInput,
  });

  final int logicalClock, timestamp;
  final String operationType;
  final String operationLocation;
  final Map operationInput;

  @override
  List<Object> get props => [logicalClock];

  @override
  int compareTo(other) {
    if (this.logicalClock < other.logicalClock)
      return -1;
    else if (this.logicalClock > other.logicalClock)
      return 1;
    else {
      if (this.timestamp < other.timestamp)
        return -1;
      else if (this.timestamp > other.timestamp)
        return 1;
      else
        return 0;
    }
  }
}
