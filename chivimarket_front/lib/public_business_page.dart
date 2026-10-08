import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ltlng;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'main.dart'; // GlassContainer & Animations
import 'product_detail_page.dart';
import 'reviews_widget.dart';
import 'promotions_list_widget.dart';

class PublicBusinessPage extends StatefulWidget {
  final Map<String, dynamic> business;
  final Map<String, dynamic>? highlightedProduct;

  const PublicBusinessPage({Key? key, required this.business, this.highlightedProduct}) : super(key: key);

  @override
  State<PublicBusinessPage> createState() => _PublicBusinessPageState();
}

class _PublicBusinessPageState extends State<PublicBusinessPage> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _fetchProducts();
  }

  Future<void> _checkLogin() async {
    final t = await ApiService.getToken();
    if (mounted) setState(() => _isLoggedIn = t != null);
  }

  Future<void> _fetchProducts() async {
    try {
      final res = await ApiService.get('/products/business/${widget.business['id']}');
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            final decoded = jsonDecode(res.body);
            _products = decoded is List ? decoded : (decoded['data'] ?? []);
            _isLoading = false;
          });
        }
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
        child: Stack(
          children: [
            IgnorePointer(
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
            // Capa interactiva de navegación
            Positioned(
              bottom: 8,
              right: 8,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  foregroundColor: Colors.blueAccent[700],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                  final Uri url = Uri.parse(googleMapsUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir Google Maps')));
                  }
                },
                icon: const Icon(Icons.directions, size: 20),
                label: const Text('Cómo LLegar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
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
                        Builder(
                          builder: (context) {
                            final phone = widget.business['phone']?.toString() ?? '';
                            final email = widget.business['email']?.toString() ?? '';
                            
                            Map<String, dynamic> meta = {};
                            if (widget.business['metadata'] is Map) {
                              meta = Map<String, dynamic>.from(widget.business['metadata']);
                            } else if (widget.business['metadata'] is String) {
                              try { meta = jsonDecode(widget.business['metadata']); } catch(_) {}
                            }

                            final hours = meta['hours']?.toString() ?? '';
                            final instagram = meta['instagram']?.toString() ?? '';
                            final facebook = meta['facebook']?.toString() ?? '';

                            if (phone.isNotEmpty || hours.isNotEmpty || instagram.isNotEmpty || facebook.isNotEmpty || email.isNotEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (hours.isNotEmpty)
                                      Row(children: [const Icon(Icons.access_time, color: Colors.orangeAccent, size: 16), const SizedBox(width: 8), Expanded(child: Text(hours, style: const TextStyle(color: Colors.white70)))]),
                                    if (phone.isNotEmpty)
                                      Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [const Icon(Icons.phone, color: Colors.greenAccent, size: 16), const SizedBox(width: 8), Text(phone, style: const TextStyle(color: Colors.white70))])),
                                    if (email.isNotEmpty)
                                      Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [const Icon(Icons.email, color: Colors.blueAccent, size: 16), const SizedBox(width: 8), Text(email, style: const TextStyle(color: Colors.white70))])),
                                    if (facebook.isNotEmpty)
                                      Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [const Icon(Icons.facebook, color: Colors.blue, size: 16), const SizedBox(width: 8), Text(facebook, style: const TextStyle(color: Colors.white70))])),
                                    if (instagram.isNotEmpty)
                                      Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [const Icon(Icons.camera_alt, color: Colors.pinkAccent, size: 16), const SizedBox(width: 8), Text(instagram, style: const TextStyle(color: Colors.white70))])),
                                  ],
                                )
                              );
                            }
                            return const SizedBox.shrink();
                          }
                        ),

                        _buildMap(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (widget.highlightedProduct != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      border: Border.all(color: Theme.of(context).colorScheme.primary),
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag, color: Colors.orangeAccent, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vienes a comprar:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
                              Text(widget.highlightedProduct!['name'] ?? '', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ]
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(8)),
                          child: Text('\$${widget.highlightedProduct!['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                      ],
                    )
                  ),
                ),
              ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              sliver: SliverToBoxAdapter(
                child: Text('Catálogo de Productos', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: PromotionsListWidget(
                  businessId: widget.business['id'] as int,
                  isLoggedIn: _isLoggedIn,
                ),
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
                      p['business'] = widget.business; 
                      
                      String? imageUrl;
                      if (p['images'] != null && p['images'].isNotEmpty) {
                        imageUrl = p['images'][0]['full_url'] ?? p['images'][0]['url'];
                        if (imageUrl != null && !imageUrl.startsWith('http')) {
                          imageUrl = 'https://chivimarket.arumasoft.com/$imageUrl';
                        }
                      }

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
                                  width: double.infinity,
                                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: imageUrl != null 
                                      ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image, color: Colors.white30, size: 32)))
                                      : const Center(child: Icon(Icons.image, color: Colors.white30, size: 48)),
                                  ),
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
            
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ReviewsWidget(
                  entityType: 'businesses',
                  entityId: widget.business['id'] as int,
                  isLoggedIn: _isLoggedIn,
                ),
              ),
            ),
            
            const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
          ],
        ),
      ),
    );
  }
}
