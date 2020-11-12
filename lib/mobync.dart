library mobync;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/models.dart';
import 'package:uuid/uuid.dart';

/// Abstract class to wrap the local storage operations.
abstract class MobyncClient {
  /// You might implement the following functions
  /// - [commitLocalCreate]
  /// - [commitLocalUpdate]
  /// - [commitLocalDelete]
  /// - [executeLocalRead]
  /// - [getAuthToken]
  /// and the getter for
  /// - [syncEndpoint]

  /// This function creates some data from a given model into a local storage.
  Future<int> commitLocalCreate(String model, Map<String, dynamic> data);

  /// This function updates some data from a given model into a local storage.
  Future<int> commitLocalUpdate(String model, Map<String, dynamic> data);

  /// This function deletes some data from a given model into a local storage.
  Future<int> commitLocalDelete(String model, String id);

  /// This function reads from a local storage all entries from a given model using some filters.
  Future<List<Map>> executeLocalRead(String model, {List<ReadFilter> filters});

  /// This functions gets the auth token to be used on the synchronization requests.
  Future<String> getAuthToken();

  /// API endpoint to make the synchronization requests.
  String get syncEndpoint;

  /// Use this function to perform a create operation that might be synchronized to the remote API.
  ///
  /// The response is wrapped into a [MobyncResponse] object to avoid bugs.
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

  /// Use this function to perform an update operation that might be synchronized to the remote API.
  ///
  /// The response is wrapped into a [MobyncResponse] object to avoid bugs.
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

  /// Use this function to perform a delete operation that might be synchronized to the remote API.
  ///
  /// The response is wrapped into a [MobyncResponse] object to avoid bugs.
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

  /// Use this function to perform a read on the local storage.
  ///
  /// The response is wrapped into a [MobyncResponse] object to avoid bugs.
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

  /// Use this function to synchronize the local storage to the remote storage.
  Future<void> synchronize() async {
    int logicalClock = await getLogicalClock();
    List<SyncDiff> localDiffs = await getSyncDiffs();
    String authToken = await getAuthToken();
    ServerSyncResponse res = await postSyncEndpoint(
      logicalClock,
      localDiffs,
      authToken,
    );

    if (res.success) {
      if (res.logicalClock > logicalClock) {
        try {
          await _executeSyncDiffs(res.diffs);
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

  /// This private function execute all a list of diffs received from upstream.
  Future<void> _executeSyncDiffs(List<SyncDiff> diffs) async {
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

  /// This function makes the request to the synchronization endpoint on the API,
  /// parses the response and returns a [ServerSyncResponse] that contains the new
  /// logical clock and the new diffs from upstream.
  Future<ServerSyncResponse> postSyncEndpoint(
      int logicalClock, List<SyncDiff> localDiffs, String authToken) async {
    try {
      String body = jsonEncode({
        'auth_token': authToken,
        'logical_clock': logicalClock,
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
        List<SyncDiff> syncDiffs = (res['diffs'] as List)
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

  /// This function gets the local diffs that have not been synchronized yet.
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

  /// This function gets the local logical clock.
  Future<int> getLogicalClock() async {
    int logicalClock = await executeLocalRead(
      SyncMetaData.tableName,
      filters: [ReadFilter('id', FilterType.inside, SyncMetaData.id)],
    ).then((value) {
      return value.length > 0 ? value[0]['logicalClock'] : 0;
    });
    return Future.value(logicalClock);
  }

  /// This function sets the local logical clock.
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
