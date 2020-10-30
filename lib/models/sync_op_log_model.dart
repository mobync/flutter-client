import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

class SyncDiff extends Comparable with EquatableMixin {
  SyncDiff({
    @required this.logicalClock,
    @required this.timestamp,
    @required this.operationType,
    @required this.modelName,
    @required this.operationMetadata,
    this.id,
  }) {
    this.id = id != null ? id : Uuid().v1();
  }

  static final String tableName = 'MobyncSyncOperationsTable';
  String id;
  String operationType, modelName;
  Map operationMetadata;
  int logicalClock, timestamp;

  @override
  List<Object> get props => [id];

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

  fromMap(Map<String, dynamic> map) {
    assert(map.containsKey('id'));
    assert(map.containsKey('logicalClock'));
    assert(map.containsKey('timestamp'));
    assert(map.containsKey('operationType'));
    assert(map.containsKey('modelName'));
    assert(map.containsKey('operationMetadata'));

    id = map['id'];
    logicalClock = map['logicalClock'];
    timestamp = map['timestamp'];
    operationType = map['operationType'];
    modelName = map['modelName'];
    operationMetadata = map['operationMetadata'];
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'logicalClock': logicalClock,
      'timestamp': timestamp,
      'operationType': operationType,
      'modelName': modelName,
      'operationMetadata': operationMetadata,
    };
    return map;
  }

  @override
  String toString() {
    return 'SyncDiff: {'
        'clock: $logicalClock,'
        'timestamp: $timestamp,'
        'opType: $operationType,'
        'odelName: $modelName,'
        'perationMetadata: $operationMetadata'
        '}';
  }
}
