import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_basic/flutter_bluetooth_basic.dart';

void main() => runApp(VestApp());

class VestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vest Companion',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<BluetoothDevice> devices = [];
  bool scanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vest Companion'),
        centerTitle: true,
      ),
      body: ListView(
        children: devices
            .map(
              (BluetoothDevice d) => ListTile(
                title: Text(d.name),
                subtitle: Text(d.address),
                trailing: Text(d.type.toString()),
              ),
            )
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.bluetooth),
        onPressed: scanning
            ? null
            : () async {
                var man = BluetoothManager.instance;
                setState(() {
                  scanning = true;
                });
                man.startScan(timeout: Duration(seconds: 10));
                man.state.listen((state) async {
                  if (state == BluetoothManager.DISCONNECTED) {
                    setState(() {
                      scanning = false;
                    });
                  }
                  man.scanResults.listen((data) {
                    setState(() {
                      devices = data;
                    });
                  });
                });
              },
      ),
    );
  }
}
