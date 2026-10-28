import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Reutilizamos AnimatedGradientBackground y GlassContainer
import 'public_business_page.dart';
import 'reviews_widget.dart';
import 'api_service.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    ApiService.getToken().then((token) {
      if (mounted) setState(() => _isLoggedIn = token != null);
    });
  }
  String _getImageUrl() {
    if (widget.product['images'] != null && widget.product['images'].isNotEmpty) {
      String url = widget.product['images'][0]['full_url'] ?? widget.product['images'][0]['url'];
      if (!url.startsWith('http')) return 'https://chivimarket.arumasoft.com/$url';
      return url;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color onSurface = theme.colorScheme.onSurface;
    final Color primary = theme.colorScheme.primary;
    final imageUrl = _getImageUrl();
    final business = widget.product['business'] ?? {};

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: isDark ? Colors.black54 : Colors.white.withOpacity(0.85),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: onSurface, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: AnimatedGradientBackground(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Image
              Stack(
                children: [
                  Container(
                    height: 400,
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surface,
                    child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Icon(Icons.shopping_bag, size: 100, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    height: 150,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                            ? const [Colors.transparent, Colors.black87]
                            : [Colors.transparent, const Color(0xFFF1F5F9).withOpacity(0.85)],
                        ),
                      ),
                    ),
                  )
                ],
              ),
              
              // Contenido Principal
              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.product['name'] ?? 'Producto',
                                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: onSurface),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(12)),
                              child: Text('\$${widget.product['price']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white)),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Ficha del Negocio
                        if (business.isNotEmpty)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: primary.withOpacity(0.15),
                              child: Icon(Icons.storefront, color: primary),
                            ),
                            title: Text(business['name'] ?? 'Tienda', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Comercio Verificado', 
                              style: TextStyle(
                                color: isDark ? Colors.greenAccent : const Color(0xFF15803D), 
                                fontSize: 12, 
                                fontWeight: FontWeight.w600
                              ),
                            ),
                          ),
                        
                        Divider(color: isDark ? Colors.white24 : Colors.black12, height: 32),
                        Text('Descripción del Artículo', style: GoogleFonts.outfit(fontSize: 18, color: primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(
                          widget.product['description'] ?? 'No hay descripción disponible para este producto en este momento.',
                          style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 15, height: 1.5),
                        ),
                        
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            onPressed: () {
                              if (business.isNotEmpty) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PublicBusinessPage(business: business, highlightedProduct: widget.product)));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este producto no tiene una tienda asociada aún.'), backgroundColor: Colors.orange));
                              }
                            },
                            icon: const Icon(Icons.map_rounded),
                            label: const Text('Ir a Comprarlo (Ver Mapa)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ReviewsWidget(
                  entityType: 'products',
                  entityId: widget.product['id'] as int,
                  isLoggedIn: _isLoggedIn,
                ),
              ),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
