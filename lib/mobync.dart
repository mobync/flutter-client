library mobync;

import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/models.dart';
import 'package:uuid/uuid.dart';

abstract class MobyncClient {
  Future<Map> createExecute(String where, Map what);
  Future<Map> updateExecute(String where, Map what);
  Future<Map> deleteExecute(String where, String uid);
  Future<List<Map>> readExecute(String where, {List<ReadFilter> filters});

  /// Note: it may handle proper auth on upstream diffs fetch.
  Future<List<SyncDiff>> fetchUpstreamDiffs(List<SyncDiff> localDiffs);

  Future<List<SyncDiff>> getSyncDiffs({int logicalClock}) async {
    if (logicalClock == null) logicalClock = await getLogicalClock();
    List<Map> maps = await readExecute(
      SyncDiff.tableName,
      filters: [
        ReadFilter('logicalClock', FilterType.majorOrEqual, logicalClock)
      ],
    );
    List<SyncDiff> diffs = maps.map((e) => SyncDiff.fromMap(e)).toList();
    diffs.sort();
    return diffs;
  }

  Future<int> getLogicalClock() async {
    int logicalClock = await readExecute(SyncMetaData.tableName).then((value) {
      return value.length > 0 ? value[0]['logicalClock'] : 0;
    });
    return Future.value(logicalClock);
  }

  Future<void> setLogicalClock(int logicalClock) async {
    Map updatedMetadata = await updateExecute(
      SyncMetaData.tableName,
      {'id': SyncMetaData.id, 'logicalClock': logicalClock},
    );

    if (updatedMetadata == null)
      await createExecute(
        SyncMetaData.tableName,
        {'id': SyncMetaData.id, 'logicalClock': logicalClock},
      );
  }

  Future<MobyncResponse> create(String model, Map metadata) async {
    try {
      await createExecute(model, metadata);
      await createExecute(
          SyncDiff.tableName,
          SyncDiff(
            id: Uuid().v1(),
            logicalClock: await getLogicalClock(),
            utcTimestamp: DateTime.now().toUtc().millisecondsSinceEpoch,
            type: CREATE_OPERATION,
            model: model,
            metadata: shallowCopy(metadata),
          ).toMap());

      return Future.value(MobyncResponse(
        success: true,
        message: 'Objected created.',
      ));
    } catch (e) {
      return Future.value(MobyncResponse(
        success: false,
        message: e.toString(),
      ));
    }
  }

  Future<MobyncResponse> update(String model, Map metadata) async {
    try {
      await updateExecute(model, metadata);
      await createExecute(
          SyncDiff.tableName,
          SyncDiff(
            id: Uuid().v1(),
            logicalClock: await getLogicalClock(),
            utcTimestamp: DateTime.now().toUtc().millisecondsSinceEpoch,
            type: UPDATE_OPERATION,
            model: model,
            metadata: shallowCopy(metadata),
          ).toMap());

      return Future.value(MobyncResponse(
        success: true,
        message: 'Objected updated.',
      ));
    } catch (e) {
      return Future.value(MobyncResponse(
        success: false,
        message: e.toString(),
      ));
    }
  }

  Future<MobyncResponse> delete(String model, String id) async {
    try {
      await deleteExecute(model, id);
      await createExecute(
          SyncDiff.tableName,
          SyncDiff(
            id: Uuid().v1(),
            logicalClock: await getLogicalClock(),
            utcTimestamp: DateTime.now().toUtc().millisecondsSinceEpoch,
            type: DELETE_OPERATION,
            model: model,
            metadata: {'id': id},
          ).toMap());

      return Future.value(MobyncResponse(
        success: true,
        message: 'Objected updated.',
      ));
    } catch (e) {
      return Future.value(MobyncResponse(
        success: false,
        message: e.toString(),
      ));
    }
  }

  Future<MobyncResponse> read(String model, {List<ReadFilter> filters}) async {
    try {
      List<Map> filteredData = await readExecute(model, filters: filters);
      return Future.value(MobyncResponse(
        success: true,
        data: filteredData,
      ));
    } catch (e) {
      return Future.value(MobyncResponse(
        success: false,
        message: e.toString(),
      ));
    }
  }

  Future<void> sync() async {
    List<SyncDiff> localDiffs = await getSyncDiffs();
    List<SyncDiff> upstreamDiffs = await fetchUpstreamDiffs(localDiffs);
    upstreamDiffs.sort();
    executeSyncDiffs(upstreamDiffs);
  }

  Future<void> executeSyncDiffs(List<SyncDiff> diffs) async {
    diffs.forEach((el) async {
      Map res;
      Map metadata = shallowCopy(el.metadata);
      switch (el.type) {
        case CREATE_OPERATION:
          res = await createExecute(el.model, metadata);
          break;
        case UPDATE_OPERATION:
          res = await createExecute(el.model, metadata);
          break;
        case DELETE_OPERATION:
          res = await deleteExecute(el.model, metadata['id']);
          break;
        default:
          throw Exception('Invalid Operation.');
          break;
      }

      if (res != null) await createExecute(SyncDiff.tableName, el.toMap());
    });
  }

  shallowCopy(obj) {
    if (obj == null) return null;

    if (obj is Map) {
      Map res = {};
      obj.forEach((key, value) => res[key] = value);
      return res;
    }

    throw Exception('Shallow copy not supported for this type.');
  }
}
