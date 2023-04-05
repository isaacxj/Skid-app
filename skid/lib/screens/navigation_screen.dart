import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> polylineCoordinates;

  NavigationScreen({required this.origin, required this.destination, required this.polylineCoordinates});

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Navigation'),
      ),
      body: Stack(
        children: [
          // GoogleMap widget with navigation data
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: ElevatedButton(
              onPressed: () {
                // End the ride and send data to the database
              },
              child: Text('END RIDE'),
            ),
          ),
        ],
      ),
    );
  }
}
