import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

class SyncMetaData extends Equatable {
  SyncMetaData({
    @required this.logicalClock,
  });

  static final String tableName = 'SyncMetaDataTable';
  static final id = '0';
  int logicalClock;

  @override
  List<Object> get props => [logicalClock];

  @override
  String toString() {
    return 'MetaSync: {\n\tclock: $logicalClock\n}';
  }
}
