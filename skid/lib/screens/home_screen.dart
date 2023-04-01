import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  String _userName = '';

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
            Text(
              'Welcome $_userName',
              style: Theme.of(context).textTheme.headline4,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Implement Bluetooth connection
              },
              child: Text('Connect to Bike'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Implement navigation to the map screen
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
          ],
        ),
      ),
    );
  }
}
