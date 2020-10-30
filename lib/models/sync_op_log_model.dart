import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

class SyncDiff extends Comparable with EquatableMixin {
  SyncDiff({
    this.id,
    this.logicalClock,
    this.utcTimestamp,
    this.type,
    this.model,
    this.metadata,
  });

  static final String tableName = 'MobyncSyncDiffsTable';
  String id;
  String type, model;
  Map metadata;
  int logicalClock, utcTimestamp;

  @override
  List<Object> get props =>
      [id, logicalClock, utcTimestamp, type, model, metadata];

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
    type = map['operationType'];
    model = map['modelName'];
    metadata = map['operationMetadata'];
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'logicalClock': logicalClock,
      'utcTimestamp': utcTimestamp,
      'operationType': type,
      'modelName': model,
      'operationMetadata': metadata,
    };
    return map;
  }

  @override
  String toString() {
    return 'SyncDiff: {'
        'id: $id,'
        'clock: $logicalClock,'
        'utcTimestamp: $utcTimestamp,'
        'opType: $type,'
        'modelName: $model,'
        'operationMetadata: $metadata'
        '}';
  }
}
