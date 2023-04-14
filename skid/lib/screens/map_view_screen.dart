import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart' as loc;

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

      // Remove the old route if it exists
      if (_currentRoutePolylineId != null) {
        setState(() {
          _polylines.removeWhere((Polyline polyline) =>
              polyline.polylineId == _currentRoutePolylineId);
        });
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

      setState(() {
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
        _updatePolyline();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text('Maps and Navigation '),
        backgroundColor: Color.fromARGB(255, 255, 52, 2),
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
              mapType: MapType.satellite,
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
            child: FloatingActionButton.extended(
              extendedPadding: const EdgeInsets.all(8.0),
              label: const Text('Calculate Distance'),
              icon: const Icon(Icons.route),
              backgroundColor: Colors.deepPurple.shade900,
              onPressed: () async {
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
              },
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

  Future<void> _goToPlace(
    double lat,
    double lng,
    Map<String, dynamic> boundsNe,
    Map<String, dynamic> boundsSw,
  ) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 12),
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
