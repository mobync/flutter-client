import 'package:flutter_test/flutter_test.dart';
import 'package:mobync/src/models/models.dart';

import 'client_implementation.dart';

void main() {
  test('Mobync Client - one client perform simple operations', () async {
    final client = MyMobyncClient.instance;
    final obj1 = {'id': '1', 'campo1': 'abc'};
    MobyncResponse response1 = await client.create('model1', obj1);
    expect(response1.success, true);

    final obj2 = {'id': '1', 'campo1': 'cde'};
    MobyncResponse response2 = await client.create('model1', obj2);
    expect(response2.success, false);

    final obj3 = {'id': '2', 'campo1': 'cde'};
    MobyncResponse response3 = await client.create('model1', obj3);
    expect(response3.success, true);

    final obj4 = {'id': '1', 'campo1': 'xxx'};
    MobyncResponse response4 = await client.update('model1', obj4);
    expect(response4.success, true);

    MobyncResponse response5 = await client.read('model1');
    expect(response5.success, true);
    expect(response5.data, [obj4, obj3]);

    MobyncResponse response6 = await client.delete('model1', '2');
    expect(response6.success, true);

    MobyncResponse response7 = await client.read('model1');
    expect(response7.success, true);
    expect(response7.data, [obj4]);
  });
}
