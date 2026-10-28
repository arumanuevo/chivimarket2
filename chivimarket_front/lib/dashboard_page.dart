import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'api_service.dart';
import 'main.dart'; // Para reutilizar AnimatedGradientBackground
import 'upgrade_plan_page.dart';
import 'change_password_dialog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _userName = "Comerciante";
  String _plan = "Cargando...";
  String _storesTracker = "- / -";
  int _currentStores = 0;
  int _storeLimit = 1;
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
            _currentStores = data['subscription_stats']['current'] ?? 0;
            _storeLimit = data['subscription_stats']['limit'] ?? 1;
            final dynamicLimit = _storeLimit > 900 ? '∞' : _storeLimit.toString();
            _storesTracker = "$_currentStores / $dynamicLimit";
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

  Future<void> _handleCreateBusiness() async {
    if (_currentStores >= _storeLimit) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
              SizedBox(width: 8),
              Text('Límite Alcanzado'),
            ],
          ),
          content: const Text(
            'Has alcanzado la cantidad máxima de tiendas permitidas en tu plan actual. Para expandir tu negocio, por favor sube de nivel tu suscripción.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => UpgradePlanPage())).then((_) => _fetchProfile());
              },
              child: const Text('VER PLANES PRO', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final result = await Navigator.pushNamed(context, '/create-business');
    if (result == true) _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Panel de Comercios',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: onSurface, fontSize: isMobile ? 18 : 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(themeNotifier.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode, color: Colors.orangeAccent),
            tooltip: 'Cambiar Tema',
            onPressed: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: onSurface),
            tooltip: 'Cerrar Sesión',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: AnimatedGradientBackground(
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16.0 : 28.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==========================================
                        // CABECERA DE BIENVENIDA Y PERFIL
                        // ==========================================
                        _buildProfileHeader(isMobile, isDark, onSurface, primary),
                        const SizedBox(height: 20),

                        // ==========================================
                        // TARJETAS DE ESTADÍSTICAS (COMPACTAS)
                        // ==========================================
                        _buildStatsSection(isMobile, isDark, onSurface, primary),
                        const SizedBox(height: 28),

                        // ==========================================
                        // SECCIÓN DE ACCIONES RÁPIDAS
                        // ==========================================
                        Row(
                          children: [
                            Icon(Icons.bolt, color: primary, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Acciones Rápidas',
                              style: GoogleFonts.outfit(
                                fontSize: isMobile ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Grid de Acciones (Fluido, sin contenedor atrapado)
                        _buildActionsGrid(isMobile, isDark, onSurface, primary),
                        const SizedBox(height: 24),

                        // ==========================================
                        // BANNER DIRECTO: VOLVER AL MODO COMPRADOR
                        // ==========================================
                        _buildReturnToBuyerBanner(isDark, onSurface, primary),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // Header del Usuario
  Widget _buildProfileHeader(bool isMobile, bool isDark, Color onSurface, Color primary) {
    final solidCardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: solidCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 24 : 28,
            backgroundColor: primary.withOpacity(0.15),
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'C',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 20 : 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $_userName!',
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Panel de Control de tu Comercio',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          // Badge Plan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _plan.toLowerCase().contains('pro') ? Colors.amber.withOpacity(0.15) : primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _plan.toLowerCase().contains('pro') ? Colors.amber : primary,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _plan.toLowerCase().contains('pro') ? Icons.star : Icons.shield_outlined,
                  size: 13,
                  color: _plan.toLowerCase().contains('pro') ? Colors.amber : primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _plan.toUpperCase(),
                  style: TextStyle(
                    color: _plan.toLowerCase().contains('pro') ? Colors.amber : primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sección de Estadísticas: En Celular 2 columnas compactas en Row; en Desktop Wrap
  Widget _buildStatsSection(bool isMobile, bool isDark, Color onSurface, Color primary) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  'Mi Plan',
                  _plan,
                  Icons.workspace_premium,
                  Colors.amber,
                  isDark,
                  onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactStatCard(
                  'Locales Creados',
                  _storesTracker,
                  Icons.storefront,
                  const Color(0xFF10B981),
                  isDark,
                  onSurface,
                ),
              ),
            ],
          ),
          if (_isSuperAdmin) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.admin_panel_settings, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Modo Súper Administrador Activo', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildCompactStatCard('Mi Plan', _plan, Icons.workspace_premium, Colors.amber, isDark, onSurface, width: 220),
        _buildCompactStatCard('Locales Creados', _storesTracker, Icons.storefront, const Color(0xFF10B981), isDark, onSurface, width: 220),
        if (_isSuperAdmin)
          _buildCompactStatCard('Permisos', 'Súper Admin', Icons.admin_panel_settings, Colors.redAccent, isDark, onSurface, width: 220),
      ],
    );
  }

  // Tarjeta de estadística compacta y proporcionada
  Widget _buildCompactStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    bool isDark,
    Color onSurface, {
    double? width,
  }) {
    final solidCardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: solidCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurface.withOpacity(0.60),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Grid de acciones rápidas: Proporción 1.35 en celular, cómodo y con espacio vertical
  Widget _buildActionsGrid(bool isMobile, bool isDark, Color onSurface, Color primary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Scroll natural de la página, sin atrapar al usuario
      crossAxisCount: isMobile ? 2 : (MediaQuery.of(context).size.width > 900 ? 4 : 3),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.28 : 1.45,
      children: [
        _buildActionCard(
          context,
          'Crear Nuevo Local',
          'Abrí una sucursal o catálogo',
          Icons.add_business_rounded,
          primary,
          isDark,
          onSurface,
          _handleCreateBusiness,
        ),
        _buildActionCard(
          context,
          'Mis Tiendas',
          'Gestionar productos y fotos',
          Icons.store_mall_directory_rounded,
          const Color(0xFF0D9488), // Teal
          isDark,
          onSurface,
          () => Navigator.pushNamed(context, '/my-businesses'),
        ),
        _buildActionCard(
          context,
          'Mejorar Mi Plan',
          'Aumentar límites de locales',
          Icons.rocket_launch_rounded,
          Colors.amber,
          isDark,
          onSurface,
          () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => UpgradePlanPage())).then((_) => _fetchProfile());
          },
        ),
        _buildActionCard(
          context,
          'Cambiar Clave',
          'Actualizar tu contraseña',
          Icons.lock_reset_rounded,
          const Color(0xFF6366F1), // Indigo
          isDark,
          onSurface,
          () => showChangePasswordDialog(context),
        ),
        if (_isSuperAdmin)
          _buildActionCard(
            context,
            'Súper Admin',
            'Gestión de usuarios y planes',
            Icons.admin_panel_settings_rounded,
            Colors.redAccent,
            isDark,
            onSurface,
            () => Navigator.pushNamed(context, '/super-admin'),
          ),
      ],
    );
  }

  // Tarjeta de acción individual, con buen área táctil, icono y subtítulo
  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    bool isDark,
    Color onSurface,
    VoidCallback onTap,
  ) {
    final solidCardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: iconColor.withOpacity(0.15),
        highlightColor: iconColor.withOpacity(0.08),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: solidCardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: iconColor),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  color: onSurface.withOpacity(0.55),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Banner para regresar a la vista de compras / consumidor
  Widget _buildReturnToBuyerBanner(bool isDark, Color onSurface, Color primary) {
    final solidCardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: () => Navigator.pushReplacementNamed(context, '/buyer-home'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: solidCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volver al Modo Comprador',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: onSurface,
                    ),
                  ),
                  Text(
                    'Explorar comercios, radar de vidrieras y trueques',
                    style: TextStyle(
                      fontSize: 11,
                      color: onSurface.withOpacity(0.60),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  // Drawer Lateral
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                Icon(Icons.storefront, size: 44, color: Theme.of(context).colorScheme.onSurface),
                const SizedBox(height: 10),
                Text('ChiviMarket', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                Text('Panel Comercios', style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.orangeAccent),
            title: Text('Inicio (Panel)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.store, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70)),
            title: Text('Mis Tiendas y Catálogos', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/my-businesses');
            },
          ),
          ListTile(
            leading: Icon(Icons.add_business, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70)),
            title: Text('Crear Nuevo Negocio', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
            onTap: () {
              Navigator.pop(context);
              _handleCreateBusiness();
            },
          ),
          if (_isSuperAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.redAccent),
              title: const Text('Súper Administración', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/super-admin');
              },
            ),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text('Suscripción Pro', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => UpgradePlanPage())).then((_) => _fetchProfile());
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: Icon(Icons.lock_reset, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70)),
            title: Text('Cambiar Contraseña', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
            onTap: () {
              Navigator.pop(context);
              showChangePasswordDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.greenAccent),
            title: const Text('Volver a Compras', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/buyer-home');
            },
          ),
        ],
      ),
    );
  }
}
