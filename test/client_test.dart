import 'package:flutter_test/flutter_test.dart';
import 'package:mobync/src/models/models.dart';

import 'client_implementation.dart';

void main() {
  test('Mobync Client - one client perform simple operations', () async {
    final client = MyMobyncClient.instance;
    final obj1 = {'id': '1', 'campo1': 'abc'};
    MobyncResponse output1 = await client.create('model1', obj1);
    expect(output1.success, true);

    final obj2 = {'id': '1', 'campo1': 'cde'};
    MobyncResponse output2 = await client.create('model1', obj2);
    expect(output2.success, false);

    final obj3 = {'id': '2', 'campo1': 'cde'};
    MobyncResponse output3 = await client.create('model1', obj3);
    expect(output3.success, true);

    final obj4 = {'id': '1', 'campo1': 'xxx'};
    MobyncResponse output4 = await client.update('model1', obj4);
    expect(output4.success, true);

    MobyncResponse output5 = await client.read('model1');
    expect(output5.success, true);
    expect(output5.data, [obj4, obj3]);

    MobyncResponse output6 = await client.delete('model1', '2');
    expect(output6.success, true);

    MobyncResponse output7 = await client.read('model1');
    expect(output7.success, true);
    expect(output7.data, [obj4]);
  });
}
