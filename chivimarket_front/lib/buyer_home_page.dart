import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _fetchExploreProducts();
  }

  Future<void> _fetchExploreProducts() async {
    try {
      final res = await ApiService.get('/explore/products');
      if (res.statusCode == 200) {
        if (mounted) setState(() {
          _products = jsonDecode(res.body);
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
              // Buscador
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  borderRadius: 30,
                  child: TextField(
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Buscar locales, productos o servicios...',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ),
              
              // Contenido exploratorio / Vitrina
              Expanded(
                child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Icon(Icons.shopping_bag_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                           const SizedBox(height: 16),
                           Text('Explora y Compra', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                           const SizedBox(height: 8),
                           Text('Aún no hay productos públicos', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchExploreProducts,
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.68, // Ajuste para que entre la foto y los textos
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final prod = _products[index];
                          final isSponsored = prod['is_sponsored'] == true;
                          
                          return GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Viendo producto: ${prod['name']}')));
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
                                          child: Icon(Icons.image, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                        ),
                                      ),
                                      // Detalles
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prod['name'] ?? '',
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '\$${prod['price']}',
                                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).colorScheme.primary),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.storefront, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    prod['business']['name'] ?? 'Local',
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
}
