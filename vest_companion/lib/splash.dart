import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'pair.dart';

class SplashPage extends StatefulWidget {
  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  BluetoothState _bluetoothState = BluetoothState.off;

  @override
  void initState() {
    FlutterBlue.instance.state.listen((BluetoothState state) async {
      if (!mounted) return;
      if (state == BluetoothState.on) {
        var prefs = await SharedPreferences.getInstance();
        if (prefs.containsKey('vapticId')) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomePage(
                id: prefs.getString('vapticId'),
                authKey: prefs.getString('vapticKey'),
              ),
            ),
          );
        }
      }
      setState(() {
        _bluetoothState = state;
      });
    });
    super.initState();
  }

  List<Widget> getBluetoothIcon() {
    switch (_bluetoothState) {
      case BluetoothState.unknown:
      case BluetoothState.unavailable:
      case BluetoothState.unauthorized:
        return [
          Icon(Icons.bluetooth_disabled, color: Colors.red),
          SizedBox(height: 12),
          Text(
            "Unsupported Device",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          SizedBox(height: 12),
          FractionallySizedBox(
            widthFactor: 0.5,
            child: Text(
              "Your device does not support bluetooth, which is required for connection to your Vaptic.",
              textAlign: TextAlign.center,
            ),
          ),
        ];

      case BluetoothState.turningOn:
      case BluetoothState.turningOff:
      case BluetoothState.off:
        return [
          Icon(Icons.bluetooth, color: Colors.red),
          SizedBox(height: 12),
          Text(
            "Turn Bluetooth On",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          SizedBox(height: 12),
          FractionallySizedBox(
            widthFactor: 0.5,
            child: Text(
              "In order for your Vaptic to connect to your smartphone, you need to enable Bluetooth.",
              textAlign: TextAlign.center,
            ),
          ),
        ];

      case BluetoothState.on:
        return [
          Icon(Icons.bluetooth, color: Colors.green),
          SizedBox(height: 12),
          Text(
            "Pair Vaptic",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          SizedBox(height: 8),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: () async {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => PairPage(),
                ),
              );
            },
          ),
        ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/icon.png'),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 64),
                ...getBluetoothIcon(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
