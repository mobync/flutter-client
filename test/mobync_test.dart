import 'package:flutter_test/flutter_test.dart';
import 'package:mobync/src/client.dart';

class MyMobyncAPI extends MobyncClient {
  MyMobyncAPI._privateConstructor();
  static final MyMobyncAPI instance = MyMobyncAPI._privateConstructor();

  void _sync() {}

  @override
  Map create(String where, Map what) {
    super.create(where, what);
    _sync();
  }

  @override
  Map update(String where, Map what) {
    super.update(where, what);
    _sync();
  }

  @override
  bool delete(String where, Map what) {
    super.delete(where, what);
    _sync();
  }

  @override
  Map read(String where, Map what) {}
}

void main() {
  test('Check singletion instantiation', () {
    final a = MyMobyncAPI.instance;
    final b = MyMobyncAPI.instance;
    expect(a, equals(b));
  });

  test('One client creates and then syncs', () {
    final mobync = MyMobyncAPI.instance;
    mobync.create('where', {});
  });
}
