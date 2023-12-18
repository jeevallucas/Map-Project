import 'dart:async';
import 'dart:convert';
import 'model/ModelLokasi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:maps_launcher/maps_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MapProject',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'MapProject'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LocationData? currentLocation;
  Location location = Location();

  List<Marker> allMarkers = [];
  late FollowOnLocationUpdate _followOnLocationUpdate;

  bool isLoading = true;
  bool isManualMarkerAdditionMode = false;

  double currentZoom = 13.0;
  late MapController mapController;

  String? tappedLatitude;
  String? tappedLongitude;

  Future<void> _fetchMarkersFromApi() async {
    try {
      const apiUrl = 'http://10.0.2.2/SlimAPI/public/mapproject/72210512/';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if (jsonData.containsKey('data') && jsonData['data'] is List) {
          final List<dynamic> data = jsonData['data'];

          setState(() {
            allMarkers.clear();

            for (final markerData in data) {
              try {
                final String lat = markerData['lat'].toString();
                final String lng = markerData['lng'].toString();
                final String informasi = markerData['informasi'];

                allMarkers.add(_createMarker(
                    double.parse(lat), double.parse(lng), informasi));
                // ignore: empty_catches
              } catch (e) {}
            }
          });
        }
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Marker _createMarker(double latitude, double longitude, String informasi) {
    return Marker(
      width: 100.0,
      height: 100.0,
      point: LatLng(latitude, longitude),
      child: IconButton(
        onPressed: () {
          _showLocationInfoDialog(latitude, longitude, informasi);
        },
        icon: Image.asset(
          'images/maps-icon-11.png',
          width: 20,
          height: 20,
        ),
      ),
    );
  }

  Future<void> _getLocation() async {
    try {
      currentLocation = await location.getLocation();
      setState(() {
        _fetchMarkersFromApi();
      });
      // ignore: empty_catches
    } catch (e) {}
  }

  void _toggleManualMarkerAdditionMode() {
    setState(() {
      isManualMarkerAdditionMode = !isManualMarkerAdditionMode;
    });

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isManualMarkerAdditionMode
                ? Icons.add_location
                : Icons.location_off,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            isManualMarkerAdditionMode
                ? "Ketuk peta untuk menambahkan marker."
                : "Mode penambahan marker secara manual dinonaktifkan.",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: isManualMarkerAdditionMode ? Colors.green : Colors.red,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _addMarker(LatLng tappedPoint) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        ModelLokasi lokasi = ModelLokasi(
          informasi: "",
          lat: tappedPoint.latitude,
          lng: tappedPoint.longitude,
        );

        return AlertDialog(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: "Informasi Lokasi",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  lokasi.informasi = value;
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Batal",
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Create a marker and add it to the map
                  Marker newMarker = _createMarker(
                    tappedPoint.latitude,
                    tappedPoint.longitude,
                    lokasi.informasi,
                  );

                  setState(() {
                    allMarkers.add(newMarker);
                  });

                  // Save the data to the API
                  await _sendDataToApi(lokasi);
                  await _fetchMarkersFromApi();

                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                // ignore: empty_catches
                } catch (e) {
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                "Simpan",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLocationInfoDialog(
      double latitude, double longitude, String informasi) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$latitude, $longitude',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info, color: Colors.green),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(informasi),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendDataToApi(ModelLokasi modelLokasi) async {}

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _followOnLocationUpdate = FollowOnLocationUpdate.once;
    _getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (currentLocation != null)
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                onTap: (tapPosition, tapLatlng) {
                  if (isManualMarkerAdditionMode) {
                    _addMarker(tapLatlng);
                  } else {
                    setState(() {
                      tappedLatitude = tapLatlng.latitude.toStringAsFixed(6);
                      tappedLongitude = tapLatlng.longitude.toStringAsFixed(6);
                    });
                  }
                },
                initialCenter: LatLng(
                  currentLocation!.latitude ?? 0.0,
                  currentLocation!.longitude ?? 0.0,
                ),
                initialZoom: currentZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  tileSize: 256,
                ),
                CurrentLocationLayer(
                  followOnLocationUpdate: _followOnLocationUpdate,
                ),
                MarkerLayer(markers: allMarkers),
              ],
            ),
          Card(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Koordinat Lokasi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tappedLatitude != null && tappedLongitude != null)
                            Text(
                              'Latitude: $tappedLatitude, Longitude: $tappedLongitude',
                              style: const TextStyle(
                                color: Colors.black87,
                              ),
                            )
                          else
                            const Text(
                              'Koordinat tidak tersedia. Ketuk peta.',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleManualMarkerAdditionMode,
        label: Text(
          isManualMarkerAdditionMode
              ? "Nonaktifkan Mode Manual"
              : "Tambahkan Marker secara Manual",
        ),
        icon: Icon(
          isManualMarkerAdditionMode
              ? Icons.location_off_rounded
              : Icons.add_location,
        ),
        backgroundColor: isManualMarkerAdditionMode ? Colors.red : Colors.white,
      ),
    );
  }
}