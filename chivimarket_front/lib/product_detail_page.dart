import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Reutilizamos AnimatedGradientBackground y GlassContainer
import 'public_business_page.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  String _getImageUrl() {
    if (product['images'] != null && product['images'].isNotEmpty) {
      String url = product['images'][0]['full_url'] ?? product['images'][0]['url'];
      if (!url.startsWith('http')) return 'https://chivimarket.arumasoft.com/$url';
      return url;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    final business = product['business'] ?? {};

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
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
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
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
                                product['name'] ?? 'Producto Remasterizado',
                                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(12)),
                              child: Text('\$${product['price']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black87)),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Ficha del Negocio
                        if (business.isNotEmpty)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              child: Icon(Icons.storefront, color: Theme.of(context).colorScheme.primary),
                            ),
                            title: Text(business['name'] ?? 'Tienda', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Comercio Verificado', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                          ),
                        
                        const Divider(color: Colors.white24, height: 32),
                        Text('Descripción del Artículo', style: GoogleFonts.outfit(fontSize: 18, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(
                          product['description'] ?? 'No hay descripción disponible para este producto en este momento.',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, height: 1.5),
                        ),
                        
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              if (business.isNotEmpty) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PublicBusinessPage(business: business)));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este producto no tiene una tienda asociada aún.', backgroundColor: Colors.orange)));
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
