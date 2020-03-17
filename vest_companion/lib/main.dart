import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'splash.dart';

const String serviceUuid = '80000000-8000-8000-8000-766170746963';

Future<BluetoothCharacteristic> findCharacteristic(
  BluetoothDevice device,
) async {
  var service = (await device.discoverServices()).firstWhere(
    (s) => s.uuid.toString() == serviceUuid,
    orElse: () => null,
  );
  if (service == null) {
    throw Exception("Device is not a Vaptic! (0x00)");
  }
  var characteristic = service.characteristics.firstWhere(
    (s) => s.uuid.toString() == serviceUuid,
    orElse: () => null,
  );
  if (characteristic == null) {
    throw Exception("Device is not a Vaptic! (0x01)");
  }
  return characteristic;
}

Future<bool> writeToDevice(
  BluetoothCharacteristic characteristic,
  List<dynamic> params, {
  bool fast: false,
}) async {
  print('start');
  try {
    await characteristic.write(
      utf8
          .encode(json.encode([
            DateTime.now().millisecondsSinceEpoch,
            ...(fast ? [] : params),
          ]))
          .toList(),
      withoutResponse: fast,
    );
  print('end');
    return true;
  } catch (e) {
    print('Error while writing "$params": ${e.message}');
    print(e);
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
  final BluetoothDevice device;
  final String id;
  final String authKey;
  HomePage({this.device, this.id, this.authKey});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BluetoothDevice device;
  BluetoothCharacteristic characteristic;
  FlutterBlue bluetooth = FlutterBlue.instance;

  @override
  void initState() {
    connectToDevice();
    super.initState();
  }

  Future<void> connectToDevice() async {
    for (var device in await bluetooth.connectedDevices) {
      await device.disconnect();
    }
    if (widget.device != null) {
      setState(() {
        device = widget.device;
      });
    } else {
      var subscription = bluetooth.scan().listen((ScanResult scanResult) async {
        if (scanResult.device.id.id == widget.id) {
          print('Connecting to saved device: ${scanResult.device.name}');
          await scanResult.device.connect();
          characteristic = await findCharacteristic(scanResult.device);
          print(characteristic.uuid);
          var authResult = await writeToDevice(
            characteristic,
            ['auth', widget.authKey],
          );
          print('Auth: $authResult');
          if (authResult) {
            setState(() {
              device = scanResult.device;
            });
            while (true) {
              await writeToDevice(
                characteristic,
                ['matrix', List<double>.filled(24, 0)],
                fast: true,
              );
              await Future.delayed(Duration(seconds: 2));
            }
          } else {
            print("Auth failed");
          }
          await bluetooth.stopScan();
        }
      });
      await Future.delayed(Duration(seconds: 2));
      await subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    var rng = Random();
    return Scaffold(
      appBar: AppBar(
        title: Text('Vaptic'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text(
                'Connected to ${widget.id}',
                textAlign: TextAlign.center,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[900],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.exit_to_app,
              ),
              title: Text('Disconnect device'),
              onTap: () async {
                var prefs = await SharedPreferences.getInstance();
                await prefs.remove('vapticId');
                await prefs.remove('vapticKey');
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => SplashPage(),
                  ),
                );
              },
            )
          ],
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SvgPicture.asset(
                  'assets/Vest.svg',
                  width: 256,
                  height: 256,
                  color: Colors.white,
                ),
                SizedBox(
                  width: 64,
                  height: 256,
                  child: CustomPaint(
                    foregroundPainter: MatrixPainter(
                      height: 6,
                      width: 4,
                      intensities:
                          List<double>.generate(24, (_) => rng.nextDouble()),
                    ),
                  ),
                ),
              ],
            ),
            Text(device?.id?.id ?? 'Vaptic Offline'),
          ],
        ),
      ),
    );
  }
}

class MatrixPainter extends CustomPainter {
  List<double> intensities;
  int width;
  int height;

  MatrixPainter({
    this.intensities,
    this.width,
    this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    double yDist = size.height / (height - 1);
    double xDist = size.width / (width - 1);
    canvas.translate(0, (size.height - xDist * height) * 2 / 3);

    int i = 0;
    for (double y = 0; y < height; y++) {
      for (double x = 0; x < width; x++) {
        Offset point = Offset(x * xDist, y * xDist);
        paint..color = Colors.white.withAlpha((intensities[i] * 255).floor());
        i++;
        canvas.drawCircle(point, 5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(MatrixPainter oldDelegate) {
    return oldDelegate.intensities != this.intensities;
  }
}
