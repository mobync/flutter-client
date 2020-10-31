import 'package:equatable/equatable.dart';

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
    assert(map.containsKey('type'));
    assert(map.containsKey('model'));
    assert(map.containsKey('metadata'));

    id = map['id'];
    logicalClock = map['logicalClock'];
    utcTimestamp = map['utcTimestamp'];
    type = map['type'];
    model = map['model'];
    metadata = map['metadata'];
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'logicalClock': logicalClock,
      'utcTimestamp': utcTimestamp,
      'type': type,
      'model': model,
      'metadata': metadata,
    };
    return map;
  }

  @override
  String toString() {
    return 'SyncDiff: {'
        'id: $id,'
        'clock: $logicalClock,'
        'utcTimestamp: $utcTimestamp,'
        'type: $type,'
        'model: $model,'
        'metadata: $metadata'
        '}';
  }
}
