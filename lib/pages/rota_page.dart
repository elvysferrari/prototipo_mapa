import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:prototipo_mapa/controllers/controllers.dart';
import '../constants/app_constant.dart';
import '../models/carregamento_model.dart';

class RotaPage extends StatefulWidget {
  const RotaPage({Key? key}) : super(key: key);

  @override
  State<RotaPage> createState() => _RotaPageState();
}

class _RotaPageState extends State<RotaPage> {
  final CameraPosition _initialLocation = const CameraPosition(target: LatLng(0.0, 0.0));
  late GoogleMapController mapController;

  final carregamentoController = TextEditingController();
  final carregamentoFocusNode = FocusNode();

  String _carregamento = '';
  String? _placeDistance;
  String _currentAddress = '';

  Set<Marker> markers = {};
  late PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  late Position _currentPosition;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late BitmapDescriptor iconeDusnei;

  @override
  void initState() {
    super.initState();
    _getPermissionLocation();
    carregamentoController.text = "19891";
    _carregamento = "19891";

    BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(16, 16)), 'assets/icons/dusnei_icon.png')
        .then((onValue) {
      iconeDusnei = onValue;
    });
  }

  _getPermissionLocation() async {
    if(await Permission.location.serviceStatus.isEnabled){
      var status = await Permission.location.status;
      if(status.isDenied){
        Map<Permission, PermissionStatus> permStatus = await [Permission.location,].request();
        await _getCurrentLocation();
      }
      else{
        await _getCurrentLocation();
      }
    }
  }

  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        if (kDebugMode) {
          print('CURRENT POS: $_currentPosition');
        }

        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
            ),
          ),
        );
      });
      await _getAddress();
    }).catchError((e) {
      if (kDebugMode) {
        print(e);
      }
    });
  }

  _getAddress() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
        "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  // Method for calculating the distance between two places
  Future<bool> _calculateDistance(String _startAddress, String _destinationAddress) async {

    List<CarregamentoModel> carregamentos = await entregasController.obterCarregamento(_carregamento);

    if (carregamentos.isEmpty) return false;

    double startLatitude = 0.0;
    double startLongitude = 0.0;

    double endLatitude = 0.0;
    double endLongitude = 0.0;

    List<PolylineWayPoint> wayPoints = [];

    //startLatitude = _currentPosition.latitude;
    //startLongitude = _currentPosition.longitude;

    startLatitude = -23.3552691;
    startLongitude = -51.8996794;

    String enderecoCoordinatesString = '($startLatitude, $startLongitude)';

    var endereco = 'Rua Pioneiro João Rufato, 257 Parque Industrial 200, Maringá - PR, 87035-540';

    PolylineWayPoint wayPoint = PolylineWayPoint(location: "$endereco");
    wayPoints.add(wayPoint);

    Marker startMarker = Marker(
      markerId: MarkerId(enderecoCoordinatesString),
      position: LatLng(startLatitude, startLongitude),
      infoWindow: InfoWindow(
        title: 'DUSNEI DISTRIBUIDORA',
        snippet: endereco,
      ),
      icon: iconeDusnei
    );

    // Adding the markers to the list
    markers.add(startMarker);

    try {
      for (var carregamento in carregamentos) {
        var endereco = "${carregamento.endereco}, ${carregamento.cidade} - ${carregamento.uf}";

        List<Location> _enderecoPlacemark = await locationFromAddress(endereco);

        carregamento.latitude = _enderecoPlacemark[0].latitude;
        carregamento.longitude = _enderecoPlacemark[0].longitude;

        String enderecoCoordinatesString = '(${carregamento.latitude}, ${carregamento.longitude})';

        PolylineWayPoint wayPoint = PolylineWayPoint(location: "$endereco");
        wayPoints.add(wayPoint);

        Marker startMarker = Marker(
          markerId: MarkerId(enderecoCoordinatesString),
          position: LatLng(carregamento.latitude, carregamento.longitude),
          infoWindow: InfoWindow(
            title: '${carregamento.nomeFantasia}',
            snippet: endereco,
          ),
          icon: BitmapDescriptor.defaultMarker,
        );

        // Adding the markers to the list
        markers.add(startMarker);
      }

      //aqui temos que fazer uma função pra calcular a distancia dos carregamentos com o carregamento inicial
      for (var carregamento in carregamentos) {
        carregamento.distancia = _coordinateDistance(startLatitude, startLongitude, carregamento.latitude, carregamento.longitude);
      }

      CarregamentoModel maiorDistancia = carregamentos.reduce((a, b) {
        if (a.distancia > b.distancia) {
          return a;
        } else {
          return b;
        }
      });

      endLatitude = maiorDistancia.latitude;
      endLongitude = maiorDistancia.longitude;
      
      // Calculating to check that the position relative
      // to the frame, and pan & zoom the camera accordingly.
      double miny = (startLatitude <= endLatitude)
          ? startLatitude
          : endLatitude;
      double minx = (startLongitude <= endLongitude)
          ? startLongitude
          : endLongitude;
      double maxy = (startLatitude <= endLatitude)
          ? endLatitude
          : startLatitude;
      double maxx = (startLongitude <= endLongitude)
          ? endLongitude
          : startLongitude;

      double southWestLatitude = miny;
      double southWestLongitude = minx;

      double northEastLatitude = maxy;
      double northEastLongitude = maxx;

      // Accommodate the two locations within the
      // camera view of the map
      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: LatLng(northEastLatitude, northEastLongitude),
            southwest: LatLng(southWestLatitude, southWestLongitude),
          ),
          100.0,
        ),
      );

      await _createPolylines(startLatitude, startLongitude, endLatitude, endLongitude, wayPoints);

      double totalDistance = 0.0;

      // Calculating the total distance by adding the distance
      // between small segments
      for (int i = 0; i < polylineCoordinates.length - 1; i++) {
        totalDistance += _coordinateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude,
        );
      }

      setState(() {
        _placeDistance = totalDistance.toStringAsFixed(2);
      });

      return true;
    } catch (e) {

      if (kDebugMode) {
        print(e);
      }
    }
    return false;
  }

  // Formula for calculating distance between two coordinates
  // https://stackoverflow.com/a/54138876/11910277
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Create the polylines for showing the route between two places
  _createPolylines(
      double startLatitude,
      double startLongitude,
      double destinationLatitude,
      double destinationLongitude,
      List<PolylineWayPoint> wayPoints
      ) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      AppConstant.API_KEY, // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.driving,
      wayPoints: wayPoints
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    PolylineId id = const PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
  }


  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required double width,
    required Icon prefixIcon,
    Widget? suffixIcon,
    required Function(String) locationCallback,
  }) {
    return Container(
      width: width * 0.8,
      child: TextField(
        onChanged: (value) {
          locationCallback(value);
        },
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Container(
      height: height,
      width: width,
      child: Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            // Map View
            GoogleMap(
              markers: Set<Marker>.from(markers),
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              polylines: Set<Polyline>.of(polylines.values),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
            // Show zoom buttons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ClipOval(
                      child: Material(
                        color: Colors.blue.shade100, // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: const SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.add),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipOval(
                      child: Material(
                        color: Colors.blue.shade100, // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: const SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.remove),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            // Show the place input fields & button for
            // showing the route
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                    ),
                    width: width * 0.9,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const SizedBox(height: 10),
                          _textField(
                              label: 'Número do carregamento',
                              hint: 'Número!',
                              prefixIcon: const Icon(Icons.looks_one),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.my_location),
                                onPressed: () {
                                  _getCurrentLocation();
                                  carregamentoController.text = _currentAddress;
                                  _carregamento = _currentAddress;
                                },
                              ),
                              controller: carregamentoController,
                              focusNode: carregamentoFocusNode,
                              width: width,
                              locationCallback: (String value) {
                                setState(() {
                                  _carregamento = value;
                                });
                              }),
                          const SizedBox(height: 10),
                          Visibility(
                            visible: _placeDistance == null ? false : true,
                            child: Text(
                              'Distância: $_placeDistance km',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          ElevatedButton(
                            onPressed: (_carregamento != '') ? () async {
                              carregamentoFocusNode.unfocus();
                              setState(() {
                                if (markers.isNotEmpty) markers.clear();
                                if (polylines.isNotEmpty) polylines.clear();
                                if (polylineCoordinates.isNotEmpty) polylineCoordinates.clear();
                                _placeDistance = null;
                              });

                              _calculateDistance("pato-agro-pato-branco", "policia-rodoviaria-federal-pato-branco").then((isCalculated) {
                                if (isCalculated) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Distância calculada com sucesso!'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Erro ao calcular distância!'),
                                    ),
                                  );
                                }
                              });
                            }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Pesquisar'.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.brown,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Show current location button
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
                        child: const SizedBox(
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


}
