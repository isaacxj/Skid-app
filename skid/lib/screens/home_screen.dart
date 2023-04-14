import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skid/screens/login_screen.dart';
import 'package:skid/screens/map_view_screen.dart';
import 'package:skid/services/authentication_service.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  String _userName = '';
  final _authService = AuthenticationService();
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothDevice? _hc05Device;
  bool _isConnected = false;
  
  @override
void initState() {
  super.initState();
  _requestPermissions(); // Add this line
  _user = FirebaseAuth.instance.currentUser;
  if (_user != null) {
    _userName = _user!.displayName ?? '';
  }
}


Future<void> _requestPermissions() async {
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  }
}
  _findHC05Device() async {
  List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
  BluetoothDevice? foundDevice;
  for (BluetoothDevice device in devices) {
    if (device.name == 'HC-05') {
      foundDevice = device;
      break;
    }
  }
  if (foundDevice != null) {
    setState(() {
      _hc05Device = foundDevice;
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('HC-05 device not found. Please pair your device.'),
      ),
    );
  }
}


  _connectToDevice() async {
    if (_hc05Device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('HC-05 device not found. Please pair your device.'),
        ),
      );
      return;
    }
    if (_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected!'),
        ),
      );
      return;
    }

    await _bluetooth
        .connect(_hc05Device!)
        .timeout(Duration(seconds: 15), onTimeout: () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect. Timeout occurred.'),
        ),
      );
      return;
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect. Error: $error'),
        ),
      );
      return;
    });

    setState(() {
      _isConnected = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connected!'),
      ),
    );
  }



  int _currentIndex = 0;
  final List<Widget> _pages = [
    // Add the widgets for your pages here
    Center(child: Text('Home')),
    Center(child: Text('Map')),
    Center(child: Text('Rides')),
    Center(child: Text('Logout')),
  ];
  void _navigateToPage(int index) async {
    Widget page;
    switch (index) {
      case 0:
        page = HomeScreen();
        break;
      case 1:
        page = MapViewScreen();
        break;
      default:
        await _authService.signOut();
        page = LoginScreen();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => page),
      (route) => false,
    );
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
            Text(
              'Welcome $_userName',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _connectToDevice,
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _navigateToPage(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bike_scooter),
            label: 'Rides',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
            backgroundColor: Colors.black,
          ),
        ],
        // Set the background color
        selectedItemColor: Colors.white, // Set the selected item color
        unselectedItemColor: Colors.white,
      ),
    );
  }
}
