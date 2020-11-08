class MyModel {
  MyModel({
    this.id,
    this.field1,
  });

  static final String tableName = 'MyModel';
  String id, field1;

  MyModel.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    field1 = map['field1'];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'field1': field1,
    };
  }
}
