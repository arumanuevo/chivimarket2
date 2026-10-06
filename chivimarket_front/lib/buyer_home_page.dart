import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ltlng;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';
import 'main.dart'; // Animations and global things
import 'product_detail_page.dart';
import 'public_business_page.dart';
import 'favorites_page.dart';

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
  String _sortBy = 'default'; // 'default', 'views_count', 'price', 'avg_rating'
  bool _showMap = false;
  final TextEditingController _searchController = TextEditingController();
  
  List<int> _favoriteProductIds = [];
  List<int> _favoriteBusinessIds = [];

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    
    try {
      String endpoint = _searchMode == 'products' 
          ? '/products/search?query=$query' 
          : '/businesses/search?name=$query';

      if (_sortBy != 'default') {
        String orderParam = (_sortBy == 'views_count' || _sortBy == 'avg_rating') ? 'desc' : 'asc';
        endpoint += '&sort_by=$_sortBy&order=$orderParam';
      }
          
      final res = await ApiService.get(endpoint);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() {
          _items = data is List ? data : (data['data'] ?? []);
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
    if (_isLoggedIn) {
      _fetchFavorites();
    }
  }

  Future<void> _fetchFavorites() async {
    try {
      final res = await ApiService.get('/favorites');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() {
          _favoriteBusinessIds = (data['businesses'] as List).map((b) => b['id'] as int).toList();
          _favoriteProductIds = (data['products'] as List).map((p) => p['id'] as int).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(bool isBusiness, dynamic item) async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Debes iniciar sesión con una cuenta para guardar favoritos!'), backgroundColor: Colors.orange));
      return;
    }
    
    final id = item['id'] as int;
    final endpoint = isBusiness ? '/favorites/businesses/$id' : '/favorites/products/$id';
    
    // UI Optimistic update
    setState(() {
      if (isBusiness) {
        if (_favoriteBusinessIds.contains(id)) _favoriteBusinessIds.remove(id);
        else _favoriteBusinessIds.add(id);
      } else {
        if (_favoriteProductIds.contains(id)) _favoriteProductIds.remove(id);
        else _favoriteProductIds.add(id);
      }
    });

    try {
      final res = await ApiService.post(endpoint, {});
      if (res.statusCode != 200) {
        // Revert on failure
        _fetchFavorites();
      }
    } catch (_) {
      _fetchFavorites();
    }
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _searchMode,
                          dropdownColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
                          icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
                          items: [
                            DropdownMenuItem(value: 'products', child: Text('Productos', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                            DropdownMenuItem(value: 'businesses', child: Text('Tiendas', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _searchMode = val;
                                _sortBy = 'default'; // Reset sort upon changing mode to avoid invalid dropdown values
                                _searchController.clear();
                                if (val != 'businesses') _showMap = false;
                              });
                              _performSearch('');
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Botones de filtro de ordenamiento (Sort By)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text('Ordenar por:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sortBy,
                      dropdownColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(value: 'default', child: Text('Relevancia')),
                        DropdownMenuItem(value: 'views_count', child: Text('🔥 Más Populares (Vistas)')),
                        if (_searchMode == 'products') DropdownMenuItem(value: 'price', child: Text('💸 Precio')),
                        if (_searchMode == 'businesses') DropdownMenuItem(value: 'avg_rating', child: Text('⭐ Mejor Calificados')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _sortBy = val);
                          _performSearch(_searchController.text);
                        }
                      },
                    ),
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

                          final viewsStr = '👀 ${item['views_count'] ?? 0}';
                          
                          return GestureDetector(
                            onTap: () {
                              final currentId = item['id'];
                              // Hacemos el llamado a la API solo para disparar el incremento de vistas por background
                              if (isBusiness) {
                                ApiService.get('/businesses/$currentId');
                              } else {
                                ApiService.get('/products/$currentId');
                              }

                              // Optimistic UI increment
                              setState(() {
                                item['views_count'] = (item['views_count'] ?? 0) + 1;
                              });
                              if (isBusiness) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PublicBusinessPage(business: item)));
                              } else {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: item)));
                              }
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
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  priceOrRating,
                                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).colorScheme.primary),
                                                ),
                                                Text(
                                                  viewsStr,
                                                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                                )
                                              ],
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
                                  // Botón de Favoritos
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: IconButton(
                                      icon: Icon(
                                        (isBusiness ? _favoriteBusinessIds.contains(item['id']) : _favoriteProductIds.contains(item['id']))
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () => _toggleFavorite(isBusiness, item),
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
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage())).then((_) => _fetchFavorites());
              },
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
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PublicBusinessPage(business: b)));
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
