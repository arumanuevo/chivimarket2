import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'api_service.dart';
import 'main.dart'; // Reutilizar layouts

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  bool _isLoading = true;
  List<dynamic> _plans = [];

  // Controladores temporales para editar
  final Map<String, TextEditingController> _businessControllers = {};
  final Map<String, TextEditingController> _productControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/admin/subscription-plans');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _plans = data;
          for (var p in _plans) {
            String pname = p['plan_name'];
            _businessControllers[pname] = TextEditingController(text: p['max_businesses'].toString());
            _productControllers[pname] = TextEditingController(text: p['max_products'].toString());
          }
        });
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.statusCode}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Red error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      // Reconstruir el array para mandar a la API
      List<Map<String, dynamic>> updatedPlans = [];
      for (var p in _plans) {
        String pname = p['plan_name'];
        updatedPlans.add({
          'plan_name': pname,
          'max_businesses': int.tryParse(_businessControllers[pname]?.text ?? '1') ?? 1,
          'max_products': int.tryParse(_productControllers[pname]?.text ?? '10') ?? 10,
        });
      }

      final res = await ApiService.patch('/admin/subscription-plans', {'plans': updatedPlans});
      
      if (res.statusCode == 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Límites actualizados masivamente en el Servidor'), backgroundColor: Colors.green));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${res.statusCode}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Red error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Modificadores de Suscripción', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reglas de la Plataforma', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                      const SizedBox(height: 8),
                      const Text('Define la cantidad máxima de sucursales y productos que puede cargar un vendedor según el anillo al que pertenece. Estos cambios aplicarán inmediatamente a toda la red.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70), fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // Listado de Tiers (Free, Basic, Premium, Enterprise)
                      ..._plans.map((plan) {
                        String name = plan['plan_name'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24)),
                            borderRadius: BorderRadius.circular(16)
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name.toUpperCase(), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _businessControllers[name],
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                      decoration: const InputDecoration(
                                        labelText: 'Máx. Sucursales',
                                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54), fontSize: 12),
                                        prefixIcon: Icon(Icons.store, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.30), size: 18),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: _productControllers[name],
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                      decoration: const InputDecoration(
                                        labelText: 'Máx. Productos (Total)',
                                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54), fontSize: 12),
                                        prefixIcon: Icon(Icons.inventory, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.30), size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent, 
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          onPressed: _saveChanges,
                          icon: const Icon(Icons.save),
                          label: const Text('Impactar Límites Globales', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
