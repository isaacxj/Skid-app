import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart' as loc;
import 'package:latlong2/latlong.dart' as latlng2;

import 'LocationService.dart';

void main() => runApp(MapViewScreen());

class MapViewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maps and Navigation',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();
  TextEditingController _originController = TextEditingController();
  PolylineId? _currentRoutePolylineId;
  LatLng _initialCameraPosition = const LatLng(0, 0);
  TextEditingController _destinationController = TextEditingController();
  loc.Location location = new loc.Location();
  loc.LocationData? _locationData;
  Set<Marker> _markers = Set<Marker>();
  Set<Polygon> _polygons = Set<Polygon>();
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polygonLatLngs = <LatLng>[];
  bool _isRideActive = false;
  bool _rideStarted = false;

  double _currentDistance = 0.0;
  double _totalDistance = 0.0;
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371.0; // Radius of the Earth in kilometers

    double lat1 = point1.latitude * pi / 180;
    double lon1 = point1.longitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double lon2 = point2.longitude * pi / 180;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  Stopwatch _rideStopwatch = Stopwatch();

  int _polygonIdCounter = 1;
  int _polylineIdCounter = 1;

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(49.940605743955274, -119.39517000394746),
    zoom: 18.0000,
  );

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _setMarker(LatLng point) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('marker'),
          position: point,
        ),
      );
    });
  }

  int _findNearestPolylineIndex(
      List<LatLng> polylinePoints, LatLng userLocation) {
    int nearestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < polylinePoints.length; i++) {
      double distance = _calculateDistance(userLocation, polylinePoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    return nearestIndex;
  }

  void _setPolygon() {
    final String polygonIdVal = 'polygon_$_polygonIdCounter';
    _polygonIdCounter++;

    _polygons.add(
      Polygon(
        polygonId: PolygonId(polygonIdVal),
        points: polygonLatLngs,
        strokeWidth: 0,
        fillColor: Colors.transparent,
      ),
    );
  }

  Future<void> _getUserLocation() async {
    geo.LocationPermission permission =
        await geo.Geolocator.requestPermission();
    if (permission == geo.LocationPermission.deniedForever) {
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
    geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high);
    print('User position: $position'); // Add this line
    setState(() {
      _initialCameraPosition = LatLng(position.latitude, position.longitude);
      _originController.text = "${position.latitude},${position.longitude}";
    });
  }

  void _updatePolyline() async {
    if (_destinationController.text.isNotEmpty) {
      // Calculate the new route based on the updated user location
      List<PointLatLng> points = await LocationService.getRouteCoordinates(
        _originController.text,
        _destinationController.text,
      );
      // Calculate the total distance
      _totalDistance = 0;
      for (int i = 0; i < points.length - 1; i++) {
        LatLng point1 = LatLng(points[i].latitude, points[i].longitude);
        LatLng point2 = LatLng(points[i + 1].latitude, points[i + 1].longitude);
        _totalDistance += _calculateDistance(point1, point2);
      }
      _totalDistance = _totalDistance * 1000;
      setState(() {
        // Remove the old route if it exists
        if (_currentRoutePolylineId != null) {
          _polylines.removeWhere((Polyline polyline) =>
              polyline.polylineId == _currentRoutePolylineId);
        }

        final String polylineIdVal = 'polyline_$_polylineIdCounter';
        _polylineIdCounter++;

        Polyline newRoute = Polyline(
          polylineId: PolylineId(polylineIdVal),
          width: 6,
          color: Color.fromARGB(255, 255, 0, 0),
          points: points
              .map(
                (point) => LatLng(point.latitude, point.longitude),
              )
              .toList(),
        );

        _polylines.add(newRoute);
        _currentRoutePolylineId = newRoute.polylineId;
      });
    }
  }

  void _setupLocationListener() {
    location.enableBackgroundMode(enable: true);
    location.onLocationChanged.listen((loc.LocationData currentLocation) {
      setState(() {
        _locationData = currentLocation;
        _originController.text =
            "\${currentLocation.latitude},\${currentLocation.longitude}";

        if (_polylines.isNotEmpty && _currentRoutePolylineId != null) {
          Polyline currentRoute = _polylines.firstWhere(
              (Polyline polyline) =>
                  polyline.polylineId == _currentRoutePolylineId,
              orElse: () => Polyline(polylineId: PolylineId('invalid')));

          if (currentRoute.polylineId != PolylineId('invalid')) {
            int nearestIndex = _findNearestPolylineIndex(
                currentRoute.points,
                LatLng(currentLocation.latitude ?? 0.0,
                    currentLocation.longitude ?? 0.0));
            List<LatLng> newPolylinePoints =
                currentRoute.points.sublist(nearestIndex);
            setState(() {
              _polylines.remove(currentRoute);
              _polylines.add(
                Polyline(
                  polylineId: currentRoute.polylineId,
                  width: currentRoute.width,
                  color: currentRoute.color,
                  points: newPolylinePoints,
                ),
              );
            });
          }
        }

        _updatePolyline();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text('Maps and Navigation '),
        backgroundColor: Colors.deepPurple.shade900,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _originController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            hintText: '  Enter Start Address',
                            icon: Icon(Icons.gps_fixed)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            hintText: '  Enter Destination Address',
                            helperText:
                                'Ex: 1234 International Mews, Kelowna, BC V1Y 9X3',
                            suffixIcon: Icon(Icons.location_on_outlined)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              markers: _markers,
              polygons: _polygons,
              polylines: _polylines,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onTap: (point) {
                setState(
                  () {
                    polygonLatLngs.add(point);
                    _setPolygon();
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      'Total Distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Ridden Distance: ${(_currentDistance / 1000).toStringAsFixed(2)} km',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(width: 10),
                FloatingActionButton.extended(
                  extendedPadding: const EdgeInsets.all(8.0),
                  label: Text(_isRideActive ? 'Stop Ride' : 'Start Ride'),
                  icon: Icon(_isRideActive ? Icons.stop : Icons.route),
                  backgroundColor: Colors.deepPurple.shade900,
                  onPressed: () {
                    if (_isRideActive) {
                      _stopRide();
                    } else {
                      _startRide();
                    }
                  },
                ),
              ],
            ),
          ),
          Container(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: RichText(
                text: TextSpan(
                  text: 'Version 1.0',
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startRide() async {
    var directions = await LocationService.getDirections(
      _originController.text,
      _destinationController.text,
    );

    _goToPlace(
      directions['start_location']['lat'],
      directions['start_location']['lng'],
      directions['bounds_ne'],
      directions['bounds_sw'],
    );
    _updatePolyline();
    _isRideActive = true;
    _rideStopwatch.start();

    setState(() {});
  }

  void _stopRide() {
    _isRideActive = false;
    _rideStopwatch.stop();

    int elapsedTimeInSeconds = _rideStopwatch.elapsed.inSeconds;
    int minutes = (elapsedTimeInSeconds / 60).floor();
    int seconds = elapsedTimeInSeconds % 60;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ride Time'),
          content: Text('Time taken for the bike ride: $minutes:$seconds'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    Future.delayed(Duration(seconds: 1), () {
      // Reset the map and other elements to their initial states
      _rideStopwatch.reset();
      _markers.clear();
      _polylines.clear();
      _destinationController.clear();
      setState(() {});
    });
  }

  Future<void> _goToPlace(
    double lat,
    double lng,
    Map<String, dynamic> boundsNe,
    Map<String, dynamic> boundsSw,
  ) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(lat, lng),
            zoom: 12,
            tilt: _rideStarted ? 60 : 0), // Add tilt parameter here
      ),
    );
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
            northeast: LatLng(boundsNe['lat'], boundsNe['lng']),
          ),
          25),
    );
    _setMarker(LatLng(lat, lng));
  }
}
