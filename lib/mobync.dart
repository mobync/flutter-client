library mobync;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/models.dart';
import 'package:uuid/uuid.dart';

abstract class MobyncClient {
  Future<int> commitLocalCreate(String model, Map<String, dynamic> data);
  Future<int> commitLocalUpdate(String model, Map<String, dynamic> data);
  Future<int> commitLocalDelete(String model, String id);
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
      int res;
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

      if (res > 0) await commitLocalCreate(SyncDiff.tableName, el.toMap());
    });
  }

  Future<ServerSyncResponse> postSyncEndpoint(
      int logicalClock, List<SyncDiff> localDiffs) async {
    try {
      String body = jsonEncode({
        'auth_token': 'asdf',
        'logical_clock': await getLogicalClock(),
        'diffs': localDiffs
            .map((e) => {
                  'id': e.id,
                  'owner': 'asdf',
                  'logical_clock': e.logicalClock,
                  'utc_timestamp': e.utcTimestamp,
                  'type': describeEnum(e.type),
                  'model': e.model,
                  'json_data': e.jsonData,
                })
            .toList(),
      });

      http.Response resp = await http.post(syncEndpoint,
          headers: {'Content-Type': 'application/json'}, body: body);

      if (resp.statusCode.toString().startsWith('2')) {
        Map res = jsonDecode(resp.body);
        List<SyncDiff> syncDiffs = res['diffs']
            .map((e) => SyncDiff(
                id: e['id'],
                jsonData: e['json_data'],
                logicalClock: e['logical_clock'],
                model: e['model'],
                type: SyncDiffTypesReversedMap[e['type']],
                utcTimestamp: e['utc_timestamp']))
            .toList();
        syncDiffs.sort();

        return Future.value(ServerSyncResponse(
          success: true,
          logicalClock: res['logical_clock'],
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
    int updatedMetadata = await commitLocalUpdate(
      SyncMetaData.tableName,
      {'id': SyncMetaData.id, 'logicalClock': logicalClock},
    );

    if (updatedMetadata <= 0) {
      await commitLocalCreate(
        SyncMetaData.tableName,
        {'id': SyncMetaData.id, 'logicalClock': logicalClock},
      );
    }
  }
}
