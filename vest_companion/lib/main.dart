import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'splash.dart';

const String serviceUuid = '80000000-8000-8000-8000-766170746963';

Future<bool> writeString(
    BluetoothCharacteristic characteristic, String string) async {
  try {
    await characteristic.write(utf8.encode(string).toList());
    return true;
  } catch (e) {
    print('Error while writing "$string": ${e.message}');
    return false;
  }
}

void main() => runApp(VestApp());

class VestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vest Companion',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        brightness: Brightness.dark,
      ),
      home: SplashPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<BluetoothDevice> devices = Set();
  bool scanning = false;
  FlutterBlue bluetooth = FlutterBlue.instance;
  BluetoothService service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vest Companion'),
        centerTitle: true,
      ),
    );
  }
}
