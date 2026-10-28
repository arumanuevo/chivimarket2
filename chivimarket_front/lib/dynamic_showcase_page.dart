import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ltlng;
import 'package:url_launcher/url_launcher.dart';
import 'app_config.dart';
import 'api_service.dart';
import 'main.dart'; // AnimatedGradientBackground, GlassContainer
import 'product_detail_page.dart';
import 'public_business_page.dart';

class DynamicShowcasePage extends StatefulWidget {
  const DynamicShowcasePage({Key? key}) : super(key: key);

  @override
  State<DynamicShowcasePage> createState() => _DynamicShowcasePageState();
}

class _DynamicShowcasePageState extends State<DynamicShowcasePage> {
  // Coordenadas de referencia inicial (Plaza 25 de Mayo, Chivilcoy)
  static const double defaultLat = -34.8986;
  static const double defaultLng = -60.0195;

  double? _userLat;
  double? _userLng;
  bool _isUsingGps = false;
  bool _liveTracking = false;
  StreamSubscription<Position>? _positionStreamSub;

  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();
  
  bool _showMap = true; // Mapa poco invasivo visible por defecto (colapsable con un toque)
  int? _selectedBusinessId; // Comercio tocado en el mapa para destacar su vidriera

  bool _isLoading = true;
  String _statusMessage = 'Calculando comercios y vidrieras...';
  List<Map<String, dynamic>> _businesses = [];
  
  // Radio de filtrado en metros: null = sin límite (ordena por distancia)
  int? _selectedRadiusMeters = 500; // Por defecto 500m (Paseo de cercanía)
  final List<Map<String, dynamic>> _radiusOptions = [
    {'label': '🚶 A pie (150m)', 'value': 150},
    {'label': '🚶‍♂️ Manzana (500m)', 'value': 500},
    {'label': '🚲 Barrio (1 km)', 'value': 1000},
    {'label': '🚗 Ciudad (3 km)', 'value': 3000},
    {'label': '🌐 Todo Chivilcoy', 'value': null},
  ];

  @override
  void initState() {
    super.initState();
    _initLocationAndFetch();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndFetch() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Obteniendo tu ubicación GPS...';
    });

    await _detectUserLocation();
    await _fetchShowcaseBusinesses();
  }

  Future<void> _detectUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useFallbackLocation('Ubicación GPS apagada. Mostrando desde Centro (Plaza 25 de Mayo).');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallbackLocation('Permiso no concedido. Usando centro de Chivilcoy.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallbackLocation('Permiso de ubicación bloqueado. Usando centro de Chivilcoy.');
        return;
      }

      // Obtener posición actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 7),
      );

      if (mounted) {
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
          _isUsingGps = true;
        });
        _recenterMapOnUser();
      }
    } catch (_) {
      _useFallbackLocation('No se pudo fijar GPS. Usando centro de Chivilcoy.');
    }
  }

  void _useFallbackLocation(String reason) {
    if (mounted) {
      setState(() {
        _userLat = defaultLat;
        _userLng = defaultLng;
        _isUsingGps = false;
      });
      _recenterMapOnUser();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reason),
          backgroundColor: Colors.orange[800],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _recenterMapOnUser() {
    if (_userLat != null && _userLng != null) {
      try {
        _mapController.move(ltlng.LatLng(_userLat!, _userLng!), 15.5);
      } catch (_) {}
    }
  }

  void _toggleLiveTracking(bool enabled) {
    if (enabled) {
      setState(() => _liveTracking = true);
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15, // Actualiza solo cada 15 metros para cuidar batería
      );
      _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen((pos) {
        if (mounted) {
          setState(() {
            _userLat = pos.latitude;
            _userLng = pos.longitude;
            _isUsingGps = true;
            _sortBusinessesByDistance();
          });
          _recenterMapOnUser();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📡 Radar en vivo activado: mapa y vidrieras se reordenan a tu paso.'),
          backgroundColor: Colors.teal,
        ),
      );
    } else {
      _positionStreamSub?.cancel();
      _positionStreamSub = null;
      setState(() => _liveTracking = false);
    }
  }

  Future<void> _fetchShowcaseBusinesses() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Cargando vidrieras y comercios...';
    });

    try {
      final res = await ApiService.get('/businesses/search?with_products=1');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['data'] ?? []);
        _businesses = List<Map<String, dynamic>>.from(list);
        _sortBusinessesByDistance();
      }
    } catch (_) {
      // Ignorar o mantener lista
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sortBusinessesByDistance() {
    if (_userLat == null || _userLng == null) return;

    for (var b in _businesses) {
      final bLat = double.tryParse(b['latitude']?.toString() ?? '');
      final bLng = double.tryParse(b['longitude']?.toString() ?? '');
      if (bLat != null && bLng != null) {
        final distMeters = Geolocator.distanceBetween(_userLat!, _userLng!, bLat, bLng);
        b['_distance_meters'] = distMeters;
      } else {
        b['_distance_meters'] = 9999999.0;
      }
    }

    _businesses.sort((a, b) {
      final double da = a['_distance_meters'] ?? 9999999.0;
      final double db = b['_distance_meters'] ?? 9999999.0;
      return da.compareTo(db);
    });
  }

  List<Map<String, dynamic>> get _filteredBusinesses {
    if (_selectedRadiusMeters == null) {
      return _businesses;
    }
    return _businesses.where((b) {
      final double? dist = b['_distance_meters'];
      if (dist == null || dist > 9000000) return false;
      return dist <= _selectedRadiusMeters!;
    }).toList();
  }

  void _scrollToBusiness(dynamic bId) {
    final filtered = _filteredBusinesses;
    final index = filtered.indexWhere((item) => item['id'] == bId);
    if (index != -1 && _scrollController.hasClients) {
      // Desplazamiento animado suave a la tarjeta seleccionada
      final targetOffset = (index * 270.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatDistance(double? meters) {
    if (meters == null || meters > 9000000) return 'Distancia desconocida';
    if (meters < 50) {
      return '🔥 ¡Frente a vos! (${meters.round()} m)';
    } else if (meters < 1000) {
      return '🚶 A ${meters.round()} metros';
    } else {
      return '🚗 A ${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _contactWhatsapp(String? phone, String storeName) async {
    final cleanPhone = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este comercio no especificó WhatsApp.')),
      );
      return;
    }
    String fullPhone = cleanPhone;
    if (!fullPhone.startsWith('54')) fullPhone = '549$fullPhone';
    final msg = Uri.encodeComponent('Hola! Vi la vidriera de "$storeName" en ChiviMarket y me gustaría consultarles.');
    final url = Uri.parse('https://wa.me/$fullPhone?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildMiniMap(bool isDark, Color onSurface, Color primary, List<Map<String, dynamic>> filtered) {
    final lat = _userLat ?? defaultLat;
    final lng = _userLng ?? defaultLng;
    final mapStyle = isDark ? 'dark-v11' : 'streets-v12';
    final token = AppConfig.mapboxToken;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: ltlng.LatLng(lat, lng),
              initialZoom: 15.2,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/$mapStyle/tiles/{z}/{x}/{y}?access_token=$token',
              ),
              // Círculo translúcido del radio de alcance del radar
              if (_selectedRadiusMeters != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: ltlng.LatLng(lat, lng),
                      radius: _selectedRadiusMeters!.toDouble(),
                      useRadiusInMeter: true,
                      color: Colors.teal.withOpacity(0.12),
                      borderColor: Colors.teal.withOpacity(0.45),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Marcador de posición del usuario (pulsante)
                  Marker(
                    point: ltlng.LatLng(lat, lng),
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: const Icon(Icons.my_location, color: Colors.white, size: 16),
                    ),
                  ),
                  // Marcadores interactivos de los comercios
                  ...filtered.map((b) {
                    final bLat = double.tryParse(b['latitude']?.toString() ?? '');
                    final bLng = double.tryParse(b['longitude']?.toString() ?? '');
                    if (bLat == null || bLng == null) return null;
                    final isSelected = b['id'] == _selectedBusinessId;

                    return Marker(
                      point: ltlng.LatLng(bLat, bLng),
                      width: 100,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedBusinessId = b['id']);
                          try {
                            _mapController.move(ltlng.LatLng(bLat, bLng), 16.0);
                          } catch (_) {}
                          _scrollToBusiness(b['id']);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? primary : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected ? Colors.white : primary,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                              ),
                              child: Text(
                                b['name'] ?? 'Local',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.location_on, 
                              color: isSelected ? primary : Colors.orangeAccent, 
                              size: isSelected ? 26 : 22,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).whereType<Marker>().toList(),
                ],
              ),
            ],
          ),

          // Badge indicador flotante arriba
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0F172A) : Colors.white).withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, size: 12, color: Colors.teal),
                  const SizedBox(width: 4),
                  Text(
                    'Toca un pin para ver su vidriera',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: onSurface),
                  ),
                ],
              ),
            ),
          ),

          // Botón flotante para re-centrar en el usuario
          Positioned(
            bottom: 8,
            right: 8,
            child: InkWell(
              onTap: _recenterMapOnUser,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1E293B) : Colors.white).withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Icon(Icons.my_location, size: 18, color: Colors.blueAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final filtered = _filteredBusinesses;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radar, color: Colors.teal, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Radar de Vidrieras', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: onSurface)),
                  Text(
                    _isUsingGps ? '📍 Tu ubicación GPS' : '📍 Centro (Plaza 25 de Mayo)',
                    style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xF20F172A) : const Color(0xF8FFFFFF),
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _liveTracking ? Icons.sensors : Icons.sensors_off_outlined,
              color: _liveTracking ? Colors.tealAccent[700] ?? Colors.teal : onSurface.withOpacity(0.5),
            ),
            tooltip: _liveTracking ? 'Rastreo en vivo activo' : 'Activar radar en vivo',
            onPressed: () => _toggleLiveTracking(!_liveTracking),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: onSurface),
            tooltip: 'Actualizar ubicación',
            onPressed: _initLocationAndFetch,
          ),
        ],
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ==========================================
              // BARRA DE RADIOS + BOTÓN COLAPSO DE MAPA
              // ==========================================
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  children: [
                    // Botón conmutador del mapa (Poco invasivo / Colapsable)
                    InkWell(
                      onTap: () => setState(() => _showMap = !_showMap),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: _showMap ? primary.withOpacity(0.15) : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _showMap ? primary : (isDark ? Colors.white12 : Colors.black12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_showMap ? Icons.map : Icons.map_outlined, size: 15, color: _showMap ? primary : onSurface.withOpacity(0.7)),
                            const SizedBox(width: 5),
                            Text(
                              _showMap ? 'Ocultar Mapa' : 'Ver Mapa (${filtered.length})',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: _showMap ? primary : onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Selector horizontal de radios de alcance
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _radiusOptions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (ctx, i) {
                            final opt = _radiusOptions[i];
                            final isSelected = _selectedRadiusMeters == opt['value'];
                            return ChoiceChip(
                              label: Text(opt['label'], style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.white : onSurface.withOpacity(0.85),
                              )),
                              selected: isSelected,
                              selectedColor: primary,
                              backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: isSelected ? primary : (isDark ? Colors.white12 : Colors.black12)),
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedRadiusMeters = opt['value'];
                                  _selectedBusinessId = null;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // MAPITA DINÁMICO COMPACTO (POCO INVASIVO)
              // ==========================================
              if (_showMap)
                _buildMiniMap(isDark, onSurface, primary, filtered),

              // ==========================================
              // ESTADO DE RADAR / LIVE TRACKING BANNER
              // ==========================================
              if (_liveTracking)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Radar en vivo activo: mapa y vidrieras se actualizan al avanzar.',
                          style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              // ==========================================
              // LISTA DE VIDRIERAS
              // ==========================================
              Expanded(
                child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(_statusMessage, style: TextStyle(color: onSurface.withOpacity(0.7))),
                        ],
                      ),
                    )
                  : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_mall_directory_outlined, size: 70, color: onSurface.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text(
                                'No hay comercios dentro de este radio',
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Prueba ampliando el radio a 1 km, 3 km o "Todo Chivilcoy" en la barra superior.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () => setState(() => _selectedRadiusMeters = null),
                                icon: const Icon(Icons.radar),
                                label: const Text('Ver todos los comercios'),
                              )
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final b = filtered[i];
                          return _buildShowcaseCard(b, isDark, onSurface, primary);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShowcaseCard(Map<String, dynamic> b, bool isDark, Color onSurface, Color primary) {
    final double? distMeters = b['_distance_meters'];
    final bool isVeryClose = distMeters != null && distMeters < 80;
    final bool isSelectedFromMap = b['id'] == _selectedBusinessId;
    final List products = (b['products'] is List) ? b['products'] : [];

    final lat = double.tryParse(b['latitude']?.toString() ?? '');
    final lng = double.tryParse(b['longitude']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.85) : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelectedFromMap 
            ? primary
            : (isVeryClose 
                ? (isDark ? Colors.greenAccent : const Color(0xFF16A34A))
                : (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06))),
          width: (isSelectedFromMap || isVeryClose) ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelectedFromMap
              ? primary.withOpacity(0.3)
              : (isVeryClose 
                  ? (isDark ? Colors.greenAccent.withOpacity(0.2) : const Color(0xFF16A34A).withOpacity(0.15))
                  : Colors.black.withOpacity(isDark ? 0.25 : 0.05)),
            blurRadius: (isSelectedFromMap || isVeryClose) ? 12 : 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CABECERA DEL COMERCIO
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicBusinessPage(business: b))),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isSelectedFromMap ? primary : primary.withOpacity(0.15),
                    child: Icon(Icons.storefront, color: isSelectedFromMap ? Colors.white : primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                b['name'] ?? 'Comercio',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelectedFromMap)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '📍 EN MAPA',
                                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isVeryClose 
                                    ? (isDark ? Colors.greenAccent : const Color(0xFF15803D)) 
                                    : (isDark ? Colors.tealAccent : const Color(0xFF0F766E))).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formatDistance(distMeters),
                                style: TextStyle(
                                  color: isVeryClose 
                                      ? (isDark ? Colors.greenAccent : const Color(0xFF15803D)) 
                                      : (isDark ? Colors.tealAccent : const Color(0xFF0F766E)),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (b['address'] != null && b['address'].toString().trim().isNotEmpty)
                              Expanded(
                                child: Text(
                                  b['address'],
                                  style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.6)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: onSurface.withOpacity(0.35)),
                ],
              ),
            ),
          ),

          // ==========================================
          // LA VIDRIERA: CARRUSEL DE PRODUCTOS AL PASO
          // ==========================================
          if (products.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '👀 Vidriera destacada (${products.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    'Deslizá para espiar ➔',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 155,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, pIdx) {
                  final p = products[pIdx];
                  p['business'] = b; // Asociar negocio
                  return _buildProductShowcaseItem(p, isDark, onSurface, primary);
                },
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 18, color: onSurface.withOpacity(0.4)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este local atiende presencialmente. Tocá para ver su ficha y catálogo completo.',
                      style: TextStyle(fontSize: 11.5, color: onSurface.withOpacity(0.65)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // PIE DE ACCIONES RÁPIDAS (MAPA + WHATSAPP)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey[100],
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
            ),
            child: Row(
              children: [
                if (lat != null && lng != null)
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        foregroundColor: isDark ? Colors.lightBlueAccent : const Color(0xFF2563EB),
                      ),
                      onPressed: () => _openMaps(lat, lng),
                      icon: const Icon(Icons.directions, size: 16),
                      label: const Text('Cómo Llegar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (b['phone'] != null && b['phone'].toString().trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _contactWhatsapp(b['phone']?.toString(), b['name'] ?? 'Local'),
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('Consultar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductShowcaseItem(dynamic p, bool isDark, Color onSurface, Color primary) {
    String? imgUrl;
    if (p['images'] != null && p['images'] is List && p['images'].isNotEmpty) {
      imgUrl = p['images'][0]['url'] ?? p['images'][0]['full_url'];
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)));
      },
      child: Container(
        width: 115,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: isDark ? Colors.black26 : Colors.grey[100],
                child: imgUrl != null && imgUrl.isNotEmpty
                  ? Image.network(
                      imgUrl.startsWith('http') ? imgUrl : 'https://chivimarket.arumasoft.com/$imgUrl',
                      fit: BoxFit.cover,
                      cacheWidth: 240,
                      errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 24, color: onSurface.withOpacity(0.3)),
                    )
                  : Icon(Icons.shopping_bag_outlined, size: 30, color: primary.withOpacity(0.4)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${p['price'] ?? 0}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
