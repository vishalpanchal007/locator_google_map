import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main(){
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(

    ),
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);


  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  TextEditingController _searchController = TextEditingController();
  LatLng? _currentLocation;
  LatLng? _destination;
  bool _showSatelliteView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: MarkerId('currentLocation'),
          position: _currentLocation!,
          infoWindow: InfoWindow(title: 'Current Location'),
        ),
      );
    });
  }

  Future<void> _searchLocation(String searchQuery) async {
    if (searchQuery.isNotEmpty) {
      List<Location> locations =
      await locationFromAddress(searchQuery.toLowerCase());
      if (locations.isNotEmpty) {
        setState(() {
          _destination = LatLng(locations[0].latitude, locations[0].longitude);
          _markers.add(
            Marker(
              markerId: MarkerId('destination'),
              position: _destination!,
              infoWindow: InfoWindow(title: 'Destination'),
            ),
          );
        });
        _moveCameraToDestination();
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Location Not Found'),
              content: Text('Unable to find the specified location.'),
              actions: [
                ElevatedButton(

                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  void _moveCameraToDestination() {
    final CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(
            _currentLocation!.latitude < _destination!.latitude
                ? _currentLocation!.latitude
                : _destination!.latitude,
            _currentLocation!.longitude < _destination!.longitude
                ? _currentLocation!.longitude
                : _destination!.longitude),
        northeast: LatLng(
            _currentLocation!.latitude > _destination!.latitude
                ? _currentLocation!.latitude
                : _destination!.latitude,
            _currentLocation!.longitude > _destination!.longitude
                ? _currentLocation!.longitude
                : _destination!.longitude),
      ),
      100.0,
    );
    _controller!.animateCamera(cameraUpdate);
  }


  Future<void> _navigateToDestination() async {
   // https://www.google.com/maps/dir/?api=1&destination=
    if (_destination != null) {
      final url = '' +
          _destination!.latitude.toString() +
          ',' +
          _destination!.longitude.toString();
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Unable to navigate.'),
              actions: [
                ElevatedButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
    else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please set a destination location.'),
            actions: [
              ElevatedButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _toggleSatelliteView() {
    setState(() {
      _showSatelliteView = !_showSatelliteView;
    });
  }

  void _zoomIn() {
    _controller!.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _controller!.animateCamera(CameraUpdate.zoomOut());
  }

  Widget build(BuildContext context) {
    // if (_currentLocation == null) {
    // return Center(child: CircularProgressIndicator());
    //}
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps Example'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _controller = controller;
            },
            markers: _markers,
            compassEnabled: true,
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? LatLng(0, 0),
              zoom: 14.0,
            ),
            mapType:
            _showSatelliteView ? MapType.satellite : MapType.normal,
            myLocationEnabled: true,
          ),
          Positioned(
            top: 10.0,
            left: 10.0,
            right: 10.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      _searchLocation(_searchController.text);
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10.0,
            left: 10.0,
            child: Row(
              children: [
                FloatingActionButton(
                  child: Icon(Icons.layers),
                  onPressed: _toggleSatelliteView,
                ),
                SizedBox(width: 10.0),
                FloatingActionButton(
                  child: Icon(Icons.directions),
                  onPressed: _getCurrentLocation,
                ),
                SizedBox(width: 10.0),
                FloatingActionButton(
                  child: Icon(Icons.navigation),
                  onPressed: _navigateToDestination,
                ),
                SizedBox(width: 10.0),
                FloatingActionButton(
                  child: Icon(Icons.location_searching),
                  onPressed: _zoomIn,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}