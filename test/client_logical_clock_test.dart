import 'package:flutter_test/flutter_test.dart';

import 'client_implementation.dart';

void main() {
  MyMobyncClient client;

  setUpAll(() async {
    client = MyMobyncClient();
  });

  test('test logical clock get and set', () async {
    int logicalClock1 = await client.getLogicalClock();
    expect(logicalClock1, 0);

    await client.setLogicalClock(10);

    int logicalClock2 = await client.getLogicalClock();
    expect(logicalClock2, 10);
  });
}
