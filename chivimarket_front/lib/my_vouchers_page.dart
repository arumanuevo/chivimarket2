import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'main.dart'; // import AnimatedGradientBackground, GlassContainer
import 'package:qr_flutter/qr_flutter.dart';

class MyVouchersPage extends StatefulWidget {
  const MyVouchersPage({Key? key}) : super(key: key);

  @override
  State<MyVouchersPage> createState() => _MyVouchersPageState();
}

class _MyVouchersPageState extends State<MyVouchersPage> {
  bool _isLoading = true;
  List<dynamic> _vouchers = [];

  @override
  void initState() {
    super.initState();
    _fetchMyVouchers();
  }

  Future<void> _fetchMyVouchers() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/vouchers/my-vouchers');
      if (res.statusCode == 200) {
        if (mounted) setState(() {
          _vouchers = jsonDecode(res.body);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showQRCodeDialog(String code, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            QrImageView(
              data: code,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 2)),
            const SizedBox(height: 8),
            const Text('Presenta este código en la caja del local para redimir tu beneficio.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: Colors.black)))
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Mi Billetera de Cupones', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Expanded(
                 child: _isLoading 
                   ? const Center(child: CircularProgressIndicator())
                   : _vouchers.isEmpty
                     ? const Center(child: Text('No tienes cupones guardados.\nExplora tiendas y reclama ofertas.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)))
                     : RefreshIndicator(
                         onRefresh: _fetchMyVouchers,
                         child: ListView.builder(
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                           itemCount: _vouchers.length,
                           itemBuilder: (ctx, index) {
                             final voucher = _vouchers[index];
                             final promo = voucher['promotion'];
                             final business = promo['business'];
                             
                             final isClaimed = voucher['status'] == 'claimed';
                             final statusColor = isClaimed ? Colors.greenAccent : Colors.grey;
                             final statusText = isClaimed ? 'DISPONIBLE PARA USAR' : (voucher['status'] == 'redeemed' ? 'YA UTILIZADO' : 'EXPIRADO');

                             return Padding(
                               padding: const EdgeInsets.only(bottom: 16.0),
                               child: GlassContainer(
                                 padding: const EdgeInsets.all(16),
                                 borderRadius: 16,
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                           decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                           child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                                         ),
                                         Text(voucher['code'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
                                       ],
                                     ),
                                     const SizedBox(height: 12),
                                     Text(promo['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orangeAccent)),
                                     Text(promo['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                     const SizedBox(height: 12),
                                     Row(
                                       children: [
                                          const Icon(Icons.storefront, size: 16, color: Colors.blueAccent),
                                          const SizedBox(width: 8),
                                          Text(business['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                       ]
                                     ),
                                     if (isClaimed) ...[
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                            onPressed: () => _showQRCodeDialog(voucher['code'], promo['title']), 
                                            icon: const Icon(Icons.qr_code, color: Colors.black), 
                                            label: const Text('MOSTRAR CÓDIGO', style: TextStyle(fontWeight: FontWeight.bold))
                                          ),
                                        )
                                     ]
                                   ],
                                 )
                               ),
                             );
                           }
                         ),
                     )
               )
            ],
          ),
        )
      )
    );
  }
}
