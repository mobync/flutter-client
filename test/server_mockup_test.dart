import 'package:flutter_test/flutter_test.dart';
import 'package:mobync/constants/constants.dart';
import 'package:mobync/models/models.dart';

import 'server_mockup.dart';

void main() {
  test('Server mockup - singleton instatiation', () {
    final a = ServerMockup.instance;
    final b = ServerMockup.instance;
    expect(a, b);
  });

  test('Server mockup - test sync for the first time (first login sync).',
      () async {
    final server = ServerMockup.instance;

    ServerSyncResponse outputClient = await server.sync(
      owner: 'user1',
      clientLogicalClock: 0,
      userSyncDiffs: [],
    );
    expect(outputClient.logicalClock, 0);
    expect(outputClient.diffs, []);
  });

  test(
      'Server mockup - one client syncs some create, other client syncs from an older state (same owner), then a client from a different owner syncs.',
      () async {
    final server = ServerMockup.instance;

    List<SyncDiff> syncDiffs = [
      SyncDiff(
        logicalClock: 1,
        utcTimestamp: new DateTime.now()
            .subtract(Duration(minutes: 2))
            .millisecondsSinceEpoch,
        operationType: CREATE_OPERATION,
        modelName: 'data_type_1',
        operationMetadata: {'a': 123},
      ),
      SyncDiff(
        logicalClock: 1,
        utcTimestamp: new DateTime.now()
            .subtract(Duration(minutes: 1))
            .millisecondsSinceEpoch,
        operationType: CREATE_OPERATION,
        modelName: 'data_type_1',
        operationMetadata: {'a': 123},
      ),
    ];

    /// User1 syncs some initial data.
    ServerSyncResponse outputClient1 = await server.sync(
      owner: 'user1',
      clientLogicalClock: 1,
      userSyncDiffs: syncDiffs,
    );
    expect(outputClient1.logicalClock, 2);
    expect(outputClient1.diffs, []);

    /// User2 syncs for the first time.
    ServerSyncResponse outputClient2 = await server.sync(
      owner: 'user2',
      clientLogicalClock: 0,
      userSyncDiffs: [],
    );
    expect(outputClient2.logicalClock, 0);
    expect(outputClient2.diffs, []);

    /// Another client from User1 then syncs and get the stored data.
    ServerSyncResponse outputClient3 = await server.sync(
      owner: 'user1',
      clientLogicalClock: 0,
      userSyncDiffs: [],
    );
    expect(outputClient3.logicalClock, 2);
    expect(outputClient3.diffs, syncDiffs);
  });
}
