import 'package:flutter_test/flutter_test.dart';
import 'package:mobync/models/models.dart';

import 'client_implementation.dart';

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

  test('Client 1 perform multiple operations and creates its local sync diffs',
      () async {
    final obj1 = {'id': 'uuid1', 'field1': 'abc'};
    MobyncResponse res1 = await client1.create('model1', obj1);
    expect(res1.success, true);

    final obj2 = {'id': 'uuid1', 'field1': 'cde'};
    MobyncResponse res2 = await client1.create('model1', obj2);
    expect(res2.success, false);

    final obj3 = {'id': 'uuid2', 'field1': 'fgh'};
    MobyncResponse res3 = await client1.create('model1', obj3);
    expect(res3.success, true);

    final obj4 = {'id': 'uuid1', 'field1': 'xxx'};
    MobyncResponse res4 = await client1.update('model1', obj4);
    expect(res4.success, true);

    MobyncResponse res5 = await client1.read('model1');
    expect(res5.success, true);
    expect(res5.data, [
      {'id': 'uuid1', 'field1': 'xxx'},
      {'id': 'uuid2', 'field1': 'fgh'}
    ]);

    MobyncResponse res6 = await client1.delete('model1', 'uuid2');
    expect(res6.success, true);

    MobyncResponse res7 = await client1.read('model1');
    expect(res7.success, true);
    expect(res7.data, [
      {'id': 'uuid1', 'field1': 'xxx'}
    ]);

    List<SyncDiff> res8 = await client1.getSyncDiffs();
    expect(
        res8
            .map((e) => e
                .toMap(
                    onlyFields: ['logicalClock', 'type', 'model', 'jsonData'])
                .values
                .toList())
            .toList(),
        [
          [0, 'create', 'model1', '{"id":"uuid1","field1":"abc"}'],
          [0, 'create', 'model1', '{"id":"uuid2","field1":"fgh"}'],
          [0, 'update', 'model1', '{"id":"uuid1","field1":"xxx"}'],
          [0, 'delete', 'model1', '{"id":"uuid2"}']
        ]);
  });

  test('Both clients sync', () async {
    await client1.synchronize();
    await client2.synchronize();

    MobyncResponse res1 = await client1.read('model1');
    expect(res1.success, true);
    expect(res1.data, [
      {'id': 'uuid1', 'field1': 'xxx'}
    ]);

    MobyncResponse res2 = await client2.read('model1');
    expect(res2.success, true);
    expect(res2.data, [
      {'id': 'uuid1', 'field1': 'xxx'}
    ]);
  });

  test('Client 2 delete object and both clients sync', () async {
    MobyncResponse res1 = await client2.delete('model1', 'uuid1');
    expect(res1.success, true);

    await client2.synchronize();
    await client1.synchronize();

    MobyncResponse res2 = await client1.read('model1');
    expect(res2.success, true);
    expect(res2.data, []);

    MobyncResponse res3 = await client2.read('model1');
    expect(res3.success, true);
    expect(res3.data, []);
  });
}
