import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ltlng;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';
import 'main.dart'; // Animations and global things

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({Key? key}) : super(key: key);

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  List<dynamic> _items = []; // Can be products or businesses
  String _searchMode = 'products'; // 'products' or 'businesses'
  bool _showMap = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _fetchExploreProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchExploreProducts() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/explore/products');
      if (res.statusCode == 200) {
        if (mounted) setState(() {
          _items = jsonDecode(res.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTopBusinesses() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/businesses/top-rated');
      if (res.statusCode == 200) {
        if (mounted) setState(() {
          // Backend returns paginated data for businesses/top-rated
          final data = jsonDecode(res.body);
          _items = data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      if (_searchMode == 'products') {
        _fetchExploreProducts();
      } else {
        _fetchTopBusinesses();
      }
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      String endpoint = _searchMode == 'products' 
          ? '/products/search?query=$query' 
          : '/businesses/search?name=$query';
          
      final res = await ApiService.get(endpoint);
      if (res.statusCode == 200) {
        if (mounted) setState(() {
          _items = jsonDecode(res.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkLogin() async {
    final token = await ApiService.getToken();
    setState(() {
      _isLoggedIn = token != null;
    });
  }

  void _logout() async {
    await ApiService.removeToken();
    setState(() {
      _isLoggedIn = false;
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesión cerrada correctamente')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat, // Desplazado a la izquierda para evitar el ReCAPTCHA
      floatingActionButton: _searchMode == 'businesses' ? FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(_showMap ? Icons.grid_view : Icons.map),
        label: Text(_showMap ? 'Ver Cuadrícula' : 'Ver Mapa', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        onPressed: () => setState(() => _showMap = !_showMap),
      ) : null,
      appBar: AppBar(
        title: Text('ChiviMarket', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24, color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          IconButton(
            icon: Icon(themeNotifier.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode, color: Colors.orangeAccent),
            tooltip: 'Cambiar Tema',
            onPressed: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carrito en construcción')));
            },
          )
        ],
      ),
      drawer: _buildBuyerDrawer(),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Buscador y Filtro
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        borderRadius: 30,
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: _searchMode == 'products' ? 'Buscar productos...' : 'Buscar tiendas...',
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            border: InputBorder.none,
                            icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                          ),
                          onSubmitted: (val) => _performSearch(val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dropdown para cambiar modo de búsqueda
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      borderRadius: 30,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _searchMode,
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
                          items: [
                            DropdownMenuItem(value: 'products', child: Text('Productos', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                            DropdownMenuItem(value: 'businesses', child: Text('Tiendas', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _searchMode = val;
                                _searchController.clear();
                                if (val != 'businesses') _showMap = false;
                              });
                              _performSearch('');
                            }
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
              
              // Contenido exploratorio / Vitrina
              Expanded(
                child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Icon(Icons.search_off, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                           const SizedBox(height: 16),
                           Text('Sin resultados', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                           const SizedBox(height: 8),
                           Text('Intenta con otra búsqueda', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                        ],
                      ),
                     )
                   : _showMap && _searchMode == 'businesses'
                       ? _buildMapView()
                       : RefreshIndicator(
                           onRefresh: () => _performSearch(_searchController.text),
                           child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240, // Más grandes, estilo MercadoLibre
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.70, // Espacio suficiente para foto cuadrada y texto
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final isBusiness = _searchMode == 'businesses';
                          final isSponsored = !isBusiness && (item['is_sponsored'] == true);
                          final title = item['name'] ?? '';
                          final subtitle = isBusiness 
                              ? (item['address'] ?? 'Tienda') 
                              : (item['business'] != null ? (item['business']['name'] ?? 'Local') : 'Local');
                          final priceOrRating = isBusiness 
                              ? '⭐ ${item['avg_rating'] ?? 'Nuevo'}' 
                              : '\$${item['price']}';
                          
                          return GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Viendo: $title')));
                            },
                            child: GlassContainer(
                              padding: EdgeInsets.zero,
                              borderRadius: 16,
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Imagen Placeholder
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surface,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          ),
                                          child: Icon(isBusiness ? Icons.store : Icons.image, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                        ),
                                      ),
                                      // Detalles
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              priceOrRating,
                                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).colorScheme.primary),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(isBusiness ? Icons.location_on : Icons.storefront, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    subtitle,
                                                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  // Etiqueta de Promocionado
                                  if (isSponsored)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amberAccent,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]
                                        ),
                                        child: const Text('Promocionado', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuyerDrawer() {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]), // Azulito para comprador (contraste visual con naranja del vendedor)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.person, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text('Mi Cuenta', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(_isLoggedIn ? 'Comprador Registrado' : 'Invitado', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
          
          ListTile(
            leading: Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
            title: Text('Explorar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () => Navigator.pop(context),
          ),
          
          if (!_isLoggedIn) ...[
            ListTile(
              leading: Icon(Icons.login, color: Theme.of(context).colorScheme.onSurface),
              title: Text('Ingresar / Registrarse', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login').then((_) => _checkLogin());
              },
            ),
          ],

          if (_isLoggedIn) ...[
            ListTile(
              leading: Icon(Icons.favorite, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              title: Text('Mis Favoritos', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              title: Text('Mis Compras', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
              onTap: () {},
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.storefront, color: Colors.orangeAccent),
              title: const Text('¡Vender mis servicios!', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
              subtitle: Text('Ir a mi panel de negocios', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/dashboard');
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapView() {
    final String mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? '';
    final mapItems = _items.where((b) => b['latitude'] != null && b['longitude'] != null).toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: const ltlng.LatLng(-34.8953, -60.0172),
        initialZoom: 13.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}?access_token=$mapboxToken',
        ),
        MarkerLayer(
          markers: mapItems.map((b) {
            final lat = double.tryParse(b['latitude'].toString()) ?? -34.8953;
            final lng = double.tryParse(b['longitude'].toString()) ?? -60.0172;
            return Marker(
              point: ltlng.LatLng(lat, lng),
              width: 140, // Espacio ancho para el nombre
              height: 80, // Aumentado ligeramente para dar aire al badge
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Viendo tienda: ${b['name']}')));
                },
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      constraints: BoxConstraints(maxWidth: 130), // Límite estricto de largo
                      decoration: BoxDecoration(
                        color: Colors.black87, // Fondo oscuro permanente alto contraste
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orangeAccent, width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Text(
                        b['name'] ?? 'Local', 
                        maxLines: 1, // Obliga a una sola línea
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), 
                        overflow: TextOverflow.ellipsis, // Corta con (...) si es muy largo
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Icon(Icons.location_on, color: Colors.orangeAccent, size: 34),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
