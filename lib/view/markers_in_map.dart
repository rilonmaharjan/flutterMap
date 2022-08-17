import 'package:flutter/material.dart';
import 'package:flutter_maps/json/markers_location.dart';
import 'package:flutter_maps/view/distance.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Markers extends StatefulWidget {
  const Markers({Key? key}) : super(key: key);

  @override
  State<Markers> createState() => _MarkersState();
}

class _MarkersState extends State<Markers> {
  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));

  late GoogleMapController mapController;

  late Position _currentPosition;

  Set<Marker> markers = {}; //markers for google map

  Map<String, dynamic> addedMarkers = {}; //added markers

  Set<Polyline> polylines = {};

  List<LatLng> latlng = []; //list of lat and long

  List joinStops = []; //joined lat long values

  List joinStopsNoLast = []; //joined lat long values without last value

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    getpolyline();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        height: height,
        width: width,
        child: Stack(
          children: [
            //Google Map
            GoogleMap(
              markers: getmarkers(),
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              polylines: polylines,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),

            //title
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                    ),
                    width: width * 0.8,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                      child: Text(
                        'Add Markers',
                        style: TextStyle(fontSize: 20.0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            //launch google map app
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, right: 10),
                  child: GestureDetector(
                    onTap: () {
                      launchGoogleMaps();
                    },
                    child: ClipOval(
                      child: Material(
                        color: Colors.white70, // button color
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(Icons.map),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            //Navigator button
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 80.0, bottom: 10.0),
                  child: ClipOval(
                    child: Material(
                      color: Colors.orange.shade100, // button color
                      child: InkWell(
                          splashColor: Colors.greenAccent, // inkwell color
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(Icons.arrow_forward_ios),
                          ),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MapDistance()))),
                    ),
                  ),
                ),
              ),
            ),

            //current location button
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                  child: ClipOval(
                    child: Material(
                      color: Colors.orange.shade100, // button color
                      child: InkWell(
                        splashColor: Colors.orange, // inkwell color
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.my_location),
                        ),
                        onTap: () {
                          mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(
                                  _currentPosition.latitude,
                                  _currentPosition.longitude,
                                ),
                                zoom: 18.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

//locats current location
  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        print('CURRENT POS: $_currentPosition');
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 14.0,
            ),
          ),
        );
      });
    }).catchError((e) {
      print(e);
    });
  }

  //markers to place on map
  Set<Marker> getmarkers() {
    setState(() {
      for (int i = 0; i < markerslocation.length; i++) {
        markers.add(Marker(
          onTap: () {},
          markerId: MarkerId(markerslocation[i]["id"].toString()),
          position: LatLng(
              double.parse(markerslocation[i]["lat"].toString()),
              double.parse(
                  markerslocation[i]["lon"].toString())), //position of marker
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
              //popup info
              title: "+ ADD",
              snippet: markerslocation[i]["snippet"].toString(),
              onTap: () {
                setState(() {
                  //add markers to list
                  addedMarkers.addAll(
                    {
                      "lat": markerslocation[i]["lat"],
                      "lon": markerslocation[i]["lon"],
                    },
                  );
                  joinStops.add(addedMarkers.values.join(","));
                  joinStopsNoLast.add(addedMarkers.values.join(","));
                });
              }), //Icon for Marker
        ));
      }
    });
    return markers;
  }

//direction from one marker to another
  Set<Polyline> getpolyline() {
    setState(() {
      for (int i = 0; i < markerslocation.length; i++) {
        latlng.add(
          LatLng(double.parse(markerslocation[i]["lat"].toString()),
              double.parse(markerslocation[i]["lon"].toString())),
        );
        polylines.add(Polyline(
          polylineId: PolylineId(markerslocation[i]["id"].toString()),
          color: Color.fromARGB(255, 54, 206, 244),
          points: latlng,
          width: 5,
        ));
      }
    });

    return polylines;
  }

  //method to launch maps
  Future<void> launchGoogleMaps() async {
    joinStopsNoLast.removeLast();
    String googleUrl =
        "google.navigation:q=${joinStops.last}&waypoints=${joinStopsNoLast.join("|")}&travelmode=driving&dir_action=navigate";
    launchUrlString(googleUrl);
  }
}
