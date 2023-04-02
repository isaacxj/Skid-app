import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
//import 'package:google_maps_webservice/directions.dart' as gmaps_ws;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:polyline/polyline.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';



class MapViewScreen extends StatefulWidget {
  @override
  _MapViewScreenState createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  late GoogleMapController _mapController;
  LatLng _initialCameraPosition = const LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<List<LatLng>> _fetchRouteData(LatLng origin, LatLng destination) async {
  const apiKey = 'AIzaSyDsrdxHDGObMKB9WcdkxeZxaft2t0DEgkw';
  final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$apiKey');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);

    if (jsonResponse['status'] == 'OK') {
      final points = jsonResponse['routes'][0]['overview_polyline']['points'];
      final PolylinePoints polylinePoints = PolylinePoints();
      final List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(points);
      final latLngPoints = decodedPoints.map((e) => LatLng(e.latitude, e.longitude)).toList();

      return latLngPoints;
    } else {
      throw Exception('Failed to fetch directions: ${jsonResponse['status']}');
    }
  } else {
    throw Exception('Failed to fetch directions with status code: ${response.statusCode}');
  }
}



  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      // ignore: use_build_context_synchronously
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Location permission denied'),
            content: const Text('Enable location permission in app settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print('User position: $position'); // Add this line
    setState(() {
      _initialCameraPosition = LatLng(position.latitude, position.longitude);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {});
  }

  Set<gmaps.Polyline> _polylines = {};

void _addPolyline(List<LatLng> points) {
  final polylineId = gmaps.PolylineId('${DateTime.now().millisecondsSinceEpoch}');
  final polyline = gmaps.Polyline(
    polylineId: polylineId,
    points: points,
    color: Colors.red,
    width: 5,
  );
  setState(() {
    _polylines.add(polyline);
  });
}


  StreamSubscription<Position>? _positionStream;
  List<Position> _positions = [];
  DateTime _rideStartTime = DateTime.now();

  void _startRide() {
  _rideStartTime = DateTime.now();
  final locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );
  _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
    setState(() {
      _positions.add(position);
    });
  });
}


  void _endRide() {
    _positionStream?.cancel();
    final rideDuration = DateTime.now().difference(_rideStartTime);
    double totalDistance = 0;
    for (int i = 0; i < _positions.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        _positions[i].latitude,
        _positions[i].longitude,
        _positions[i + 1].latitude,
        _positions[i + 1].longitude,
      );
    }
    final averageSpeed = totalDistance / rideDuration.inSeconds;
print('Ride duration: $rideDuration');
print('Average speed: $averageSpeed m/s');

// Save the ride data to Firestore
_saveRideData(
  route: _positions.map((position) => LatLng(position.latitude, position.longitude)).toList(),
  rideDuration: rideDuration,
  averageSpeed: averageSpeed,
);
}

Future<void> _saveRideData({
required List<LatLng> route,
required Duration rideDuration,
required double averageSpeed,
}) async {
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  throw Exception('User not signed in.');
}

final routeData = route.map((point) => {'lat': point.latitude, 'lng': point.longitude}).toList();
final rideData = {
  'route': routeData,
  'rideDuration': rideDuration.inSeconds,
  'averageSpeed': averageSpeed,
  'timestamp': FieldValue.serverTimestamp(),
};

await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .collection('rides')
    .add(rideData);
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Map View'),
    ),
    body: SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.9,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: _initialCameraPosition, zoom: 15),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: _onMapCreated,
        polylines: _polylines,
      ),
    ),
  );
}

}



