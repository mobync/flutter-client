import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

class SyncDiff extends Comparable with EquatableMixin {
  SyncDiff({
    @required this.logicalClock,
    @required this.utcTimestamp,
    @required this.operationType,
    @required this.modelName,
    @required this.operationMetadata,
    this.id,
  }) {
    this.id = id != null ? id : Uuid().v1();
  }

  static final String tableName = 'MobyncSyncDiffsTable';
  String id;
  String operationType, modelName;
  Map operationMetadata;
  int logicalClock, utcTimestamp;

  @override
  List<Object> get props => [
        id,
        logicalClock,
        utcTimestamp,
        operationType,
        modelName,
        operationMetadata
      ];

  @override
  int compareTo(other) {
    if (this.logicalClock < other.logicalClock)
      return -1;
    else if (this.logicalClock > other.logicalClock)
      return 1;
    else {
      if (this.utcTimestamp < other.utcTimestamp)
        return -1;
      else if (this.utcTimestamp > other.utcTimestamp)
        return 1;
      else
        return 0;
    }
  }

  SyncDiff.fromMap(Map<String, dynamic> map) {
    assert(map.containsKey('id'));
    assert(map.containsKey('logicalClock'));
    assert(map.containsKey('utcTimestamp'));
    assert(map.containsKey('operationType'));
    assert(map.containsKey('modelName'));
    assert(map.containsKey('operationMetadata'));

    id = map['id'];
    logicalClock = map['logicalClock'];
    utcTimestamp = map['utcTimestamp'];
    operationType = map['operationType'];
    modelName = map['modelName'];
    operationMetadata = map['operationMetadata'];
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'logicalClock': logicalClock,
      'utcTimestamp': utcTimestamp,
      'operationType': operationType,
      'modelName': modelName,
      'operationMetadata': operationMetadata,
    };
    return map;
  }

  @override
  String toString() {
    return 'SyncDiff: {'
        'id: $id,'
        'clock: $logicalClock,'
        'utcTimestamp: $utcTimestamp,'
        'opType: $operationType,'
        'modelName: $modelName,'
        'operationMetadata: $operationMetadata'
        '}';
  }
}
