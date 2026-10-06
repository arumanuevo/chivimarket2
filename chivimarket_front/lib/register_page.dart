import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:g_recaptcha_v3/g_recaptcha_v3.dart';
import 'api_service.dart';
import 'main.dart'; // Para reutilizar GlassContainer y AnimatedGradientBackground

class RegisterPage extends StatefulWidget {
  RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      // 1. Generamos el token de seguridad invisible para Google
      String recaptchaToken = await GRecaptchaV3.execute('register') ?? 'token_fallido';

      final response = await ApiService.post('/register', {
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'recaptcha_token': recaptchaToken, 
      });

      if (response.statusCode == 201) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cuenta registrada con éxito. ¡Verifica tu correo!'), backgroundColor: Colors.green));
           Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        if (mounted) {
          String errorMessage = 'Ocurrió un error al registrarse.';
          try {
            final decoded = jsonDecode(response.body);
            if (decoded['message'] != null) {
              errorMessage = decoded['message'];
            } else if (decoded is Map) {
              errorMessage = "Revisa: ${decoded.values.first[0]}";
            }
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de red: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                  Icon(Icons.person_add_alt, size: 64, color: Theme.of(context).colorScheme.primary),
                  SizedBox(height: 24),
                  Text('Crear Cuenta', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  SizedBox(height: 40),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Nombre del Administrador (Tu Nombre)',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.60)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                      prefixIcon: Icon(Icons.store, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.60)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                      prefixIcon: Icon(Icons.email, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.60)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                      prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                    ),
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface) : Text('Registrarse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

