import 'package:flutter/material.dart';
import 'package:mobync/models/models.dart';
import 'package:example/myMobync.dart';
import 'package:example/myModel.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobync Demo using SQLite',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<MyModel> data = [];

  Future<void> addRandomElement() async {
    MyMobyncClient mobync = MyMobyncClient.instance;
    MobyncResponse res = await mobync.create(
      MyModel.tableName,
      MyModel(
              id: Uuid().v1(),
              field1: 'DEVICE2_${DateTime.now().toIso8601String()}')
          .toMap(),
    );
    if (res.success)
      await getData();
    else
      print('Create failed.');
  }

  Future<void> getData() async {
    MyMobyncClient mobync = MyMobyncClient.instance;
    MobyncResponse res = await mobync.read(MyModel.tableName);
    if (res.success) {
      setState(() {
        data = res.data.map((el) => MyModel.fromMap(el)).toList();
      });
    }
  }

  void sync() async {
    MyMobyncClient mobync = MyMobyncClient.instance;
    await mobync.synchronize();
    await getData();
  }

  Widget buildList() {
    List<Widget> list = [];
    for (int i = 0; i < data.length; i++)
      list.add(Container(
        color: Colors.white,
        margin: EdgeInsets.all(5),
        child: ListTile(
          leading: Text(
            '$i',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          title: Text(
            'id: ${data[i].id}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'field1: ${data[i].field1}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ));

    return ListView(children: list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mobync Demo using SQLite'),
      ),
      body: Container(
        color: Colors.black.withOpacity(0.05),
        child: Center(
          child: buildList(),
        ),
      ),
      persistentFooterButtons: [
        FloatingActionButton(
          onPressed: addRandomElement,
          tooltip: 'Add',
          child: Icon(Icons.add),
        ), //
        FloatingActionButton(
          onPressed: sync,
          tooltip: 'Sync',
          child: Icon(Icons.sync),
        ), //
      ],
    );
  }
}
