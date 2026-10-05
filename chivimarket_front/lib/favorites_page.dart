import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'main.dart'; // Animations and global things
import 'public_business_page.dart';
import 'product_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _isLoading = true;
  List<dynamic> _favoriteBusinesses = [];
  List<dynamic> _favoriteProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/favorites');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _favoriteBusinesses = data['businesses'] ?? [];
            _favoriteProducts = data['products'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('Mis Favoritos', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
          bottom: TabBar(
            labelColor: Colors.redAccent,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            indicatorColor: Colors.redAccent,
            tabs: const [
              Tab(icon: Icon(Icons.storefront), text: 'Tiendas Guardadas'),
              Tab(icon: Icon(Icons.shopping_bag), text: 'Productos Guardados'),
            ],
          ),
        ),
        body: AnimatedGradientBackground(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildList(_favoriteBusinesses, true),
                  _buildList(_favoriteProducts, false),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, bool isBusiness) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('No hay favoritos aquí.', style: GoogleFonts.outfit(fontSize: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 130, bottom: 24, left: 16, right: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60, height: 60,
                color: Colors.black26,
                child: const Icon(Icons.image, color: Colors.white54),
              ),
            ),
            title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(isBusiness ? (item['address'] ?? 'Tienda') : '\$${item['price']}', style: TextStyle(color: isBusiness ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
            onTap: () {
              if (isBusiness) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PublicBusinessPage(business: item)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: item)));
              }
            },
          ),
        );
      },
    );
  }
}
