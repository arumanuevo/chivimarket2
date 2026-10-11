import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ltlng;
import 'app_config.dart';
import 'my_vouchers_page.dart';
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
  bool _showHeroBanner = true;
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
          : _searchMode == 'businesses' 
              ? '/businesses/search?name=$query'
              : '/promotions/all';

      if (_sortBy != 'default' && _searchMode != 'promotions') {
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
          if (!_isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.login, size: 16),
                label: const Text('Ingresar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => Navigator.pushNamed(context, '/login').then((_) => _checkLogin()),
              ),
            ),
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
          child: RefreshIndicator(
            onRefresh: () => _performSearch(_searchController.text),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeroBanner(),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SearchBarDelegate(
                    child: _buildSearchBarAndFilters(),
                    height: 92.0,
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else if (_showMap && _searchMode == 'businesses')
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: _buildMapView(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 240,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.70,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildItemCard(_items[index]),
                        childCount: _items.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBarAndFilters() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Buscador y Selector de Modo
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 2.0),
          child: Row(
            children: [
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  borderRadius: 30,
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      hintText: _searchMode == 'products' ? 'Buscar productos...' : 'Buscar tiendas...',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 20),
                    ),
                    onSubmitted: (val) => _performSearch(val),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Dropdown para cambiar modo de búsqueda
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _searchMode,
                    dropdownColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
                    icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary, size: 18),
                    items: [
                      DropdownMenuItem(value: 'products', child: Text('Productos', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13))),
                      DropdownMenuItem(value: 'businesses', child: Text('Tiendas', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13))),
                      DropdownMenuItem(value: 'promotions', child: Text('Promo / Vouchers', style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _searchMode = val;
                          _sortBy = 'default';
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
              Text('Ordenar por:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 11)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortBy,
                dropdownColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                underline: const SizedBox(),
                isDense: true,
                items: [
                  const DropdownMenuItem(value: 'default', child: Text('Relevancia')),
                  const DropdownMenuItem(value: 'views_count', child: Text('🔥 Más Populares (Vistas)')),
                  if (_searchMode == 'products') const DropdownMenuItem(value: 'price', child: Text('💸 Precio')),
                  if (_searchMode == 'businesses') const DropdownMenuItem(value: 'avg_rating', child: Text('⭐ Mejor Calificados')),
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
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
    );
  }

  Widget _buildItemCard(dynamic item) {
    final isBusiness = _searchMode == 'businesses';
    final isPromo = _searchMode == 'promotions';
    final isSponsored = !isBusiness && !isPromo && (item['is_sponsored'] == true);
    
    final title = isPromo ? (item['title'] ?? 'Voucher') : (item['name'] ?? '');
    final subtitle = isPromo 
        ? (item['business'] != null ? item['business']['name'] : 'Beneficio Exclusivo')
        : isBusiness 
            ? (item['address'] ?? 'Tienda') 
            : (item['business'] != null ? (item['business']['name'] ?? 'Local') : 'Local');
    
    final priceOrRating = isPromo
        ? '🏆 Lvl. ${item['required_level'] ?? 1}'
        : isBusiness 
            ? '⭐ ${item['avg_rating'] ?? 'Nuevo'}' 
            : '\$${item['price']}';

    final viewsStr = isPromo ? '🎁 ${item['max_uses_per_user'] ?? 1}x/u' : '👀 ${item['views_count'] ?? 0}';
    
    return GestureDetector(
      onTap: () {
        if (isPromo) {
          if (item['business'] != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PublicBusinessPage(business: item['business'])));
          }
          return;
        }
        
        final currentId = item['id'];
        if (isBusiness) {
          ApiService.get('/businesses/$currentId');
        } else {
          ApiService.get('/products/$currentId');
        }

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
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Icon(isBusiness ? Icons.store : Icons.image, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                  ),
                ),
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
            if (isSponsored)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]
                  ),
                  child: const Text('Promocionado', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(
                  (isBusiness || isPromo ? _favoriteBusinessIds.contains(isPromo ? item['business_id'] : item['id']) : _favoriteProductIds.contains(item['id']))
                    ? Icons.favorite
                    : Icons.favorite_border,
                  color: Colors.redAccent,
                ),
                onPressed: () {
                  if (!_isLoggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('¡Debes iniciar sesión para agregar a favoritos!'),
                        backgroundColor: Colors.orange,
                        action: SnackBarAction(
                          label: 'Ingresar',
                          textColor: Colors.white,
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                        ),
                      ),
                    );
                    return;
                  }
                  if (isPromo) {
                    if (item['business'] != null) {
                      _toggleFavorite(true, item['business']);
                    }
                  } else {
                    _toggleFavorite(isBusiness, item);
                  }
                },
              ),
            ),
          ],
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
              leading: Icon(Icons.login, color: Theme.of(context).colorScheme.primary),
              title: Text('Ingresar a mi Cuenta', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login').then((_) => _checkLogin());
              },
            ),
            ListTile(
              leading: const Icon(Icons.storefront, color: Colors.orangeAccent),
              title: const Text('¡Publicá tu Negocio Gratis!', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
              subtitle: Text('Llegá a toda la comunidad de Chivilcoy', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55), fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showPublishPromoDialog();
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
              leading: const Icon(Icons.wallet_giftcard, color: Colors.greenAccent),
              title: const Text('Billetera de Beneficios', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVouchersPage()));
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
    final String mapboxToken = AppConfig.mapboxToken;
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

  Widget _buildHeroBanner() {
    if (!_showHeroBanner || _searchController.text.trim().isNotEmpty) {
      return const SizedBox.shrink();
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: GlassContainer(
        borderRadius: 22,
        padding: EdgeInsets.all(isMobile ? 16 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar del Banner: Badge local + Cerrar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF97316).withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.location_on, color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Chivilcoy Conectado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                  ),
                  child: const Text(
                    '100% Local',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => setState(() => _showHeroBanner = false),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 15,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Título Impactante
            Text(
              '¡Comprá, descubrí y vendé en tu ciudad!',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 21 : 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),

            // Subtítulo
            Text(
              'Encontrá locales cercanos, productos con stock real y cupones de descuento exclusivos. ¿Tenés un comercio o servicio? Sumate hoy mismo gratis.',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 13 : 14.5,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 16),

            // Accesos directos / Filtros rápidos
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildHeroActionChip(
                  icon: Icons.storefront,
                  label: 'Ver Tiendas & Mapa',
                  color: Colors.blueAccent,
                  isSelected: _searchMode == 'businesses',
                  onTap: () {
                    setState(() {
                      _searchMode = 'businesses';
                      _searchController.clear();
                    });
                    _performSearch('');
                  },
                ),
                _buildHeroActionChip(
                  icon: Icons.local_offer,
                  label: 'Cupones & Vouchers',
                  color: Colors.pinkAccent,
                  isSelected: _searchMode == 'promotions',
                  onTap: () {
                    setState(() {
                      _searchMode = 'promotions';
                      _searchController.clear();
                    });
                    _performSearch('');
                  },
                ),
                _buildHeroCtaChip(
                  icon: Icons.rocket_launch,
                  label: _isLoggedIn ? 'Mi Panel de Negocios' : '¡Publicá tu Negocio Gratis!',
                  onTap: () {
                    if (_isLoggedIn) {
                      Navigator.pushNamed(context, '/dashboard');
                    } else {
                      _showPublishPromoDialog();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.25) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCtaChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF97316).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPublishPromoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rocket_launch, color: Colors.orangeAccent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Impulsá tu Negocio',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publicá tus servicios o local comercial en ChiviMarket y llegá a toda la comunidad de Chivilcoy.',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            _buildDialogFeature(Icons.pin_drop, 'Tu tienda visible en el mapa satelital de la ciudad.'),
            _buildDialogFeature(Icons.inventory_2, 'Catálogo digital con fotos, stock y precios.'),
            _buildDialogFeature(Icons.confirmation_number, 'Creá cupones de descuento y promociones.'),
            _buildDialogFeature(Icons.check_circle, 'Comenzá 100% GRATIS sin comisiones iniciales.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/login').then((_) => _checkLogin());
            },
            child: const Text('Ya tengo cuenta'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/register').then((_) => _checkLogin());
            },
            child: const Text('Crear mi Cuenta Gratis', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SearchBarDelegate({required this.child, this.height = 92.0});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPinned = shrinkOffset > 0 || overlapsContent;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: isPinned ? 16.0 : 0.0, sigmaY: isPinned ? 16.0 : 0.0),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: isPinned
                ? (isDark ? const Color(0xE61E293B) : const Color(0xE6F1F5F9))
                : Colors.transparent,
            border: isPinned
                ? Border(bottom: BorderSide(color: (isDark ? Colors.white12 : Colors.black12), width: 1))
                : null,
            boxShadow: isPinned
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
