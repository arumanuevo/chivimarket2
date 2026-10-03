import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ltlng;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';
import 'main.dart'; // GlassContainer & Animations
import 'product_detail_page.dart';

class PublicBusinessPage extends StatefulWidget {
  final Map<String, dynamic> business;

  const PublicBusinessPage({Key? key, required this.business}) : super(key: key);

  @override
  State<PublicBusinessPage> createState() => _PublicBusinessPageState();
}

class _PublicBusinessPageState extends State<PublicBusinessPage> {
  bool _isLoading = true;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final res = await ApiService.get('/products/business/${widget.business['id']}');
      if (res.statusCode == 200) {
        if (mounted) setState(() {
          _products = jsonDecode(res.body)['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildMap() {
    final lat = double.tryParse(widget.business['latitude'].toString());
    final lng = double.tryParse(widget.business['longitude'].toString());
    if (lat == null || lng == null) return const SizedBox();

    final String token = dotenv.env['MAPBOX_TOKEN'] ?? '';
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(16)
        ),
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: ltlng.LatLng(lat, lng),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}?access_token=$token',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: ltlng.LatLng(lat, lng),
                    width: 40, height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on, color: Colors.orangeAccent, size: 40),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.business['name'] ?? 'Tienda', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black87.withOpacity(0.6),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: AnimatedGradientBackground(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(radius: 30, backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2), child: const Icon(Icons.storefront, size: 36, color: Colors.orangeAccent)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.business['name'] ?? '', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text('${(widget.business['modality'] ?? 'Físico').toString().toUpperCase()} - ⭐ ${widget.business['avg_rating'] ?? '5.0'}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(widget.business['description'] ?? 'Este vendedor es un misterio.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                        const SizedBox(height: 16),
                        _buildMap(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              sliver: SliverToBoxAdapter(
                child: Text('Catálogo de Productos', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_products.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text('El vendedor aún no ha publicado artículos.', style: TextStyle(color: Colors.white54, fontSize: 16)),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = _products[index];
                      // Aseguramos que el producto lleva la info completa de la tienda en el mapa
                      p['business'] = widget.business; 
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: p))),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(8),
                          borderRadius: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                                  child: const Center(child: Icon(Icons.image, color: Colors.white30, size: 48)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('\$${p['price']}', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _products.length,
                  ),
                ),
              ),
            
            const SliverPadding(padding: EdgeInsets.only(bottom: 24))
          ],
        ),
      ),
    );
  }
}
