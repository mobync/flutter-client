class SyncMetaData {
  SyncMetaData({this.logicalClock});

  static final String tableName = 'SyncMetaDataTable';
  static final id = '0';
  int logicalClock;

  @override
  String toString() {
    return 'MetaSync: {\n\tclock: $logicalClock\n}';
  }
}
