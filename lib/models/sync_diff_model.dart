import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:mobync/constants/constants.dart';

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
  String id, model;
  SyncDiffType type;
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
    assert(map.containsKey('type'));
    assert(map.containsKey('model'));
    assert(map.containsKey('metadata'));

    id = map['id'];
    logicalClock = map['logicalClock'];
    utcTimestamp = map['utcTimestamp'];
    type = map['type'] is SyncDiffType
        ? map['type']
        : SyncDiffTypesReversedMap[map['type']];
    model = map['model'];
    metadata = map['metadata'];
  }

  Map<String, dynamic> toMap({List<String> onlyFields}) {
    Map<String, dynamic> map = {
      'id': id,
      'logicalClock': logicalClock,
      'utcTimestamp': utcTimestamp,
      'type': describeEnum(type),
      'model': model,
      'metadata': metadata,
    };

    if (onlyFields != null) {
      var keys = map.keys.toList();
      keys.forEach((key) {
        if (!onlyFields.contains(key)) map.remove(key);
      });
    }

    return map;
  }

  @override
  String toString() {
    return 'SyncDiff: {'
        'id: $id,'
        'clock: $logicalClock,'
        'utcTimestamp: $utcTimestamp,'
        'type: ${describeEnum(type)},'
        'model: $model,'
        'metadata: $metadata'
        '}';
  }
}
