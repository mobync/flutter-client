import 'package:flutter_test/flutter_test.dart';
import 'package:mobync/models/models.dart';

import 'client_implementation.dart';

void main() {
  test('test logical clock get and set', () async {
    final client = MyMobyncClient.instance;

    int logicalClock = await client.getLogicalClock();
    expect(logicalClock, 0);

    await client.setLogicalClock(10);
    int logicalClock2 = await client.getLogicalClock();
    expect(logicalClock2, 10);
  });

  test('Client perform simple operations', () async {
    final client = MyMobyncClient.instance;

    final obj1 = {'id': '1', 'campo1': 'abc'};
    MobyncResponse res1 = await client.create('model1', obj1);
    expect(res1.success, true);

    final obj2 = {'id': '1', 'campo1': 'cde'};
    MobyncResponse res2 = await client.create('model1', obj2);
    expect(res2.success, false);

    final obj3 = {'id': '2', 'campo1': 'fgh'};
    MobyncResponse res3 = await client.create('model1', obj3);
    expect(res3.success, true);

    final obj4 = {'id': '1', 'campo1': 'xxx'};
    MobyncResponse res4 = await client.update('model1', obj4);
    expect(res4.success, true);

    MobyncResponse res5 = await client.read('model1');
    expect(res5.success, true);
    expect(res5.data, [obj4, obj3]);

    MobyncResponse res6 = await client.delete('model1', '2');
    expect(res6.success, true);

    MobyncResponse res7 = await client.read('model1');
    expect(res7.success, true);
    expect(res7.data, [obj4]);

    List<SyncDiff> res8 = await client.getSyncDiffs();
    expect(res8.length, 4);
    expect(
        res8
            .map((e) => [
                  e.logicalClock,
                  e.operationType,
                  e.modelName,
                  e.operationMetadata
                ])
            .toList(),
        [
          [
            10,
            'CREATE',
            'model1',
            {'id': '1', 'campo1': 'abc'}
          ],
          [
            10,
            'CREATE',
            'model1',
            {'id': '2', 'campo1': 'fgh'}
          ],
          [
            10,
            'UPDATE',
            'model1',
            {'id': '1', 'campo1': 'xxx'}
          ],
          [
            10,
            'DELETE',
            'model1',
            {'id': '2'}
          ]
        ]);
  });
}
