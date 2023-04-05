// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart'; 
// import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:polyline/polyline.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'dart:async';
// import 'package:skid/api_provider.dart';




// class MapViewScreen extends StatefulWidget {
//   @override
//   _MapViewScreenState createState() => _MapViewScreenState();
// }

// class _MapViewScreenState extends State<MapViewScreen> {
//   late GoogleMapController _mapController;
//   LatLng _initialCameraPosition = const LatLng(0, 0);
//   final ValueNotifier<bool> _isSearching = ValueNotifier<bool>(false);


//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_updateSearchResultsVisibility);
//     _getUserLocation();
//   }

//   @override
// void dispose() {
//   _searchController.removeListener(_updateSearchResultsVisibility);
//   _searchController.dispose();
//   super.dispose();
// }

//   Future<List<LatLng>> _fetchRouteData(LatLng origin, LatLng destination) async {
//   const apiKey = 'AIzaSyDsrdxHDGObMKB9WcdkxeZxaft2t0DEgkw';
//   final url = Uri.parse(
//       'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$apiKey');

//   final response = await http.get(url);

//   if (response.statusCode == 200) {
//     final jsonResponse = jsonDecode(response.body);

//     if (jsonResponse['status'] == 'OK') {
//       final points = jsonResponse['routes'][0]['overview_polyline']['points'];
//       final PolylinePoints polylinePoints = PolylinePoints();
//       final List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(points);
//       final latLngPoints = decodedPoints.map((e) => LatLng(e.latitude, e.longitude)).toList();

//       return latLngPoints;
//     } else {
//       throw Exception('Failed to fetch directions: ${jsonResponse['status']}');
//     }
//   } else {
//     throw Exception('Failed to fetch directions with status code: ${response.statusCode}');
//   }
// }



//   Future<void> _getUserLocation() async {
//     LocationPermission permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.deniedForever) {
      
//       return showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: const Text('Location permission denied'),
//             content: const Text('Enable location permission in app settings.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('OK'),
//               ),
//             ],
//           );
//         },
//       );
//     }
//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//     print('User position: $position'); // Add this line
//     setState(() {
//       _initialCameraPosition = LatLng(position.latitude, position.longitude);
//     });
//   }

//   void _searchPlaces(String searchTerm) async {
//     if (searchTerm.isEmpty) {
//       _isSearching.value = false;
//       setState(() {
//         _searchResults = [];
//       });
//       return;
//     }

//     _isSearching.value = true;

//     try {
//       List<dynamic> results = await ApiProvider().searchPlaces(searchTerm);
//       setState(() {
//         _searchResults = results;
//       });
//     } catch (e) {
//       print('Error fetching search results: $e');
//     } finally {
//       _isSearching.value = false;
//     }
//   }


// final TextEditingController _searchController = TextEditingController();



//   void _onMapCreated(GoogleMapController controller) {
//     _mapController = controller;
//     setState(() {});
//   }

//   Set<gmaps.Polyline> _polylines = {};

// void _addPolyline(List<LatLng> points) {
//   final polylineId = gmaps.PolylineId('${DateTime.now().millisecondsSinceEpoch}');
//   final polyline = gmaps.Polyline(
//     polylineId: polylineId,
//     points: points,
//     color: Colors.red,
//     width: 5,
//   );
//   setState(() {
//     _polylines.add(polyline);
//   });
// }


//   StreamSubscription<Position>? _positionStream;
//   List<Position> _positions = [];
//   DateTime _rideStartTime = DateTime.now();

//   void _startRide() {
//   _rideStartTime = DateTime.now();
//   final locationSettings = const LocationSettings(
//     accuracy: LocationAccuracy.high,
//     distanceFilter: 10,
//   );
//   _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
//     setState(() {
//       _positions.add(position);
//     });
//   });
// }


//   void _endRide() {
//     _positionStream?.cancel();
//     final rideDuration = DateTime.now().difference(_rideStartTime);
//     double totalDistance = 0;
//     for (int i = 0; i < _positions.length - 1; i++) {
//       totalDistance += Geolocator.distanceBetween(
//         _positions[i].latitude,
//         _positions[i].longitude,
//         _positions[i + 1].latitude,
//         _positions[i + 1].longitude,
//       );
//     }
//     final averageSpeed = totalDistance / rideDuration.inSeconds;
// print('Ride duration: $rideDuration');
// print('Average speed: $averageSpeed m/s');

// // Save the ride data to Firestore
// _saveRideData(
//   route: _positions.map((position) => LatLng(position.latitude, position.longitude)).toList(),
//   rideDuration: rideDuration,
//   averageSpeed: averageSpeed,
// );
// }

// Future<void> _saveRideData({
// required List<LatLng> route,
// required Duration rideDuration,
// required double averageSpeed,
// }) async {
// final user = FirebaseAuth.instance.currentUser;
// if (user == null) {
//   throw Exception('User not signed in.');
// }

// final routeData = route.map((point) => {'lat': point.latitude, 'lng': point.longitude}).toList();
// final rideData = {
//   'route': routeData,
//   'rideDuration': rideDuration.inSeconds,
//   'averageSpeed': averageSpeed,
//   'timestamp': FieldValue.serverTimestamp(),
// };

// await FirebaseFirestore.instance
//     .collection('users')
//     .doc(user.uid)
//     .collection('rides')
//     .add(rideData);
// }


// List<dynamic> _searchResults = [];

// Widget _buildSearchResults(List<dynamic> results) {
//   return ListView.builder(
//     itemCount: results.length,
//     itemBuilder: (BuildContext context, int index) {
//       final result = results[index];
//       return ListTile(
//         title: Text(result['structured_formatting']['main_text']),
//         subtitle: Text(result['structured_formatting']['secondary_text']),
//         onTap: () {
//           // Handle when a search result is tapped
//           _onLocationSelected(result);
//         },
//       );
//     },
//   );
// }
// void _onLocationSelected(SearchResult result) async {
//   _isSearching.value = false;
//   _searchController.clear();

//   LatLng destination = LatLng(result.geometry.location.lat, result.geometry.location.lng);
//   LatLng origin = LatLng(_currentLocation.latitude, _currentLocation.longitude);

//   // Get the route between the user's current location and the selected destination
//   List<LatLng> route = await _getRoute(origin, destination);

//   // Update the map to display the route
//   _updateMapWithRoute(route, origin, destination);
// }

// Future<List<LatLng>> _getRoute(LatLng origin, LatLng destination) async {
//   final String apiKey = 'AIzaSyDsrdxHDGObMKB9WcdkxeZxaft2t0DEgkw';
//   final String url =
//       'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

//   http.Response response = await http.get(Uri.parse(url));

//   if (response.statusCode == 200) {
//     Map<String, dynamic> jsonResponse = jsonDecode(response.body);
//     String encodedPoints = jsonResponse['routes'][0]['overview_polyline']['points'];
//     return polylinePoints.decodePolyline(encodedPoints).map((point) => LatLng(point.latitude, point.longitude)).toList();
//   } else {
//     throw Exception('Failed to fetch directions');
//   }
// }
// void _updateMapWithRoute(List<LatLng> route, LatLng origin, LatLng destination) {
//   // Remove any existing polylines and markers
//   _polylines.clear();
//   _markers.clear();

//   // Add the origin and destination markers
//   _markers.add(Marker(markerId: MarkerId('origin'), position: origin, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)));
//   _markers.add(Marker(markerId: MarkerId('destination'), position: destination, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)));

//   // Add the polyline for the route
//   _polylines.add(Polyline(polylineId: PolylineId('route'), points: route, color: Colors.blue, width: 5));

//   // Animate the map to show the entire route
//   LatLngBounds bounds = _calculateBounds(route);
//   _googleMapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));

//   setState(() {});
// }
// LatLngBounds _calculateBounds(List<LatLng> route) {
//   double minLat = route[0].latitude;
//   double maxLat = route[0].latitude;
//   double minLng = route[0].longitude;
//   double maxLng = route[0].longitude;

//   for (final point in route) {
//     minLat = min(minLat, point.latitude);
//     maxLat = max(maxLat, point.latitude);
//     minLng = min(minLng, point.longitude);
//     maxLng = max(maxLng, point.longitude);
//   }

//   LatLng southwest = LatLng(minLat, minLng);
//   LatLng northeast = LatLng(maxLat, maxLng);

//   return LatLngBounds(southwest: southwest, northeast: northeast);
// }
//DELETE



// void _updateSearchResultsVisibility() {
//   if (_searchController.text.isEmpty) {
//     _isSearching.value = false;
//   } else {
//     _isSearching.value = true;
//   }
// }


// // @override
// // Widget build(BuildContext context) {
// //   return Scaffold(
// //     appBar: AppBar(
// //       title: Text('Map View'),
// //     ),
// //     body: SizedBox(
// //       width: MediaQuery.of(context).size.width,
// //       height: MediaQuery.of(context).size.height * 0.9,
// //       child: GoogleMap(
// //         initialCameraPosition: CameraPosition(target: _initialCameraPosition, zoom: 15),
// //         myLocationEnabled: true,
// //         myLocationButtonEnabled: true,
// //         onMapCreated: _onMapCreated,
// //         polylines: _polylines,
// //       ),
// //     ),
// //   );
// // }
//   @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     body: Stack(
//       children: [
//         GoogleMap(
//           onMapCreated: _onMapCreated,
//           initialCameraPosition: CameraPosition(target: _initialCameraPosition, zoom: 15.0),
//           myLocationEnabled: true,
//           myLocationButtonEnabled: true,
//         ),
//         Positioned(
//           top: 50.0,
//           left: 15.0,
//           right: 15.0,
//           child: Container(
//             height: 50.0,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10.0),
//               color: Colors.white,
//             ),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search destination',
//                 border: InputBorder.none,
//                 contentPadding: EdgeInsets.only(left: 15.0, top: 15.0),
//                 suffixIcon: Icon(Icons.search, size: 30.0),
//               ),
//               onChanged: (value) {
//                 _searchPlaces(value);
//               },
//             ),
//           ),
//         ),
//         ValueListenableBuilder<bool>(
//           valueListenable: _isSearching,
//           builder: (BuildContext context, bool isSearching, Widget? child) {
//             if (isSearching) {
//               return Positioned(
//                 top: 90.0,
//                 right: 15.0,
//                 left: 15.0,
//                 child: Container(
//                   height: 300.0,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10.0),
//                   ),
//                   child: _buildSearchResults(_searchResults),
//                 ),
//               );
//             } else {
//               return SizedBox.shrink();
//             }
//           },
//         ),
//       ],
//     ),
//   );
// }





  
// }



import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'navigation_screen.dart';

class MapViewScreen extends StatefulWidget {
  @override
  _MapViewScreenState createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  late GoogleMapController _googleMapController;
  LatLng? _origin;
  LatLng? _destination;
  List<LatLng> _polylineCoordinates = [];
  LatLng _initialCameraPosition = LatLng(0, 0);
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
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

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _initialCameraPosition = LatLng(position.latitude, position.longitude);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _googleMapController = controller;
  }

  Future<void> _searchAndNavigate() async {
    if (_searchController.text.isEmpty) {
      return;
    }

    final apiKey = 'AIzaSyDsrdxHDGObMKB9WcdkxeZxaft2t0DEgkw';
    final query = _searchController.text;
    final location = '${_initialCameraPosition.latitude},${_initialCameraPosition.longitude}';
    final url = Uri.parse('https://maps.googleapis.com/maps/api/place/findplacefromtext/json?key=$apiKey&input=$query&inputtype=textquery&fields=geometry&locationbias=point:$location');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'OK') {
        final lat = jsonResponse['candidates'][0]['geometry']['location']['lat'];
        final lng = jsonResponse['candidates'][0]['geometry']['location']['lng'];
        LatLng destination = LatLng(lat, lng);

        final directions = await _getDirections(_initialCameraPosition, destination, apiKey);

        if (directions != null) {
          _addMarker(destination);
          _addPolyline(directions);
        }
      } else {
        throw Exception('Failed to fetch search results: ${jsonResponse['status']}');
      }
    } else {
      throw Exception('Failed to fetch search results with status code: ${response.statusCode}');
    }
  }

  Future<List<LatLng>?> _getDirections(LatLng origin, LatLng destination, String apiKey) async {
    final url = Uri.parse('https://maps.googleapis.com/maps/api/directions/json?key=$apiKey&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'OK') {
        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> result = polylinePoints.decodePolyline(jsonResponse['routes'][0]['overview_polyline']['points']);

        List<LatLng> polylineCoordinates = result.map((point) => LatLng(point.latitude, point.longitude)).toList();
        return polylineCoordinates;
      } else {
        throw Exception('Failed to fetch directions: ${jsonResponse['status']}');
      }
    } else {
      throw Exception('Failed to fetch directions with status code: ${response.statusCode}');
    }
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId('destination'),
          position: position,
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });
  }

  void _addPolyline(List<LatLng> polylineCoordinates) {
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: polylineCoordinates,
        ),
      );
    });
  }

  void _zoomToFit(LatLngBounds bounds) {
    double screenPadding = 100;
    _googleMapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, screenPadding),
    );
  }

  void _startRide() {
    if (_origin != null && _destination != null && _polylineCoordinates.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NavigationScreen(
            origin: _origin!,
            destination: _destination!,
            polylineCoordinates: _polylineCoordinates,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a destination first.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _origin ?? _initialCameraPosition, zoom: 15),
            onMapCreated: _onMapCreated,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Container(
              height: 50,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                                    suffixIcon: IconButton(
                    onPressed: _searchAndNavigate,
                    icon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
          ),
          if (_destination != null)
            Positioned(
              bottom: 20,
              left: 15,
              right: 15,
              child: ElevatedButton(
                onPressed: _startRide,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('START RIDE', style: TextStyle(fontSize: 20)),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


