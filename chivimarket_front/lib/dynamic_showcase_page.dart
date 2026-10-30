import 'dart:async';
import 'dart:convert';
import 'dart:ui';
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

class _DynamicShowcasePageState extends State<DynamicShowcasePage> with SingleTickerProviderStateMixin {
  // Coordenadas de referencia inicial (Plaza 25 de Mayo, Chivilcoy)
  static const double defaultLat = -34.8986;
  static const double defaultLng = -60.0195;

  double? _userLat;
  double? _userLng;
  bool _isUsingGps = false;
  bool _liveTracking = false;
  StreamSubscription<Position>? _positionStreamSub;

  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.90);
  final ScrollController _listScrollController = ScrollController();

  // Opciones de visualización
  bool _isMapExpanded = true; // Mapa maximizado por defecto
  bool _isListViewMode = false; // Modo Radar (Mapa + Carrusel) vs Modo Lista Vertical
  String _mapStyle = 'streets-v12'; // Siempre claro y nítido por defecto
  int? _selectedBusinessId;
  int _activeCardIndex = 0;

  bool _isLoading = true;
  String _statusMessage = 'Sintonizando radar de comercios...';
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

  // Animación del pulso de radar
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.8, end: 2.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _initLocationAndFetch();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _pulseController.dispose();
    _pageController.dispose();
    _listScrollController.dispose();
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
        _useFallbackLocation('Ubicación GPS apagada. Mostrando desde Plaza 25 de Mayo.');
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
        _useFallbackLocation('Permiso de ubicación bloqueado en el navegador.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
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

  void _recenterMapOnUser({double zoom = 15.6}) {
    if (_userLat != null && _userLng != null) {
      try {
        _mapController.move(ltlng.LatLng(_userLat!, _userLng!), zoom);
      } catch (_) {}
    }
  }

  void _toggleLiveTracking(bool enabled) {
    if (enabled) {
      setState(() => _liveTracking = true);

      // Configuración sensible de 3 metros para detectar pasos y movimientos reales
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Actualiza cada 3 metros recorridos
      );

      _positionStreamSub?.cancel();
      _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen((pos) {
        if (mounted) {
          setState(() {
            _userLat = pos.latitude;
            _userLng = pos.longitude;
            _isUsingGps = true;
            _sortBusinessesByDistance();
          });
          _recenterMapOnUser(zoom: 16.0);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📡 Radar en vivo activado: el cursor y las vidrieras te siguen en tiempo real.'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      _positionStreamSub?.cancel();
      _positionStreamSub = null;
      setState(() => _liveTracking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pausaste el radar en tiempo real.'),
          duration: Duration(seconds: 2),
        ),
      );
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

        if (_businesses.isNotEmpty) {
          _selectedBusinessId = _businesses.first['id'];
        }
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

  void _focusBusinessOnMapAndDock(int bId) {
    final filtered = _filteredBusinesses;
    final index = filtered.indexWhere((item) => item['id'] == bId);
    if (index == -1) return;

    final b = filtered[index];
    final bLat = double.tryParse(b['latitude']?.toString() ?? '');
    final bLng = double.tryParse(b['longitude']?.toString() ?? '');

    setState(() {
      _selectedBusinessId = bId;
      _activeCardIndex = index;
    });

    if (bLat != null && bLng != null) {
      try {
        _mapController.move(ltlng.LatLng(bLat, bLng), 16.2);
      } catch (_) {}
    }

    // Si estamos en modo carrusel, animar la página
    if (!_isListViewMode && _pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_isListViewMode && _listScrollController.hasClients) {
      final targetOffset = (index * 280.0).clamp(0.0, _listScrollController.position.maxScrollExtent);
      _listScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatDistance(double? meters) {
    if (meters == null || meters > 9000000) return 'Distancia no fijada';
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
    final msg = Uri.encodeComponent('¡Hola! Vi la vidriera de "$storeName" en ChiviMarket y me gustaría consultarles.');
    final url = Uri.parse('https://wa.me/$fullPhone?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
                    _isUsingGps ? '📍 Ubicación GPS precisa' : '📍 Centro (Plaza 25 de Mayo)',
                    style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.65)),
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
          // Conmutador Modo Radar (Mapa) vs Modo Lista
          IconButton(
            icon: Icon(
              _isListViewMode ? Icons.map_outlined : Icons.view_agenda_outlined,
              color: onSurface,
            ),
            tooltip: _isListViewMode ? 'Ver mapa con radar' : 'Ver lista completa de vidrieras',
            onPressed: () {
              setState(() => _isListViewMode = !_isListViewMode);
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: onSurface),
            tooltip: 'Actualizar GPS y vidrieras',
            onPressed: _initLocationAndFetch,
          ),
        ],
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ==========================================
              // BARRA DE RADIOS DE BÚSQUEDA
              // ==========================================
              _buildRadiusSelector(isDark, onSurface, primary),

              // ==========================================
              // CUERPO PRINCIPAL: RADAR (MAPA + DOCK) O LISTA
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
                        ? _buildEmptyState(onSurface, primary)
                        : _isListViewMode
                            ? _buildFullListView(filtered, isDark, onSurface, primary)
                            : _buildRadarSplitView(filtered, isDark, onSurface, primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BARRA DE RADIOS DE BÚSQUEDA
  // =========================================================
  Widget _buildRadiusSelector(bool isDark, Color onSurface, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _radiusOptions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final opt = _radiusOptions[i];
            final isSelected = _selectedRadiusMeters == opt['value'];
            return ChoiceChip(
              label: Text(
                opt['label'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : onSurface.withOpacity(0.85),
                ),
              ),
              selected: isSelected,
              selectedColor: primary,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: isSelected ? 3 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isSelected ? primary : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: 1.2,
                ),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedRadiusMeters = opt['value'];
                  final f = _filteredBusinesses;
                  if (f.isNotEmpty) {
                    _selectedBusinessId = f.first['id'];
                    _activeCardIndex = 0;
                  }
                });

                // Si seleccionó "Todo Chivilcoy" o no hay comercios en su radio GPS actual, centrar el mapa en la Plaza 25 de Mayo
                if (opt['value'] == null) {
                  try {
                    _mapController.move(const ltlng.LatLng(defaultLat, defaultLng), 14.5);
                  } catch (_) {}
                }
              },
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // VISTA RADAR: MAPA PROTAGONISTA + CARRUSEL HORIZONTAL DOCK
  // =========================================================
  Widget _buildRadarSplitView(List<Map<String, dynamic>> filtered, bool isDark, Color onSurface, Color primary) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 750;

    return LayoutBuilder(
      builder: (context, constraints) {
        // En celular: el mapa toma aprox 48% normal, o 68% expandido para no asfixiar el dock inferior
        final double mapFlex = _isMapExpanded ? (isSmallScreen ? 0.65 : 0.70) : (isSmallScreen ? 0.46 : 0.50);
        final double dockFlex = 1.0 - mapFlex;

        return Column(
          children: [
            // ÁREA DEL MAPA
            Expanded(
              flex: (mapFlex * 100).toInt(),
              child: Stack(
                children: [
                  _buildInteractiveMap(isDark, onSurface, primary, filtered),

                  // BOTÓN FLOTANTE: TIEMPO REAL (LIVE TRACKING)
                  Positioned(
                    top: 10,
                    left: 12,
                    child: _buildLiveTrackingPill(primary, isDark),
                  ),

                  // BOTONES SUPERIORES DERECHOS: ESTILO DE MAPA Y EXPANDIR
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Column(
                      children: [
                        // Botón Re-centrar en el usuario
                        _buildMapActionButton(
                          icon: Icons.my_location,
                          tooltip: 'Centrar en mi ubicación',
                          color: const Color(0xFF0284C7), // Sky blue vivo
                          isDark: isDark,
                          onTap: () => _recenterMapOnUser(zoom: 16.0),
                        ),
                        const SizedBox(height: 10),

                        // Toggle Expandir / Achicar mapa
                        _buildMapActionButton(
                          icon: _isMapExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                          tooltip: _isMapExpanded ? 'Restaurar vidrieras' : 'Maximizar mapa',
                          color: primary,
                          isDark: isDark,
                          onTap: () => setState(() => _isMapExpanded = !_isMapExpanded),
                        ),
                        const SizedBox(height: 10),

                        // Toggle Estilo de Mapa
                        _buildMapActionButton(
                          icon: _mapStyle == 'streets-v12' ? Icons.wb_sunny : Icons.nightlight_round,
                          tooltip: _mapStyle == 'streets-v12' ? 'Cambiar a modo noche' : 'Cambiar a calles claras',
                          color: const Color(0xFFD97706), // Amber oscuro nítido
                          isDark: isDark,
                          onTap: () {
                            setState(() {
                              _mapStyle = _mapStyle == 'streets-v12' ? 'dark-v11' : 'streets-v12';
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // CONTADOR INFORMATIVO FLOTANTE
                  Positioned(
                    bottom: 8,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storefront_rounded, size: 14, color: Colors.orangeAccent),
                          const SizedBox(width: 5),
                          Text(
                            '${filtered.length} comercios en radar',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // DOCK INFERIOR: CARRUSEL HORIZONTAL DE VIDRIERAS
            Expanded(
              flex: (dockFlex * 100).toInt(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ScrollConfiguration(
                      behavior: const MaterialScrollBehavior().copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                          PointerDeviceKind.stylus,
                        },
                      ),
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        onPageChanged: (idx) {
                          setState(() {
                            _activeCardIndex = idx;
                            _selectedBusinessId = filtered[idx]['id'];
                          });
                          final b = filtered[idx];
                          final bLat = double.tryParse(b['latitude']?.toString() ?? '');
                          final bLng = double.tryParse(b['longitude']?.toString() ?? '');
                          if (bLat != null && bLng != null) {
                            try {
                              _mapController.move(ltlng.LatLng(bLat, bLng), 16.0);
                            } catch (_) {}
                          }
                        },
                        itemBuilder: (ctx, idx) {
                          final b = filtered[idx];
                          return _buildDockBusinessCard(b, isDark, onSurface, primary);
                        },
                      ),
                    ),
                  ),

                  // FLECHA NAVEGACIÓN ANTERIOR (PC, Tablets y Celulares)
                  Positioned(
                    left: 2,
                    child: Opacity(
                      opacity: _activeCardIndex > 0 ? 1.0 : 0.35,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 1.2),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.black87),
                          tooltip: 'Comercio anterior',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          onPressed: _activeCardIndex > 0
                              ? () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // FLECHA NAVEGACIÓN SIGUIENTE (PC, Tablets y Celulares)
                  Positioned(
                    right: 2,
                    child: Opacity(
                      opacity: _activeCardIndex < filtered.length - 1 ? 1.0 : 0.35,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 1.2),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black87),
                          tooltip: 'Siguiente comercio',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          onPressed: _activeCardIndex < filtered.length - 1
                              ? () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // MAPA INTERACTIVO CON PINES PULSANTES Y MAPBOX VIBRANTE
  // =========================================================
  Widget _buildInteractiveMap(bool isDark, Color onSurface, Color primary, List<Map<String, dynamic>> filtered) {
    final lat = _userLat ?? defaultLat;
    final lng = _userLng ?? defaultLng;
    final token = AppConfig.mapboxToken;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: ltlng.LatLng(lat, lng),
        initialZoom: 15.6,
      ),
      children: [
        // CAPA MAPBOX (Siempre clara por defecto con calles nítidas)
        TileLayer(
          urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/$_mapStyle/tiles/{z}/{x}/{y}?access_token=$token',
        ),

        // CÍRCULO DEL RADIO DE CERCANÍA
        if (_selectedRadiusMeters != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: ltlng.LatLng(lat, lng),
                radius: _selectedRadiusMeters!.toDouble(),
                useRadiusInMeter: true,
                color: Colors.teal.withOpacity(0.09),
                borderColor: Colors.teal.withOpacity(0.55),
                borderStrokeWidth: 2.0,
              ),
            ],
          ),

        // MARCADORES: USUARIO + PINES DE COMERCIOS
        MarkerLayer(
          markers: [
            // Marcador de ubicación del usuario con halo pulsante en tiempo real
            Marker(
              point: ltlng.LatLng(lat, lng),
              width: 50,
              height: 50,
              alignment: Alignment.center,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_liveTracking)
                        Container(
                          width: 24 * _pulseAnimation.value,
                          height: 24 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.teal.withOpacity((1.0 - (_pulseAnimation.value - 0.8) / 1.4).clamp(0.0, 0.45)),
                          ),
                        ),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _liveTracking ? Colors.teal : Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        child: const Icon(Icons.my_location, color: Colors.white, size: 14),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Pines de los comercios encontrados en el radar
            ...filtered.map((b) {
              final bLat = double.tryParse(b['latitude']?.toString() ?? '');
              final bLng = double.tryParse(b['longitude']?.toString() ?? '');
              if (bLat == null || bLng == null) return null;

              final isSelected = b['id'] == _selectedBusinessId;
              final String name = b['name'] ?? 'Local';

              return Marker(
                point: ltlng.LatLng(bLat, bLng),
                width: isSelected ? 120 : 90,
                height: isSelected ? 58 : 46,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () => _focusBusinessOnMapAndDock(b['id']),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge con nombre legible
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isSelected ? 8 : 6, vertical: isSelected ? 3 : 2),
                        decoration: BoxDecoration(
                          color: isSelected ? primary : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.white : primary,
                            width: isSelected ? 1.8 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? primary.withOpacity(0.4) : Colors.black26,
                              blurRadius: isSelected ? 6 : 3,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSelected ? 10.5 : 9.5,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      // Pin Icon
                      Icon(
                        Icons.location_on,
                        color: isSelected ? primary : const Color(0xFFF97316),
                        size: isSelected ? 32 : 24,
                      ),
                    ],
                  ),
                ),
              );
            }).whereType<Marker>().toList(),
          ],
        ),
      ],
    );
  }

  // =========================================================
  // BOTÓN LIVE TRACKING FLOTANTE
  // =========================================================
  Widget _buildLiveTrackingPill(Color primary, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Fondo blanco sólido para que resalte perfecto en el mapa
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _liveTracking ? const Color(0xFF0D9488) : Colors.black12,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => _toggleLiveTracking(!_liveTracking),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _liveTracking ? const Color(0xFF10B981) : Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _liveTracking ? 'Radar en Vivo: ACTIVO' : 'Activar Radar en Vivo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _liveTracking ? const Color(0xFF0D9488) : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Botón de acción redondito en el mapa
  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white, // Siempre fondo blanco sólido brillante para máximo contraste sobre el mapa
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(icon, color: color, size: 24),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // TARJETA DEL DOCK HORIZONTAL (COMPACTA Y COMPLETA)
  // =========================================================
  Widget _buildDockBusinessCard(Map<String, dynamic> b, bool isDark, Color onSurface, Color primary) {
    final double? distMeters = b['_distance_meters'];
    final bool isSelected = b['id'] == _selectedBusinessId;
    final List products = (b['products'] is List) ? b['products'] : [];
    final lat = double.tryParse(b['latitude']?.toString() ?? '');
    final lng = double.tryParse(b['longitude']?.toString() ?? '');

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isSelected ? primary : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.2),
        boxShadow: [
          BoxShadow(
            color: isSelected ? primary.withOpacity(0.25) : Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: isSelected ? 10 : 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FILA SUPERIOR: LOGO + NOMBRE + DISTANCIA + ACCIÓN
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isSelected ? primary : primary.withOpacity(0.15),
                child: Icon(Icons.storefront, color: isSelected ? Colors.white : primary, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      b['name'] ?? 'Comercio',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatDistance(distMeters),
                            style: const TextStyle(
                              color: Color(0xFF0D9488),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (b['address'] != null && b['address'].toString().trim().isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              b['address'],
                              style: TextStyle(fontSize: 10, color: onSurface.withOpacity(0.6)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.open_in_new, size: 18),
                color: primary,
                tooltip: 'Ver perfil completo',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicBusinessPage(business: b))),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // PRODUCTOS DESTACADOS HORIZONTALES
          Expanded(
            child: products.isNotEmpty
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, pIdx) {
                      final p = products[pIdx];
                      p['business'] = b;
                      return _buildCompactProductThumb(p, isDark, onSurface, primary);
                    },
                  )
                : Center(
                    child: Text(
                      'Este local atiende presencialmente. Tocá arriba para ver su ficha completa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.6)),
                    ),
                  ),
          ),

          const SizedBox(height: 6),

          // BOTONES DE ACCIÓN: CÓMO LLEGAR + WHATSAPP
          Row(
            children: [
              if (lat != null && lng != null)
                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: isDark ? Colors.lightBlueAccent.withOpacity(0.5) : const Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _openMaps(lat, lng),
                      icon: const Icon(Icons.directions, size: 13),
                      label: const Text('Cómo Llegar', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              if (b['phone'] != null && b['phone'].toString().trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _contactWhatsapp(b['phone']?.toString(), b['name'] ?? 'Local'),
                      icon: const Icon(Icons.chat, size: 13),
                      label: const Text('WhatsApp', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Miniatura de producto para el dock
  Widget _buildCompactProductThumb(dynamic p, bool isDark, Color onSurface, Color primary) {
    String? imgUrl;
    if (p['images'] != null && p['images'] is List && p['images'].isNotEmpty) {
      imgUrl = p['images'][0]['url'] ?? p['images'][0]['full_url'];
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)));
      },
      child: Container(
        width: 86,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: imgUrl != null && imgUrl.isNotEmpty
                  ? Image.network(
                      imgUrl.startsWith('http') ? imgUrl : 'https://chivimarket.arumasoft.com/$imgUrl',
                      fit: BoxFit.cover,
                      cacheWidth: 180,
                      errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 18, color: onSurface.withOpacity(0.3)),
                    )
                  : Icon(Icons.shopping_bag_outlined, size: 22, color: primary.withOpacity(0.5)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.5, color: onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${p['price'] ?? 0}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5, color: primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // VISTA ALTERNATIVA: MODO LISTA COMPLETA VERTICAL
  // =========================================================
  Widget _buildFullListView(List<Map<String, dynamic>> filtered, bool isDark, Color onSurface, Color primary) {
    return ListView.builder(
      controller: _listScrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final b = filtered[i];
        return _buildFullShowcaseCard(b, isDark, onSurface, primary);
      },
    );
  }

  Widget _buildFullShowcaseCard(Map<String, dynamic> b, bool isDark, Color onSurface, Color primary) {
    final double? distMeters = b['_distance_meters'];
    final List products = (b['products'] is List) ? b['products'] : [];
    final lat = double.tryParse(b['latitude']?.toString() ?? '');
    final lng = double.tryParse(b['longitude']?.toString() ?? '');

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: primary.withOpacity(0.15),
                child: Icon(Icons.storefront, color: primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['name'] ?? 'Comercio',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDistance(distMeters),
                      style: const TextStyle(color: Color(0xFF0D9488), fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                color: onSurface.withOpacity(0.4),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicBusinessPage(business: b))),
              ),
            ],
          ),
          if (products.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, pIdx) {
                  final p = products[pIdx];
                  p['business'] = b;
                  return _buildCompactProductThumb(p, isDark, onSurface, primary);
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (lat != null && lng != null)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(color: isDark ? Colors.lightBlueAccent.withOpacity(0.5) : const Color(0xFF2563EB)),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                    ),
                    onPressed: () => _contactWhatsapp(b['phone']?.toString(), b['name'] ?? 'Local'),
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ESTADO VACÍO
  // =========================================================
  Widget _buildEmptyState(Color onSurface, Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory_outlined, size: 70, color: onSurface.withOpacity(0.25)),
            const SizedBox(height: 16),
            Text(
              'No hay comercios dentro de este radio',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba ampliando el radio a 1 km, 3 km o "Todo Chivilcoy" en la barra superior.',
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurface.withOpacity(0.65), fontSize: 13),
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
            ),
          ],
        ),
      ),
    );
  }
}
