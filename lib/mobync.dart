library mobync;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/models.dart';
import 'package:uuid/uuid.dart';

abstract class MobyncClient {
  Future<Map> commitLocalCreate(String model, Map<String, dynamic> data);
  Future<Map> commitLocalUpdate(String model, Map<String, dynamic> data);
  Future<Map> commitLocalDelete(String model, String id);
  Future<List<Map>> executeLocalRead(String model, {List<ReadFilter> filters});
  String get syncEndpoint;

  Future<MobyncResponse> create(String model, Map metadata) async {
    try {
      await commitLocalCreate(model, metadata);
      await commitLocalCreate(
          SyncDiff.tableName,
          SyncDiff(
            id: Uuid().v1(),
            logicalClock: await getLogicalClock(),
            utcTimestamp: DateTime.now().toUtc().millisecondsSinceEpoch,
            type: SyncDiffType.create,
            model: model,
            jsonData: jsonEncode(metadata),
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
            type: SyncDiffType.update,
            model: model,
            jsonData: jsonEncode(metadata),
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
            type: SyncDiffType.delete,
            model: model,
            jsonData: jsonEncode({'id': id}),
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
    ServerSyncResponse res = await postSyncEndpoint(logicalClock, localDiffs);

    if (res.success) {
      if (res.logicalClock > logicalClock) {
        try {
          await executeSyncDiffs(res.diffs);
          await setLogicalClock(res.logicalClock);
        } catch (e) {
          print(e);
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  }

  Future<void> executeSyncDiffs(List<SyncDiff> diffs) async {
    diffs.forEach((el) async {
      Map res;
      Map data = jsonDecode(el.jsonData);
      switch (el.type) {
        case SyncDiffType.create:
          res = await commitLocalCreate(el.model, data);
          break;
        case SyncDiffType.update:
          res = await commitLocalUpdate(el.model, data);
          break;
        case SyncDiffType.delete:
          res = await commitLocalDelete(el.model, data['id']);
          break;
        default:
          throw Exception('Invalid Operation.');
          break;
      }

      if (res != null) await commitLocalCreate(SyncDiff.tableName, el.toMap());
    });
  }

  Future<ServerSyncResponse> postSyncEndpoint(
      int logicalClock, List<SyncDiff> localDiffs) async {
    try {
      String body = jsonEncode({
        'logicalClock': await getLogicalClock(),
        'diffs': localDiffs.map((e) => e.toMap()).toList(),
      });

      http.Response resp = await http.post(syncEndpoint,
          headers: {'Content-Type': 'application/json'}, body: body);

      if (resp.statusCode.toString().startsWith('2')) {
        Map res = jsonDecode(resp.body);
        List<SyncDiff> syncDiffs =
            (res['diffs'] as List).map((e) => SyncDiff.fromMap(e)).toList();
        syncDiffs.sort();
        return Future.value(ServerSyncResponse(
          success: true,
          logicalClock: res['logicalClock'],
          diffs: syncDiffs,
        ));
      } else {
        throw Exception('Request failed.');
      }
    } catch (e) {
      return Future.value(ServerSyncResponse(
        success: false,
        message: e.toString(),
      ));
    }
  }

  Future<List<SyncDiff>> getSyncDiffs({logicalClock}) async {
    if (logicalClock == null) logicalClock = await getLogicalClock();
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
    int logicalClock = await executeLocalRead(
      SyncMetaData.tableName,
      filters: [ReadFilter('id', FilterType.inside, SyncMetaData.id)],
    ).then((value) {
      return value.length > 0 ? value[0]['logicalClock'] : 0;
    });
    return Future.value(logicalClock);
  }

  Future<void> setLogicalClock(int logicalClock) async {
    Map updatedMetadata = await commitLocalUpdate(
      SyncMetaData.tableName,
      {'id': SyncMetaData.id, 'logicalClock': logicalClock},
    );

    if (updatedMetadata == null) {
      await commitLocalCreate(
        SyncMetaData.tableName,
        {'id': SyncMetaData.id, 'logicalClock': logicalClock},
      );
    }
  }
}
