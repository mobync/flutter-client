import 'dart:convert';

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
    this.jsonData,
  }) : assert(id != null &&
            logicalClock >= 0 &&
            utcTimestamp >= 0 &&
            type != null &&
            model.length > 0 &&
            jsonDecode(jsonData) is Map);

  static final String tableName = 'MobyncSyncDiffsTable';
  String id, model, jsonData;
  SyncDiffType type;
  int logicalClock, utcTimestamp;

  @override
  List<Object> get props =>
      [id, logicalClock, utcTimestamp, type, model, jsonData];

  /// Comparision criteria.
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

  /// Static from map constructor.
  SyncDiff.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    logicalClock = map['logicalClock'];
    utcTimestamp = map['utcTimestamp'];
    type = map['type'] is SyncDiffType
        ? map['type']
        : SyncDiffTypesReversedMap[map['type']];
    model = map['model'];
    jsonData = map['jsonData'];
  }

  /// Static to map parser.
  Map<String, dynamic> toMap({List<String> onlyFields}) {
    Map<String, dynamic> map = {
      'id': id,
      'logicalClock': logicalClock,
      'utcTimestamp': utcTimestamp,
      'type': describeEnum(type),
      'model': model,
      'jsonData': jsonData,
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
        'logicalClock: $logicalClock,'
        'utcTimestamp: $utcTimestamp,'
        'type: ${describeEnum(type)},'
        'model: $model,'
        'jsonData: $jsonData'
        '}';
  }
}
