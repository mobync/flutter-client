import 'package:flutter_test/flutter_test.dart';
import 'package:mobync/src/client.dart';

class MyMobyncAPI extends MobyncClient {
  MyMobyncAPI._privateConstructor();
  static final MyMobyncAPI instance = MyMobyncAPI._privateConstructor();

  @override
  Map create(String where, Map what){
    super.create(where, what);
  }

  @override
  Map update(String where, Map what){
    super.update(where, what);
  }

  @override
  bool delete(String where, Map what){
    super.delete(where, what);
  }

  @override
  Map read(String where, Map what){

  }
}

void main() {
  test('Check singletion instantiation', () {
    final a = MyMobyncAPI.instance;
    final b = MyMobyncAPI.instance;
    expect(a, equals(b));
  });
}
