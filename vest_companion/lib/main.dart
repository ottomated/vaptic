import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

const String serviceUuid = '80000000-8000-8000-8000-766170746963';

Future<void> writeString(
    BluetoothCharacteristic characteristic, String string) async {
  return await characteristic.write(utf8.encode(string).toList());
}

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
  Set<BluetoothDevice> devices = Set();
  bool scanning = false;
  FlutterBlue bluetooth = FlutterBlue.instance;
  BluetoothService service;

  void showError(String error) {
    print("ERROR: $error");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vest Companion'),
        centerTitle: true,
      ),
      body: ListView(
        children: devices.map((BluetoothDevice device) {
          bool isVaptic = device.name == 'Vaptic';
          return Container(
            color: isVaptic
                ? Colors.lightGreen.withAlpha(100)
                : Colors.transparent,
            child: ListTile(
                onTap: isVaptic
                    ? () async {
                        try {
                          await device.connect();
                          service = (await device.discoverServices())
                              .firstWhere(
                                  (s) => s.uuid.toString() == serviceUuid);
                          if (service == null) {
                            showError("Device is not a valid Vaptic!");
                          }
                        } catch (e) {
                          showError(e.toString());
                        }
                        List<BluetoothService> services =
                            await device.discoverServices();
                        services.forEach((service) {
                          if (service.uuid.toString() == serviceUuid) {
                            service.characteristics
                                .forEach((BluetoothCharacteristic char) async {
                              await char.setNotifyValue(true);
                              char.value.listen((data) {
                                print("Received ${utf8.decode(data)}");
                              });
                              await writeString(char, 'Hello World!');
                            });
                          }
                        });
                      }
                    : null,
                title: Text(device.name),
                subtitle: Text(device.id.toString()),
                trailing: isVaptic ? Icon(Icons.chevron_right) : null),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.bluetooth),
        backgroundColor: scanning ? Colors.grey : Colors.deepPurple,
        onPressed: scanning
            ? null
            : () async {
                setState(() {
                  scanning = true;
                  devices.clear();
                });
                for (var device in await bluetooth.connectedDevices) {
                  await device.disconnect();
                }
                var scanSubscription =
                    bluetooth.scan().listen((scanResult) async {
                  setState(() {
                    if (scanResult.advertisementData.localName != '')
                      devices.add(scanResult.device);
                  });
                });
                await Future.delayed(Duration(seconds: 5));
                await bluetooth.stopScan();
                await scanSubscription.cancel();
                setState(() {
                  scanning = false;
                });
              },
      ),
    );
  }
}
