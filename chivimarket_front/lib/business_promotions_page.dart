import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'main.dart'; // import GlassContainer

class BusinessPromotionsPage extends StatefulWidget {
  final Map<String, dynamic> business;

  const BusinessPromotionsPage({Key? key, required this.business}) : super(key: key);

  @override
  State<BusinessPromotionsPage> createState() => _BusinessPromotionsPageState();
}

class _BusinessPromotionsPageState extends State<BusinessPromotionsPage> {
  bool _isLoading = true;
  List<dynamic> _promotions = [];
  final TextEditingController _redeemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
  }

  Future<void> _fetchPromotions() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/businesses/${widget.business['id']}/promotions');
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

  Future<void> _createPromoDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final levelCtrl = TextEditingController(text: '1');
    final usesCtrl = TextEditingController(text: '1');
    bool isSaving = false;
    
    // Fetch products para el dropdown
    List<dynamic> storeProducts = [];
    try {
      final pRes = await ApiService.get('/products/search?business=${widget.business['id']}');
      if (pRes.statusCode == 200) {
         final data = jsonDecode(pRes.body);
         storeProducts = data is List ? data : (data['data'] ?? []);
      }
    } catch (_) {}

    String? selectedProductId;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateModal) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text('Nueva Promoción', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Aplicar a...', border: OutlineInputBorder()),
                    value: selectedProductId,
                    dropdownColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('- Toda la Tienda -', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))),
                      ...storeProducts.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['name'], style: const TextStyle(color: Colors.white)))),
                    ],
                    onChanged: (val) => setStateModal(() => selectedProductId = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título (Ej: 2x1 en Pintas)', border: OutlineInputBorder()), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Instrucciones / Descripción', border: OutlineInputBorder()), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: levelCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nivel Fidelidad Requerido', border: OutlineInputBorder()), style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: usesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Máx Usos/Pers', border: OutlineInputBorder()), style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                onPressed: isSaving ? null : () async {
                  if (titleCtrl.text.isEmpty) return;
                  setStateModal(() => isSaving = true);
                  
                  final bodyData = {
                    'title': titleCtrl.text,
                    'description': descCtrl.text,
                    'required_level': levelCtrl.text,
                    'max_uses_per_user': usesCtrl.text,
                    'is_active': true
                  };
                  if (selectedProductId != null) {
                    bodyData['product_id'] = selectedProductId!;
                  }

                  final res = await ApiService.post('/businesses/${widget.business['id']}/promotions', bodyData);
                  
                  if (res.statusCode == 201) {
                    Navigator.pop(ctx, true);
                  } else {
                    setStateModal(() => isSaving = false);
                    String errorMsg = "Ocurrió un error inesperado al guardar.";
                    try {
                      final decoded = jsonDecode(res.body);
                      if (decoded['message'] != null) {
                        errorMsg = decoded['message'];
                      } else if (decoded is Map) {
                        errorMsg = "Revisa los campos: ${decoded.values.first[0]}";
                      }
                    } catch (_) {}
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent));
                  }
                },
                child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black)) : const Text('Lanzar Promo', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          );
        });
      }
    );

    _fetchPromotions();
  }

  Future<void> _redeemVoucherDialog() async {
    _redeemController.clear();
    bool isRedeeming = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateModal) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text('🔫 Escáner de Caja', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pídele al cliente su Código Único de Voucher (Ej: CHIVI-ABCD) y escríbelo aquí para validar:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 16),
                TextField(
                  controller: _redeemController, 
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Ingresar Código', border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code_scanner, color: Colors.greenAccent)), 
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                onPressed: isRedeeming ? null : () async {
                  if (_redeemController.text.trim().isEmpty) return;
                  setStateModal(() => isRedeeming = true);
                  
                  final res = await ApiService.post('/vouchers/redeem', {
                    'code': _redeemController.text.trim().toUpperCase()
                  });
                  
                  final data = jsonDecode(res.body);
                  setStateModal(() => isRedeeming = false);

                  if (res.statusCode == 200) {
                     Navigator.pop(ctx);
                     _showSuccessRPG(data['transaction_details']);
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Código Inválido'), backgroundColor: Colors.redAccent));
                  }
                },
                child: isRedeeming ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black)) : const Text('💵 Cobrar y Validar', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          );
        });
      }
    );
  }

  void _showSuccessRPG(dynamic transactionDetails) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text('¡Transacción Exitosa!', style: GoogleFonts.outfit(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(Icons.verified, color: Colors.greenAccent, size: 60),
             const SizedBox(height: 16),
             Text('Cliente: ${transactionDetails['buyer_name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
             Text('Ha redimido: ${transactionDetails['total_business_visits']} cupones aquí.', style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
             const SizedBox(height: 8),
             Text('Promo: ${transactionDetails['promotion']}', style: const TextStyle(color: Colors.white70)),
             const SizedBox(height: 16),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
               child: Column(
                 children: [
                   const Text('RECOMPENSA DE FIDELIDAD', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900)),
                   Text('+${transactionDetails['xp_awarded_to_buyer']} Puntos otorgados al comprador', style: const TextStyle(color: Colors.white)),
                   if (transactionDetails['leveled_up'] == true)
                      Text('🌟 ¡El cliente alcanzó el Nivel VIP ${transactionDetails['new_level']}!', style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 16, textAlign: TextAlign.center)),
                 ]
               ),
             )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: Colors.greenAccent)))
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('🎫 Centro de Ofertas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               // Botonera de herramientas
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                 child: Row(
                   children: [
                     Expanded(
                       child: ElevatedButton.icon(
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                         onPressed: _createPromoDialog, 
                         icon: const Icon(Icons.add_circle), 
                         label: const Text('NUEVA PROMO', style: TextStyle(fontWeight: FontWeight.bold))
                       )
                     ),
                     const SizedBox(width: 8),
                     Expanded(
                       child: ElevatedButton.icon(
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                         onPressed: _redeemVoucherDialog, 
                         icon: const Icon(Icons.qr_code_scanner), 
                         label: const Text('COBRAR VOUCHER', style: TextStyle(fontWeight: FontWeight.bold))
                       )
                     ),
                   ]
                 ),
               ),
               const SizedBox(height: 16),
               
               // Lista de promociones publicadas
               Expanded(
                 child: _isLoading 
                   ? const Center(child: CircularProgressIndicator())
                   : _promotions.isEmpty
                     ? const Center(child: Text('No tienes ofertas publicadas.\n¡Lanza tu primera promoción para atraer clientes!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)))
                     : ListView.builder(
                         padding: const EdgeInsets.symmetric(horizontal: 16),
                         itemCount: _promotions.length,
                         itemBuilder: (ctx, index) {
                           final promo = _promotions[index];
                           return GlassContainer(
                             padding: const EdgeInsets.all(16),
                             borderRadius: 16,
                             child: Row(
                               children: [
                                 const Icon(Icons.local_offer, color: Colors.orange, size: 36),
                                 const SizedBox(width: 16),
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(promo['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                       const SizedBox(height: 4),
                                       Text(promo['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                       const SizedBox(height: 8),
                                       Row(
                                         children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                                              child: Text('Lv. ${promo['required_level']}+', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                                              child: Text('Max: ${promo['max_uses_per_user']}/us.', style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                                            ),
                                         ],
                                       )
                                     ],
                                   ),
                                 ),
                               ]
                             )
                           );
                         }
                       )
               )
            ],
          ),
        )
      )
    );
  }
}
