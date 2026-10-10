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
import 'package:g_recaptcha_v3/g_recaptcha_v3.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "env.txt"); // Carga el archivo env.txt
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
            scaffoldBackgroundColor: Color(0xFFF1F5F9), // Slate 50
            primarySwatch: Colors.orange,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF97316),
              secondary: Color(0xFFFB923C),
              surface: Color(0x99FFFFFF), // Superficie clarita
              onSurface: Colors.black87, // Texto principal en claro
            ),
            appBarTheme: AppBarTheme(
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
            scaffoldBackgroundColor: Color(0xFF1E293B), // Dark blueish gray background
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF97316),
              secondary: Color(0xFFFB923C),
              surface: Color(0x33FFFFFF), // Transparent surface for glassmorphism
              onSurface: Colors.white,
            ),
            appBarTheme: AppBarTheme(
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

  GlassContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(32),
    this.borderRadius = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Optimizado (20 era muy costoso para Web)
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: Offset(0, 10),
              )
            ],
          ),
          child: child,
        ),
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
          SafeArea(child: child),
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

  void _showError(String msg) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedGradientBackground(
        child: Center(
          child: GlassContainer(
            width: 450,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dashboard_customize, size: 64, color: Theme.of(context).colorScheme.primary),
                SizedBox(height: 24),
                Text('Acceso Central', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 8),
                Text('Administra tu escaparate local', style: TextStyle(color: Colors.white60, fontSize: 16)),
                SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                    prefixIcon: Icon(Icons.email, color: Colors.white54),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                    prefixIcon: Icon(Icons.lock, color: Colors.white54),
                  ),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Comenzar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('O INGRESAR CON', style: TextStyle(color: Colors.white54, fontSize: 12))),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                  ],
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () {}, // Backend login url for future
                    icon: _isGoogleLoading 
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : Icon(Icons.g_mobiledata, size: 36, color: Colors.white),
                    label: Text('Continuar con Google', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Colors.white.withOpacity(0.05)
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: Text('¿No tienes cuenta? Registra tu Comercio Aquí', style: TextStyle(color: Colors.white70)),
                )
              ],
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
                    color: Colors.greenAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, size: 80, color: Colors.greenAccent),
                ),
                SizedBox(height: 32),
                Text(
                  'Cuenta Verificada!',
                  style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Tu email ha sido validado correctamente. Tu negocio ya cuenta con la insignia de confianza en ChiviMarket.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
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

