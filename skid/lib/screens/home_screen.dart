import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skid/screens/login_screen.dart';
import 'package:skid/screens/map_view_screen.dart';
import 'package:skid/services/authentication_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:location/location.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BluetoothConnection(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}


class BluetoothConnection extends ChangeNotifier {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final Uuid _targetService = Uuid.parse("00001101-0000-1000-8000-00805F9B34FB");
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  ConnectionStateUpdate? _connectionState;
  bool _isScanning = false;
  late StreamSubscription<ConnectionStateUpdate> _connection;

  Future<void> checkLocationServicesAndPermission() async {
  Location location = Location();
  bool serviceEnabled;
  ph.PermissionStatus permissionStatus;

  // Check if location services are enabled
  serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      // Show an error message or prompt the user to enable location services
      return;
    }
  }

  // Request location permission
  permissionStatus = await ph.Permission.location.request();
  if (permissionStatus.isGranted) {
    // Start scanning for devices
  } else {
    // Show an error message or prompt the user to grant permission
  }
}


  Future<void> startScan() async {
    if (_isScanning) return;
    await checkLocationServicesAndPermission();
    _isScanning = true;
    _scanSubscription = _ble.scanForDevices(
      withServices: [_targetService],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (device.name == "HC-05") {
        stopScan();
        _connectToDevice(device.id);
      }
    });
  }

  void stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
  }

  Future<void> _connectToDevice(String deviceId) async {
    _connectionSubscription?.cancel();
    _connectionSubscription = _ble.connectToAdvertisingDevice(
      id: deviceId,
      withServices: [_targetService],
      prescanDuration: const Duration(seconds: 5),
      connectionTimeout: const Duration(seconds: 2),
    ).listen((connectionState) {
      _connectionState = connectionState;
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        print('Connected to HC-05');
      } else if (connectionState.connectionState ==
          DeviceConnectionState.disconnected) {
        print('Disconnected from HC-05');
      }
    });

  }

        Future<void> disconnect() async {
    if (_connectionState == null ||
        _connectionState!.connectionState != DeviceConnectionState.connected) {
      return;
    }
    try {
      await _connection.cancel();
    } catch (e) {
      print("Error disconnecting from device: $e");
    }
  }




  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}



class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  String _userName = '';
  final _authService = AuthenticationService();

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _userName = _user!.displayName ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome $_userName',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 24),
          ElevatedButton(
  onPressed: () {
    final connection =
        Provider.of<BluetoothConnection>(context, listen: false);
    connection.startScan();
  },
  child: Text('Connect to Bike'),
),


          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              // Implement navigation to the map screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapViewScreen()),
              );
            },
            child: Text('View Map'),
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              // Implement navigation to the past rides screen
            },
            child: Text('View Past Rides'),
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              // Implement navigation to the past rides screen
              await _authService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('Logout'),
          ),
        ],
      ),
    ),);
  }
}

