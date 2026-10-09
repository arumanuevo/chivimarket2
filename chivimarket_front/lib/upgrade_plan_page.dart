import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'api_service.dart';
import 'main.dart'; // GlassContainer, AnimatedGradientBackground

class UpgradePlanPage extends StatefulWidget {
  @override
  State<UpgradePlanPage> createState() => _UpgradePlanPageState();
}

class _UpgradePlanPageState extends State<UpgradePlanPage> {
  bool _isLoading = true;
  String _currentPlan = 'free';
  String? _nextPaymentDue;

  @override
  void initState() {
    super.initState();
    _fetchCurrentStatus();
  }

  Future<void> _fetchCurrentStatus() async {
    try {
      final res = await ApiService.get('/subscription/status');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() {
          _currentPlan = data['type'] ?? 'free';
          _nextPaymentDue = data['formatted_ends_at']; 
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _simulatePaymentAndUpgrade(String planName) async {
    if (planName.toLowerCase() == _currentPlan.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya cuentas con este plan.')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            const Icon(Icons.payment, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text('Checkout Simulator', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
        content: Text('Simularás el pago en "MercadoPago" por la suscripción al plan ${planName.toUpperCase()} mensual.\n\n¿Deseas registrar un pago exitoso?'),
        actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Rechazar Pago')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
              child: const Text('Pago Exitoso', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ]
      )
    );

    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.put('/subscription/upgrade', {
        'plan': planName,
        'payment_method': 'mercadopago'
      });
      
      if (res.statusCode == 200) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡Excelente! Has sido promovido al plan ${planName.toUpperCase()}'), backgroundColor: Colors.green));
           _fetchCurrentStatus();
        }
      } else {
        final err = jsonDecode(res.body);
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err['error'] ?? 'No puedes realizar downgrade en este momento.'), backgroundColor: Colors.red));
            setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String name,
    required String price,
    required List<String> features,
    required Color highlightColor,
    bool isPopular = false,
  }) {
    final isCurrent = _currentPlan.toLowerCase() == name.toLowerCase();

    return Container(
      width: 280, // Fijo para el scroll horizontal en móviles, responsivo en pantallas grandes
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: highlightColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  price,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '/ mes',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20, color: highlightColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
                    ],
                  ),
                )).toList(),
                
                const Spacer(),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent ? Colors.grey : highlightColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isCurrent ? null : () => _simulatePaymentAndUpgrade(name),
                  child: Text(
                    isCurrent ? 'Plan Actual' : 'Contratar $name',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                )
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: highlightColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: highlightColor.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: const Text(
                    'MÁS ELEGIDO',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Membresías', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context, true), // Retorna 'true' para indicar posible cambio
        ),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface))
              : Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Potencia tus ventas',
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Llega a miles de clientes locales y crece sin límites.',
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    if (_nextPaymentDue != null && _currentPlan != 'free')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Suscripción ${_currentPlan.toUpperCase()} vigente hasta el $_nextPaymentDue',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                    const SizedBox(height: 24),
                    
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildPlanCard(
                              context: context,
                              name: 'Free',
                              price: 'Gratis',
                              features: ['1 Local Asociado', '5 Productos de catálogo', 'Soporte Básico', 'Vouchers nivel 1'],
                              highlightColor: Colors.blueAccent,
                            ),
                            _buildPlanCard(
                              context: context,
                              name: 'Basic',
                              price: '\$ 15.000',
                              features: ['2 Locales Asociados', '20 Productos de catálogo', 'Soporte Prioritario', 'Vouchers nivel 2', 'Insignia de confianza'],
                              highlightColor: Colors.orangeAccent,
                            ),
                            _buildPlanCard(
                              context: context,
                              name: 'Premium',
                              price: '\$ 35.000',
                              features: ['10 Locales Asociados', '100 Productos totales', 'Banner Promocional', 'Vouchers nivel 3', 'Destacado en búsquedas'],
                              highlightColor: Colors.pinkAccent,
                              isPopular: true,
                            ),
                            _buildPlanCard(
                              context: context,
                              name: 'Enterprise',
                              price: '\$ 90.000',
                              features: ['Locales Ilimitados', 'Catálogo Ilimitado', 'Ejecutivo de cuentas VIP', 'Vouchers RPG Ilimitados'],
                              highlightColor: Colors.deepPurpleAccent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
        ),
      ),
    );
  }
}
