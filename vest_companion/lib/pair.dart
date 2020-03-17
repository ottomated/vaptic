import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:vest_companion/main.dart';

import 'splash.dart';

const String serviceUuid = '80000000-8000-8000-8000-766170746963';

class PairPage extends StatefulWidget {
  @override
  _PairPageState createState() => _PairPageState();
}

class _PairPageState extends State<PairPage> {
  Set<BluetoothDevice> devices = Set();
  FlutterBlue bluetooth;
  StreamSubscription scanSubscription;
  bool _scanning = false;
  var _uuid = Uuid();

  @override
  void initState() {
    bluetooth = FlutterBlue.instance;
    bluetooth.state.listen((BluetoothState state) async {
      if (!mounted) return;
      if (state != BluetoothState.on) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SplashPage(),
          ),
        );
      }
    });
    startScan();
    super.initState();
  }

  @override
  void dispose() {
    bluetooth.stopScan();
    scanSubscription.cancel();
    super.dispose();
  }

  Future<void> startScan() async {
    if (_scanning) {
      await bluetooth.stopScan();
      await scanSubscription.cancel();
    }
    setState(() {
      _scanning = true;
      devices = Set();
    });
    for (var device in await bluetooth.connectedDevices) {
      await device.disconnect();
    }
    scanSubscription = bluetooth.scan().listen((ScanResult scanResult) async {
      if (scanResult.device.name != '') {
        setState(() {
          devices.add(scanResult.device);
        });
      }
    });
    await Future.delayed(Duration(seconds: 10));
    await bluetooth.stopScan();
    await scanSubscription.cancel();
    if (!mounted) return;
    setState(() {
      _scanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children;
    if (devices.length == 0) {
      if (_scanning) {
        children = [
          ListTile(
            title: Text('Scanning for devices...'),
            leading: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2.0,
            ),
          ),
        ];
      } else {
        children = [
          ListTile(
            title: Text(
                'No Vaptic devices found. Ensure your device is turned on.'),
            leading: Icon(Icons.close, size: 32),
            trailing: RaisedButton(
              child: Text('Retry'),
              onPressed: startScan,
            ),
          ),
        ];
      }
    } else {
      children = devices.map((BluetoothDevice device) {
        return Builder(
          builder: (context) => ListTile(
            title: Text(device.name),
            subtitle: Text(device.id.toString()),
            trailing: Icon(Icons.chevron_right),
            onTap: () async {
              try {
                for (var device in await bluetooth.connectedDevices) {
                  await device.disconnect();
                }
                await device.connect().timeout(
                      Duration(seconds: 3),
                      onTimeout: () => throw Exception("Connection timed out!"),
                    );
                var characteristic = await findCharacteristic(device);
                print(characteristic);
                // Generate shared key
                var key = _uuid.v4();
                var authResult = await writeToDevice(
                  characteristic,
                  ['auth', key],
                );
                if (authResult) {
                  var prefs = await SharedPreferences.getInstance();
                  prefs.setString('vapticId', device.id.id);
                  prefs.setString('vapticKey', key);
                } else {
                  throw Exception(
                    "Vaptic is already paired to another device!",
                  );
                }
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => HomePage(
                        id: device.id.id, authKey: key, device: device),
                  ),
                );
              } catch (e) {
                device.disconnect();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(5.0),
                      ),
                    ),
                    title: Text('Error'),
                    content: SingleChildScrollView(
                      child: Text(
                        '${e.message[0].toUpperCase()}${e.message.substring(1)}',
                      ),
                    ),
                    actions: <Widget>[
                      FlatButton(
                        textColor: Colors.red,
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
                print(e);
              }
            },
          ),
        );
      }).toList();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("V"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          startScan();
          await Future.delayed(Duration(seconds: 1));
        },
        child: ListView(
          children: children,
        ),
      ),
    );
  }
}
