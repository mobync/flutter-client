library mobync;

import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/models.dart';
import 'package:uuid/uuid.dart';

abstract class MobyncClient {
  Future<Map> commitLocalCreate(String model, Map metadata);
  Future<Map> commitLocalUpdate(String model, Map metadata);
  Future<Map> commitLocalDelete(String model, String id);
  Future<List<Map>> executeLocalRead(String model, {List<ReadFilter> filters});

  /// Note: it may handle proper auth when fetching upstream data.
  Future<ServerSyncResponse> postSyncEndpoint(
      int logicalClock, List<SyncDiff> localDiffs);

  Future<List<SyncDiff>> getSyncDiffs() async {
    int logicalClock = await getLogicalClock();
    List<Map> maps = await executeLocalRead(
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
    int logicalClock =
        await executeLocalRead(SyncMetaData.tableName).then((value) {
      return value.length > 0 ? value[0]['logicalClock'] : 0;
    });
    return Future.value(logicalClock);
  }

  Future<void> _setLogicalClock(int logicalClock) async {
    Map updatedMetadata = await commitLocalUpdate(
      SyncMetaData.tableName,
      {'id': SyncMetaData.id, 'logicalClock': logicalClock},
    );

    if (updatedMetadata == null)
      await commitLocalCreate(
        SyncMetaData.tableName,
        {'id': SyncMetaData.id, 'logicalClock': logicalClock},
      );
  }

  Future<MobyncResponse> create(String model, Map metadata) async {
    try {
      await commitLocalCreate(model, metadata);
      await commitLocalCreate(
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
      await commitLocalUpdate(model, metadata);
      await commitLocalCreate(
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
      await commitLocalDelete(model, id);
      await commitLocalCreate(
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
      List<Map> filteredData = await executeLocalRead(model, filters: filters);
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

  Future<void> synchronize() async {
    int logicalClock = await getLogicalClock();
    List<SyncDiff> localDiffs = await getSyncDiffs();
    ServerSyncResponse upstream =
        await postSyncEndpoint(logicalClock, localDiffs);

    _setLogicalClock(upstream.logicalClock + 1);
    if (upstream.diffs.length > 0) executeSyncDiffs(upstream.diffs);
  }

  Future<void> executeSyncDiffs(List<SyncDiff> diffs) async {
    diffs.forEach((el) async {
      Map res;
      Map metadata = shallowCopy(el.metadata);
      switch (el.type) {
        case CREATE_OPERATION:
          res = await commitLocalCreate(el.model, metadata);
          break;
        case UPDATE_OPERATION:
          res = await commitLocalUpdate(el.model, metadata);
          break;
        case DELETE_OPERATION:
          res = await commitLocalDelete(el.model, metadata['id']);
          break;
        default:
          throw Exception('Invalid Operation.');
          break;
      }

      if (res != null) await commitLocalCreate(SyncDiff.tableName, el.toMap());
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
