import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:ui';
import 'api_service.dart';
import 'register_page.dart';
import 'dashboard_page.dart';
import 'create_business_page.dart';
import 'my_businesses_page.dart';
import 'superadmin_page.dart';
import 'buyer_home_page.dart';
import 'legal_terms_page.dart';
import 'dynamic_showcase_page.dart';
import 'forgot_password_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:g_recaptcha_v3/g_recaptcha_v3.dart';


final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: ¡Pega tu SITKEY pública de ReCAPTCHA aquí para el Frontend!
  await GRecaptchaV3.ready('6LfajdItAAAAALK0AsHklkRGZz6D_kwQfNw1zNhi');
  runApp(ChivimarketApp());
}

class ChivimarketApp extends StatelessWidget {
  ChivimarketApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'ChiviMarket',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // CLARO
          theme: ThemeData(
            fontFamily: GoogleFonts.outfit().fontFamily,
            scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 50
            primarySwatch: Colors.orange,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF97316),
              secondary: Color(0xFFFB923C),
              surface: Colors.white, // 100% Sólido sin transparencias
              onSurface: Colors.black87, // Texto principal en claro
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 20,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            ),
            appBarTheme: const AppBarTheme(
              color: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.black87),
              titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          // OSCURO
          darkTheme: ThemeData(
            fontFamily: GoogleFonts.outfit().fontFamily,
            primarySwatch: Colors.orange,
            scaffoldBackgroundColor: const Color(0xFF1E293B), // Dark blueish gray background
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF97316),
              secondary: Color(0xFFFB923C),
              surface: Color(0xFF1E293B), // 100% Sólido sin transparencias
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1E293B),
              surfaceTintColor: Colors.transparent,
              elevation: 20,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            ),
            appBarTheme: const AppBarTheme(
              color: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.white),
            ),
          ),
          initialRoute: '/buyer-home',
          routes: {
            '/buyer-home': (context) => const BuyerHomePage(),
            '/login': (context) => LoginPage(),
            '/register': (context) => RegisterPage(),
            '/dashboard': (context) => DashboardPage(),
            '/create-business': (context) => CreateBusinessPage(),
            '/my-businesses': (context) => MyBusinessesPage(),
            '/super-admin': (context) => SuperAdminPage(),
            '/cuenta-verificada': (context) => CuentaVerificadaPage(),
            '/terminos-y-condiciones': (context) => const LegalTermsPage(),
            '/radar': (context) => const DynamicShowcasePage(),
          },
        );
      }
    );
  }
}

// ----------------------------------------------------
// COMPONENTS: GLASSMORPHISM & WIDGETS
// ----------------------------------------------------
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool enableBlur;

  GlassContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(32),
    this.borderRadius = 24.0,
    this.enableBlur = false, // Desactivado por defecto para 60 FPS en celulares
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1E293B) 
            : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06), 
          width: 1.2
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: child,
    );

    if (!enableBlur) {
      return content;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: content,
      ),
    );
  }
}

class AnimatedGradientBackground extends StatelessWidget {
  final Widget child;
  AnimatedGradientBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E1B4B), // Indigo 950
            Color(0xFF431407), // Orange 950
          ] : [
            Color(0xFFFFEDD5), // Orange 50
            Color(0xFFE0E7FF), // Indigo 50
            Color(0xFFF8FAFC), // Slate 50
          ],
          stops: const [0.1, 0.5, 0.9],
        ),
      ),
      child: Stack(
        children: [
          // Decorative glowing orbs optimized for Web (No BackdropFilter)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    Theme.of(context).colorScheme.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF6366F1).withOpacity(0.15),
                    Color(0xFF6366F1).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: child,
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// VIEWS
// ----------------------------------------------------
class LandingPage extends StatelessWidget {
  LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'ChiviMarket',
                        style: GoogleFonts.outfit(
                            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 10,
                    ),
                    child: Text('Acceso Restringido', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'El Ecosistema Comercial',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -1.5,
                        ),
                      ),
                      Text(
                        'Más Poderoso de Chivilcoy',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                          height: 1.1,
                          letterSpacing: -1.5,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Una plataforma premium reservada para conectar la ciudad.\nIngresa ahora al panel administrativo.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 48),
                      GlassContainer(
                        width: 600,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        borderRadius: 40,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Buscar directorios y locales...',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: Text('Explorar', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('/login', {
        'email': _emailController.text,
        'password': _passwordController.text,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await ApiService.saveToken(data['token']);
        }
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/buyer-home');
        }
      } else {
        _showError('Credenciales incorrectas');
      }
    } catch (e) {
      _showError('Error de red: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkIncomingGoogleToken();
  }

  Future<void> _checkIncomingGoogleToken() async {
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('token')) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        await ApiService.saveToken(token);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/buyer-home');
        }
      }
    } else if (uri.queryParameters.containsKey('error')) {
      _showError('No se pudo autenticar con Google. Intenta nuevamente.');
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final googleUrl = Uri.parse('${ApiService.baseUrl}/auth/google');
      await launchUrl(googleUrl, webOnlyWindowName: '_self');
    } catch (e) {
      _showError('Error al iniciar Google Sign-In: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showError(String msg) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedGradientBackground(
        child: Center(
          child: SingleChildScrollView(
            child: GlassContainer(
              width: 450,
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dashboard_customize, size: 64, color: primary),
                  const SizedBox(height: 24),
                  Text('Acceso Central', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: onSurface)),
                  const SizedBox(height: 8),
                  Text('Administra tu escaparate local', style: TextStyle(color: onSurface.withOpacity(0.65), fontSize: 16)),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _emailController,
                    style: TextStyle(color: onSurface),
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      labelStyle: TextStyle(color: onSurface.withOpacity(0.60)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary)),
                      prefixIcon: Icon(Icons.email, color: onSurface.withOpacity(0.54)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: onSurface),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: TextStyle(color: onSurface.withOpacity(0.60)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: onSurface.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primary)),
                      prefixIcon: Icon(Icons.lock, color: onSurface.withOpacity(0.54)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => showForgotPasswordDialog(context, initialEmail: _emailController.text.trim()),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: primary.withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Comenzar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: onSurface.withOpacity(0.2))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('O INGRESAR CON', style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12, fontWeight: FontWeight.bold))),
                      Expanded(child: Divider(color: onSurface.withOpacity(0.2))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isGoogleLoading ? null : _loginWithGoogle,
                      icon: _isGoogleLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : Icon(Icons.g_mobiledata, size: 36, color: onSurface),
                      label: Text('Continuar con Google', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: onSurface.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: onSurface.withOpacity(0.04)
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: Text('¿No tienes cuenta? Registra tu Comercio Aquí', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class CuentaVerificadaPage extends StatelessWidget {
  CuentaVerificadaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        child: Center(
          child: GlassContainer(
            width: 500,
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (Theme.of(context).brightness == Brightness.dark ? Colors.greenAccent : const Color(0xFF16A34A)).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, size: 80, color: Theme.of(context).brightness == Brightness.dark ? Colors.greenAccent : const Color(0xFF16A34A)),
                ),
                const SizedBox(height: 32),
                Text(
                  '¡Cuenta Verificada!',
                  style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu email ha sido validado correctamente. Tu negocio ya cuenta con la insignia de confianza en ChiviMarket.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75), fontSize: 16, height: 1.5),
                ),
                SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Ir al Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

