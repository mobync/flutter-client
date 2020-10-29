import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

class SyncMetaData extends Equatable {
  static String tableName = 'SyncMetaDataTable';
  static final id = '0';
  SyncMetaData({
    @required this.logicalClock,
  });

  int logicalClock;

  @override
  List<Object> get props => [logicalClock];

  @override
  String toString() {
    return 'MetaSync: {\n\tclock: $logicalClock\n}';
  }
}
