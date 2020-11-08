import 'package:flutter_test/flutter_test.dart';
import 'package:mobync/models/models.dart';

import 'client_implementation.dart';
import 'local_server_mockup.dart';

void main() {
  MyMobyncClient client1, client2;

  setUpAll(() async {
    client1 = MyMobyncClient();
    client2 = MyMobyncClient();
    ServerMockup.instance.reset();
  });

  test('client 1 and 2 sanity check', () async {
    int logicalClock1 = await client1.getLogicalClock();
    expect(logicalClock1, 0);

    int logicalClock2 = await client2.getLogicalClock();
    expect(logicalClock2, 0);

    MobyncResponse res1 = await client1.read('model1');
    expect(res1.success, true);
    expect(res1.data, []);

    MobyncResponse res2 = await client2.read('model1');
    expect(res2.success, true);
    expect(res2.data, []);
  });

  test('client 1 creates local object and synchronizes', () async {
    final obj1 = {'id': 'uuid1', 'field1': 'a'};
    MobyncResponse res1 = await client1.create('model1', obj1);
    expect(res1.success, true);

    await client1.synchronize();

    int logicalClock1 = await client1.getLogicalClock();
    expect(logicalClock1, 1);

    MobyncResponse res = await client1.read('model1');
    expect(res.success, true);
    expect(res.data, [
      {'id': 'uuid1', 'field1': 'a'},
    ]);
  });

  test('client 1 and 2 create local objects but neither synchronize', () async {
    final obj1 = {'id': 'uuid2', 'field1': 'b'};
    MobyncResponse res1 = await client1.create('model1', obj1);
    expect(res1.success, true);

    final obj2 = {'id': 'uuid3', 'field1': 'c'};
    MobyncResponse res2 = await client2.create('model1', obj2);
    expect(res2.success, true);
  });

  test('client 2 synchonizes', () async {
    await client2.synchronize();

    MobyncResponse res = await client2.read('model1');
    expect(res.success, true);
    expect(res.data, [
      {'id': 'uuid1', 'field1': 'a'},
      {'id': 'uuid3', 'field1': 'c'},
    ]);

    int logicalClock2 = await client2.getLogicalClock();
    expect(logicalClock2, 2);
  });

  test('client 1 synchronizes', () async {
    await client1.synchronize();

    MobyncResponse res = await client1.read('model1');
    expect(res.success, true);
    expect(res.data, [
      {'id': 'uuid1', 'field1': 'a'},
      {'id': 'uuid2', 'field1': 'b'},
      {'id': 'uuid3', 'field1': 'c'},
    ]);

    int logicalClock1 = await client1.getLogicalClock();
    expect(logicalClock1, 3);
  });

  test('client 2 synchronizes', () async {
    await client2.synchronize();

    MobyncResponse res = await client2.read('model1');
    expect(res.success, true);
    expect(res.data, [
      {'id': 'uuid1', 'field1': 'a'},
      {'id': 'uuid2', 'field1': 'b'},
      {'id': 'uuid3', 'field1': 'c'},
    ]);

    int logicalClock2 = await client2.getLogicalClock();
    expect(logicalClock2, 3);
  });

  test('client 2 updates client 1 object and both synchronizes', () async {
    final obj = {'id': 'uuid1', 'field1': 'x'};
    MobyncResponse res = await client2.update('model1', obj);
    expect(res.success, true);

    await client2.synchronize();
    await client1.synchronize();

    MobyncResponse res1 = await client1.read('model1');
    expect(res1.success, true);
    expect(res1.data, [
      {'id': 'uuid1', 'field1': 'x'},
      {'id': 'uuid2', 'field1': 'b'},
      {'id': 'uuid3', 'field1': 'c'},
    ]);

    int logicalClock1 = await client1.getLogicalClock();
    expect(logicalClock1, 4);

    MobyncResponse res2 = await client2.read('model1');
    expect(res2.success, true);
    expect(res2.data, [
      {'id': 'uuid1', 'field1': 'x'},
      {'id': 'uuid2', 'field1': 'b'},
      {'id': 'uuid3', 'field1': 'c'},
    ]);

    int logicalClock2 = await client2.getLogicalClock();
    expect(logicalClock2, 4);
  });

  test('client 1 deletes client 2 object and both synchronizes', () async {
    MobyncResponse res = await client1.delete('model1', 'uuid3');
    expect(res.success, true);

    await client1.synchronize();
    await client2.synchronize();

    MobyncResponse res1 = await client1.read('model1');
    expect(res1.success, true);
    expect(res1.data, [
      {'id': 'uuid1', 'field1': 'x'},
      {'id': 'uuid2', 'field1': 'b'},
    ]);

    MobyncResponse res2 = await client2.read('model1');
    expect(res2.success, true);
    expect(res2.data, [
      {'id': 'uuid1', 'field1': 'x'},
      {'id': 'uuid2', 'field1': 'b'},
    ]);
  });
}
