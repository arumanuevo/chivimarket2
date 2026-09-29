import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:convert';
import 'api_service.dart';
import 'main.dart'; // Para reutilizar GlassContainer y AnimatedGradientBackground

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _userName = "Comerciante";
  String _plan = "Cargando...";
  String _storesTracker = "- / -";
  bool _isSuperAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await ApiService.get('/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _userName = data['user']['name'] ?? 'Usuario';
            _isSuperAdmin = data['is_super_admin'] ?? false;
            _plan = data['subscription_stats']['plan'] ?? 'Free';
            _storesTracker = "${data['subscription_stats']['current']} / ${data['subscription_stats']['limit']}";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await ApiService.removeToken();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Panel de Administración', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: _logout,
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E293B), // Dark slate
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.storefront, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text('ChiviMarket', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Panel Comercios', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.orangeAccent),
              title: const Text('Inicio', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.store, color: Colors.white70),
              title: const Text('Mi Negocio (Perfil)', style: TextStyle(color: Colors.white70)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.white70),
              title: const Text('Imágenes y Escaparate', style: TextStyle(color: Colors.white70)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Suscripción Pro', style: TextStyle(color: Colors.white70)),
              onTap: () {}, // Aquí irá la ruta de simular pago
            ),
          ],
        ),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bienvenido, $_userName', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Estadísticas y estado general de tu local.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 32),
                
                // Stat Cards Row (Responsivo)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard(context, 'Rango Actual', _plan, Icons.workspace_premium, Colors.grey),
                    _buildStatCard(context, 'Locales Creados', _storesTracker, Icons.store, Colors.greenAccent),
                    if (_isSuperAdmin)
                      _buildStatCard(context, 'Modo de Acceso', 'Súper Admin', Icons.admin_panel_settings, Colors.redAccent),
                  ],
                ),

                const SizedBox(height: 40),
                Text('Acciones Rápidas', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                
                Expanded(
                  child: GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      // Solo mostramos el boton de crear comercio si NO somos limitados (Opcional)
                      _buildActionCard(context, 'Crear Nuevo Local', Icons.add_business, () async {
                        final result = await Navigator.pushNamed(context, '/create-business');
                        if (result == true) _fetchProfile(); // Refrescar stats si creamos
                      }),
                      _buildActionCard(context, 'Editar Datos del Local', Icons.edit_document, () {}),
                      _buildActionCard(context, 'Mejorar Plan', Icons.rocket_launch, () {}),
                      if (_isSuperAdmin)
                        _buildActionCard(context, 'God Mode: Gestión', Icons.people_alt, () {
                          // TODO: Navegar a la página de lista de usuarios para asignar roles
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color iconColor) {
    return GlassContainer(
      width: 250,
      padding: const EdgeInsets.all(24),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
