import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'main.dart'; // import GlassContainer

class PromotionsListWidget extends StatefulWidget {
  final int? businessId;
  final int? productId;
  final bool isLoggedIn;

  const PromotionsListWidget({Key? key, this.businessId, this.productId, required this.isLoggedIn}) : super(key: key);

  @override
  State<PromotionsListWidget> createState() => _PromotionsListWidgetState();
}

class _PromotionsListWidgetState extends State<PromotionsListWidget> {
  bool _isLoading = true;
  List<dynamic> _promotions = [];
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
  }

  Future<void> _fetchPromotions() async {
    try {
      final endpoint = widget.productId != null 
          ? '/products/${widget.productId}/promotions'
          : '/businesses/${widget.businessId}/promotions';

      final res = await ApiService.get(endpoint);
      if (res.statusCode == 200) {
        if (mounted) setState(() {
          _promotions = jsonDecode(res.body);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _claimVoucher(int promotionId) async {
    if (!widget.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para obtener descuentos.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isClaiming = true);

    try {
      final res = await ApiService.post('/promotions/$promotionId/claim', {});
      
      final data = jsonDecode(res.body);

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡Éxito! Tu código es: ${data['voucher']['code']}'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Error al reclamar.'), backgroundColor: Colors.redAccent));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión.')));
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
    if (_promotions.isEmpty) return const SizedBox.shrink(); // No mostrar nada si no hay promociones

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('🔥 Ofertas Disponibles', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
        const SizedBox(height: 12),
        ..._promotions.map((promo) {
          return GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            child: Row(
              children: [
                const Icon(Icons.local_offer, color: Colors.orange, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(promo['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      if (promo['description'] != null) Text(promo['description'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Req. Nivel ${promo['required_level']} RPG', style: TextStyle(color: Colors.blueAccent.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _isClaiming ? null : () => _claimVoucher(promo['id']),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                  child: const Text('OBTENER', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
