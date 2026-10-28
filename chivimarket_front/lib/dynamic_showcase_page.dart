import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ltlng;
import 'package:url_launcher/url_launcher.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reason),
          backgroundColor: Colors.orange[800],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _toggleLiveTracking(bool enabled) {
    if (enabled) {
      setState(() => _liveTracking = true);
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15, // Actualiza solo cada 15 metros para no liquidar batería
      );
      _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen((pos) {
        if (mounted) {
          setState(() {
            _userLat = pos.latitude;
            _userLng = pos.longitude;
            _isUsingGps = true;
            _sortBusinessesByDistance();
          });
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📡 Radar en vivo activado: las vidrieras se reordenarán a tu paso.'),
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
    } catch (e) {
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
              // BARRA DE CONTROL DE RADIO DE ALCANCE
              // ==========================================
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _radiusOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final opt = _radiusOptions[i];
                      final isSelected = _selectedRadiusMeters == opt['value'];
                      return ChoiceChip(
                        label: Text(opt['label'], style: TextStyle(
                          fontSize: 12,
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
                          setState(() => _selectedRadiusMeters = opt['value']);
                        },
                      );
                    },
                  ),
                ),
              ),

              // ==========================================
              // ESTADO DE RADAR / LIVE TRACKING BANNER
              // ==========================================
              if (_liveTracking)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          'Radar en vivo activo: las vidrieras se ordenan a medida que avanzas.',
                          style: TextStyle(fontSize: 11.5, color: Colors.teal, fontWeight: FontWeight.bold),
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
    final List products = (b['products'] is List) ? b['products'] : [];

    final lat = double.tryParse(b['latitude']?.toString() ?? '');
    final lng = double.tryParse(b['longitude']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.85) : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVeryClose 
            ? (isDark ? Colors.greenAccent : const Color(0xFF16A34A))
            : (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06)),
          width: isVeryClose ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isVeryClose 
              ? (isDark ? Colors.greenAccent.withOpacity(0.2) : const Color(0xFF16A34A).withOpacity(0.15))
              : Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: isVeryClose ? 12 : 8,
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
                    backgroundColor: primary.withOpacity(0.15),
                    child: Icon(Icons.storefront, color: primary, size: 24),
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
