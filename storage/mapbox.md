// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/widgets/index.dart'; // Importa otros Custom Widgets (opcional)
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ltlng;
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapaDireccionesWidget extends StatefulWidget {
  final double width;
  final double height;

  const MapaDireccionesWidget({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  State<MapaDireccionesWidget> createState() => _MapaDireccionesWidgetState();
}

class _MapaDireccionesWidgetState extends State<MapaDireccionesWidget> {
  final MapController _mapController = MapController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _direccionSeleccionadaController =
      TextEditingController();
  final TextEditingController _latitudController = TextEditingController();
  final TextEditingController _longitudController = TextEditingController();
  String _tokenMapbox = 'TU_TOKEN_MAPBOX_ELIMINADO_POR_SEGURIDAD';
  String _resultadoBusqueda = 'Ingresá una dirección para buscar en Chivilcoy.';
  ltlng.LatLng? _ubicacionEncontrada;
  List<Map<String, dynamic>> _resultadosBusqueda = [];
  Map<String, dynamic>? _resultadoSeleccionado;
  bool _mostrarResultados = false;

  Future<void> _buscarDireccion(String query) async {
    final String queryConChivilcoy = "$query, Chivilcoy";
    final String bbox = "-60.15447189,-34.99613545,-59.82348962,-34.80632355";

    final String url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$queryConChivilcoy.json'
        '?bbox=$bbox'
        '&proximity=-60.0167,-34.8997'
        '&country=AR'
        '&fuzzyMatch=true'
        '&autocomplete=true'
        '&access_token=$_tokenMapbox'
        '&language=es';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['features'] != null && data['features'].isNotEmpty) {
        final List<dynamic> features = data['features'];
        final List<Map<String, dynamic>> resultados = features.map((feature) {
          return {
            'description': feature['place_name'] as String,
            'lat': feature['geometry']['coordinates'][1] as double,
            'lng': feature['geometry']['coordinates'][0] as double,
          };
        }).toList();

        setState(() {
          _resultadosBusqueda = resultados;
          _resultadoBusqueda =
              'Se encontraron ${_resultadosBusqueda.length} resultados en Chivilcoy.';
          _mostrarResultados = true;
        });
      } else {
        setState(() {
          _resultadoBusqueda =
              'No se encontraron resultados en Chivilcoy para "$query".';
          _resultadosBusqueda = [];
          _mostrarResultados = false;
        });
      }
    } catch (e) {
      setState(() {
        _resultadoBusqueda = 'Error al buscar la dirección: $e';
        _resultadosBusqueda = [];
        _mostrarResultados = false;
      });
    }
  }

  void _moverMapa(double deltaX, double deltaY) {
    final currentCenter = _mapController.camera.center;
    final newCenter = ltlng.LatLng(
      currentCenter.latitude + deltaY * 0.002,
      currentCenter.longitude + deltaX * 0.002,
    );
    _mapController.move(newCenter, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TextField y botón para buscar direcciones
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Ej: Lavalle 194, Chivilcoy',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide:
                          BorderSide(color: Color(0xFF1481B1), width: 1.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide:
                          BorderSide(color: Color(0xFF1481B1), width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide:
                          BorderSide(color: Color(0xFF1481B1), width: 2.0),
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.0,
                    color: Color(0xFF262D34),
                  ),
                  onSubmitted: (value) => _buscarDireccion(value),
                ),
              ),
              IconButton(
                icon: Icon(Icons.search, color: Color(0xFF1481B1)),
                onPressed: () => _buscarDireccion(_textController.text),
              ),
            ],
          ),
        ),
        // Stack para superponer el ListView de resultados sobre el mapa
        Stack(
          children: [
            // Mapa
            SizedBox(
              width: widget.width,
              height: widget.height,
              child: IgnorePointer(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: ltlng.LatLng(-34.8997, -60.0167),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=$_tokenMapbox',
                      additionalOptions: {
                        'accessToken': _tokenMapbox,
                        'id': 'mapbox/streets-v11',
                      },
                    ),
                    if (_ubicacionEncontrada != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _ubicacionEncontrada!,
                            child: Icon(
                              Icons.location_on,
                              color: Color(0xFF1481B1),
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // Lista de resultados de búsqueda superpuesta
            if (_mostrarResultados && _resultadosBusqueda.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  margin: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    itemCount: _resultadosBusqueda.length,
                    itemBuilder: (context, index) {
                      final resultado = _resultadosBusqueda[index];
                      return ListTile(
                        title: Text(
                          resultado['description'],
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.0,
                            color: Color(0xFF262D34),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _resultadoSeleccionado = resultado;
                            _ubicacionEncontrada = ltlng.LatLng(
                              resultado['lat'],
                              resultado['lng'],
                            );
                            _direccionSeleccionadaController.text =
                                resultado['description'];
                            _latitudController.text =
                                resultado['lat'].toString();
                            _longitudController.text =
                                resultado['lng'].toString();
                            _mostrarResultados = false;
                          });
                          _mapController.move(
                            ltlng.LatLng(resultado['lat'], resultado['lng']),
                            _mapController.camera.zoom,
                          );
                          // Establecer la variable de aplicación direccionEncontrada
                          FFAppState().update(() {
                            FFAppState().direccionEncontrada =
                                resultado['description'];
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            // Controles de desplazamiento y zoom
            Positioned(
              right: 8.0,
              top: 0,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón de zoom +
                  FloatingActionButton.small(
                    heroTag: 'zoomIn',
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      );
                    },
                    child: Icon(Icons.add, color: Color(0xFF1481B1)),
                  ),
                  SizedBox(height: 8.0),
                  // Botón de zoom -
                  FloatingActionButton.small(
                    heroTag: 'zoomOut',
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      );
                    },
                    child: Icon(Icons.remove, color: Color(0xFF1481B1)),
                  ),
                  SizedBox(height: 8.0),
                  // Botón para mover arriba
                  FloatingActionButton.small(
                    heroTag: 'moveUp',
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _moverMapa(0, 1);
                    },
                    child: Icon(Icons.arrow_upward, color: Color(0xFF1481B1)),
                  ),
                  SizedBox(height: 8.0),
                  // Botón para mover abajo
                  FloatingActionButton.small(
                    heroTag: 'moveDown',
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _moverMapa(0, -1);
                    },
                    child: Icon(Icons.arrow_downward, color: Color(0xFF1481B1)),
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botón para mover izquierda
                      FloatingActionButton.small(
                        heroTag: 'moveLeft',
                        backgroundColor: Colors.white,
                        onPressed: () {
                          _moverMapa(-1, 0);
                        },
                        child: Icon(Icons.arrow_back, color: Color(0xFF1481B1)),
                      ),
                      SizedBox(width: 8.0),
                      // Botón para mover derecha
                      FloatingActionButton.small(
                        heroTag: 'moveRight',
                        backgroundColor: Colors.white,
                        onPressed: () {
                          _moverMapa(1, 0);
                        },
                        child:
                            Icon(Icons.arrow_forward, color: Color(0xFF1481B1)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  // Botón para centrar el mapa en Chivilcoy
                  FloatingActionButton.small(
                    heroTag: 'centerMap',
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _mapController.move(
                        ltlng.LatLng(-34.8997, -60.0167),
                        13.0,
                      );
                    },
                    child: Icon(Icons.my_location, color: Color(0xFF1481B1)),
                  ),
                ],
              ),
            ),
          ],
        ),
        // TextField de solo lectura para mostrar la dirección seleccionada
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _direccionSeleccionadaController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Dirección',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Color(0xFF1481B1), width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Color(0xFF1481B1), width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Color(0xFF1481B1), width: 2.0),
              ),
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.0,
              color: Color(0xFF262D34),
            ),
          ),
        ),
        // Campos de solo lectura para latitud y longitud
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: TextField(
                    controller: _latitudController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Latitud',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide:
                            BorderSide(color: Color(0xFF1481B1), width: 1.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide:
                            BorderSide(color: Color(0xFF1481B1), width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide:
                            BorderSide(color: Color(0xFF1481B1), width: 2.0),
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.0,
                      color: Color(0xFF262D34),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: TextField(
                    controller: _longitudController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Longitud',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide:
                            BorderSide(color: Color(0xFF1481B1), width: 1.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide:
                            BorderSide(color: Color(0xFF1481B1), width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide:
                            BorderSide(color: Color(0xFF1481B1), width: 2.0),
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.0,
                      color: Color(0xFF262D34),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
