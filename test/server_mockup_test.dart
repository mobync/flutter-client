import 'package:flutter_test/flutter_test.dart';
import 'package:mobync/src/constants/constants.dart';
import 'package:mobync/src/models/models.dart';

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
      userSyncOperationList: [],
    );
    expect(outputClient.logicalClock, 0);
    expect(outputClient.syncOperationList, []);
  });

  test(
      'Server mockup - one client syncs some create, other client syncs from an older state (same owner), then a client from a different owner syncs.',
      () async {
    final server = ServerMockup.instance;

    List<SyncOperation> syncOperationList = [
      SyncOperation(
        logicalClock: 1,
        timestamp: new DateTime.now()
            .subtract(Duration(minutes: 2))
            .millisecondsSinceEpoch,
        operationType: K_SYNC_OP_CREATE,
        operationInput: {'a': 123},
        operationLocation: 'data_type_1',
      ),
      SyncOperation(
        logicalClock: 1,
        timestamp: new DateTime.now()
            .subtract(Duration(minutes: 1))
            .millisecondsSinceEpoch,
        operationType: K_SYNC_OP_CREATE,
        operationInput: {'a': 123},
        operationLocation: 'data_type_1',
      ),
    ];

    /// User1 syncs some initial data.
    ServerSyncResponse outputClient1 = await server.sync(
      owner: 'user1',
      clientLogicalClock: 1,
      userSyncOperationList: syncOperationList,
    );
    expect(outputClient1.logicalClock, 2);
    expect(outputClient1.syncOperationList, []);

    /// User2 syncs for the first time.
    ServerSyncResponse outputClient2 = await server.sync(
      owner: 'user2',
      clientLogicalClock: 0,
      userSyncOperationList: [],
    );
    expect(outputClient2.logicalClock, 0);
    expect(outputClient2.syncOperationList, []);

    /// Another client from User1 then syncs and get the stored data.
    ServerSyncResponse outputClient3 = await server.sync(
      owner: 'user1',
      clientLogicalClock: 0,
      userSyncOperationList: [],
    );
    expect(outputClient3.logicalClock, 2);
    expect(outputClient3.syncOperationList, syncOperationList);
  });
}
