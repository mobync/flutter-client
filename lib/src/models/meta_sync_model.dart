import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

class SyncMetaData extends Equatable {
  static String tableName = 'SyncMetaDataTable';
  SyncMetaData({
    @required this.logicalClock,
  });

  static final id = '0';
  int logicalClock;

  @override
  List<Object> get props => [logicalClock];

  @override
  String toString() {
    return 'MetaSync: {\n\tclock: $logicalClock\n}';
  }
}
