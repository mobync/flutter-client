import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

class SyncOperation extends Comparable with EquatableMixin {
  static String tableName = 'SyncOperationsTable';
  SyncOperation({
    @required this.logicalClock,
    @required this.timestamp,
    @required this.operationType,
    @required this.operationLocation,
    @required this.operationInput,
    this.id,
  }) {
    if (id == null) id = new Uuid().v1();
  }

  String id;
  int logicalClock, timestamp;
  String operationType;
  String operationLocation;
  Map operationInput;

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

  @override
  String toString() {
    return 'SyncOperation: {\n\tclock: $logicalClock,\n\ttimestamp: $timestamp,\n\topType: $operationType,\n\twhere: $operationLocation,\n\tdata: $operationInput\n}';
  }

  fromMap(Map<String, dynamic> map) {
    assert(map.containsKey('id'));
    assert(map.containsKey('logicalClock'));
    assert(map.containsKey('timestamp'));
    assert(map.containsKey('operationType'));
    assert(map.containsKey('operationLocation'));
    assert(map.containsKey('operationInput'));

    id = map['id'];
    logicalClock = map['logicalClock'];
    timestamp = map['timestamp'];
    operationType = map['operationType'];
    operationLocation = map['operationLocation'];
    operationInput = map['operationInput'];
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'logicalClock': logicalClock,
      'timestamp': timestamp,
      'operationType': operationType,
      'operationLocation': operationLocation,
      'operationInput': operationInput,
    };
    return map;
  }
}
