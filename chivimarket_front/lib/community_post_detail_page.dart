import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'legal_terms_page.dart';

class CommunityPostDetailPage extends StatefulWidget {
  final dynamic post;

  const CommunityPostDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  State<CommunityPostDetailPage> createState() => _CommunityPostDetailPageState();
}

class _CommunityPostDetailPageState extends State<CommunityPostDetailPage> {
  late dynamic _post;
  int _activeImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _fetchDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    try {
      final res = await ApiService.get('/community-posts/${_post['id']}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted && data['post'] != null) {
          setState(() => _post = data['post']);
        }
      }
    } catch (_) {}
  }

  Future<void> _contactViaWhatsapp() async {
    final rawPhone = (_post['contact_whatsapp'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El vendedor no especificó un número de WhatsApp.')),
      );
      return;
    }

    // Prefijo internacional para Argentina si empieza con 2346 o número de 10 dígitos
    String phone = rawPhone;
    if (!phone.startsWith('54')) {
      if (phone.startsWith('9')) {
        phone = '54$phone';
      } else {
        phone = '549$phone';
      }
    }

    final title = _post['title'] ?? 'tu publicación';
    final msg = Uri.encodeComponent('Hola! Vi tu publicación en ChiviMarket de "$title" y me interesa coordinar.');
    final url = Uri.parse('https://wa.me/$phone?text=$msg');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
        );
      }
    }
  }

  void _showReportDialog() {
    String selectedReason = 'articulo_prohibido';
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.report_problem_outlined, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Denunciar Publicación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Si detectás un artículo ilegal o sospechoso, informanos para proteger a la comunidad de Chivilcoy.',
                  style: TextStyle(fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  decoration: const InputDecoration(labelText: 'Motivo de la denuncia', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'articulo_prohibido', child: Text('Artículo prohibido (armas/medicamentos)')),
                    DropdownMenuItem(value: 'sospecha_ilicito', child: Text('Sospecha de procedencia ilícita o robado')),
                    DropdownMenuItem(value: 'estafa_falso', child: Text('Información engañosa o posible estafa')),
                    DropdownMenuItem(value: 'inapropiado_spam', child: Text('Contenido ofensivo o spam')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedReason = val ?? 'articulo_prohibido'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: detailsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Detalles adicionales (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final res = await ApiService.post('/community-posts/${_post['id']}/report', {
                    'reason': selectedReason,
                    'details': detailsController.text.trim(),
                  });
                  if (mounted) {
                    final data = jsonDecode(res.body);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(data['message'] ?? 'Denuncia registrada. Gracias.'), backgroundColor: Colors.orange),
                    );
                  }
                } catch (_) {}
              },
              child: const Text('Enviar Denuncia'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCondition(String? c) {
    switch (c) {
      case 'como_nuevo':
        return '✨ Como nuevo (impecable)';
      case 'muy_bueno':
        return '👌 Muy bueno';
      case 'buen_estado':
        return '👍 Buen estado (funciona 100%)';
      case 'con_detalles':
        return '🔧 Con detalles';
      default:
        return 'Usado';
    }
  }

  List<String> _getImagesList() {
    final rawImages = _post['images'];
    if (rawImages is List && rawImages.isNotEmpty) {
      return rawImages.map((e) => e.toString()).toList();
    }
    if (_post['image_url'] != null && _post['image_url'].toString().trim().isNotEmpty) {
      return [_post['image_url'].toString()];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final type = _post['type'] ?? 'both';
    final isBarter = type == 'barter';
    final isSale = type == 'sale';
    final isBoth = type == 'both';

    final images = _getImagesList();
    final price = _post['price'];
    final barterFor = _post['barter_for'];
    final condition = _post['condition'];
    final zone = _post['zone'] ?? 'Chivilcoy';
    final user = _post['user'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Trueque / Usado', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.orangeAccent),
            tooltip: 'Denunciar publicación',
            onPressed: _showReportDialog,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // GALERÍA DE IMÁGENES (PAGINADOR Y MINIATURAS)
            // ==========================================
            if (images.isNotEmpty) ...[
              Container(
                height: 280,
                width: double.infinity,
                color: isDark ? Colors.black26 : Colors.grey[200],
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _activeImageIndex = i),
                      itemBuilder: (context, index) {
                        final img = images[index];
                        final fullUrl = img.startsWith('http')
                            ? img
                            : 'https://chivimarket.arumasoft.com/$img';
                        return Image.network(
                          fullUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                        );
                      },
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 12,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_activeImageIndex + 1}/${images.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (images.length > 1) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _activeImageIndex;
                      final img = images[index];
                      final fullUrl = img.startsWith('http')
                          ? img
                          : 'https://chivimarket.arumasoft.com/$img';
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.teal : Colors.transparent,
                              width: 2.5,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(fullUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ] else ...[
              Container(
                height: 220,
                color: isDark ? Colors.black26 : Colors.grey[200],
                child: _buildPlaceholderIcon(),
              ),
            ],

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges de Modalidad y Condición
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(
                        label: isBoth ? '🔄🏷️ VENTA O TRUEQUE' : (isBarter ? '🔄 SOLO TRUEQUE' : '🏷️ VENTA USADO'),
                        color: isBoth ? Colors.teal : (isBarter ? Colors.deepPurpleAccent : Colors.orangeAccent),
                      ),
                      _buildBadge(
                        label: _formatCondition(condition),
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Título
                  Text(
                    _post['title'] ?? '',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  // Precio o valor
                  if (price != null && double.tryParse(price.toString()) != null && double.parse(price.toString()) > 0)
                    Text(
                      '\$${price.toString()}',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.greenAccent[700] ?? Colors.green,
                      ),
                    )
                  else if (isBarter)
                    Text(
                      '🤝 Disponible para permuta directa',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal[400]),
                    ),

                  const SizedBox(height: 12),

                  // Caja: ¿Qué busca en trueque?
                  if ((isBarter || isBoth) && barterFor != null && barterFor.toString().trim().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.swap_horizontal_circle, color: Colors.teal, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Acepta a cambio / Interesa para trueque:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  barterFor,
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Zona y datos del autor
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Chivilcoy ($zone)',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 13),
                      ),
                      const Spacer(),
                      Icon(Icons.person_outline, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        _post['contact_name'] ?? user['name'] ?? 'Vecino de Chivilcoy',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 13),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Descripción detallada
                  Text('Descripción del Artículo', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _post['description'] ?? 'Sin descripción',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // CAJA DE SEGURIDAD Y DESLINDE LEGAL
                  // ==========================================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, color: isDark ? Colors.orangeAccent : const Color(0xFFC2410C), size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Aviso de Seguridad Comunitario',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDark ? Colors.orangeAccent : const Color(0xFFC2410C)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• ChiviMarket es una plataforma tecnológica de contacto entre particulares. No es propietaria, no custodia ni garantiza los bienes intercambiados o vendidos.\n'
                          '• Toda operación se celebra bajo modalidad "como está" (ad-corpus).\n'
                          '• Coordiná siempre el encuentro en lugares públicos concurridos de Chivilcoy y en horarios diurnos.\n'
                          '• Revisá el funcionamiento y titularidad del bien personalmente antes de concretar.\n'
                          '• NUNCA transfieras señas ni dinero por adelantado.',
                          style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurface.withOpacity(0.85), height: 1.4),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalTermsPage())),
                          child: Text(
                            'Ver Términos y Condiciones Legales de ChiviMarket ➔',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.orangeAccent : const Color(0xFFC2410C)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón de Contacto por WhatsApp
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _contactViaWhatsapp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // Color oficial WhatsApp
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.chat, size: 22),
                      label: Text(
                        'Contactar por WhatsApp al Dueño',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Botón de Denuncia
                  Center(
                    child: TextButton.icon(
                      onPressed: _showReportDialog,
                      icon: const Icon(Icons.flag_outlined, size: 16, color: Colors.redAccent),
                      label: const Text('¿Artículo sospechoso o prohibido? Denunciar publicación', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.swap_horiz_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 8),
          Text('Trueque / Usado', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
