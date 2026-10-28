import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'forgot_password_dialog.dart';

void showChangePasswordDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _ChangePasswordDialogContent(),
  );
}

class _ChangePasswordDialogContent extends StatefulWidget {
  const _ChangePasswordDialogContent({Key? key}) : super(key: key);

  @override
  State<_ChangePasswordDialogContent> createState() => _ChangePasswordDialogContentState();
}

class _ChangePasswordDialogContentState extends State<_ChangePasswordDialogContent> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (current.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _errorMessage = 'Por favor completa todos los campos.');
      return;
    }

    if (newPass.length < 8) {
      setState(() => _errorMessage = 'La nueva contraseña debe tener al menos 8 caracteres.');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'La confirmación de contraseña no coincide.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.post('/change-password', {
        'current_password': current,
        'new_password': newPass,
        'new_password_confirmation': confirmPass,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? '¡Contraseña actualizada con éxito!'),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Error al actualizar la contraseña.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final primary = const Color(0xFFF97316);
    // Fondo 100% SÓLIDO (Cero transparencia para que no se mezcle con el fondo)
    final solidDialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Dialog(
      backgroundColor: solidDialogBg,
      surfaceTintColor: Colors.transparent,
      elevation: 24,
      shadowColor: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: solidDialogBg,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(26),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_reset, color: primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cambiar Contraseña',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        Text(
                          'Actualiza tu clave de acceso',
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: onSurface.withOpacity(0.5)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Contraseña actual
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  labelText: 'Contraseña Actual',
                  labelStyle: TextStyle(color: onSurface.withOpacity(0.6)),
                  filled: true,
                  fillColor: inputBg,
                  prefixIcon: Icon(Icons.lock_outline, color: onSurface.withOpacity(0.5)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, color: onSurface.withOpacity(0.5)),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),

              // Ayuda especial para usuarios de Google OAuth o que no recuerdan la clave
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  showForgotPasswordDialog(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(Icons.g_mobiledata, size: 22, color: primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '¿Iniciaste con Google o no sabes tu clave actual? Haz clic aquí para definirla con un código por email.',
                          style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Nueva contraseña
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña (mínimo 8 caracteres)',
                  labelStyle: TextStyle(color: onSurface.withOpacity(0.6)),
                  filled: true,
                  fillColor: inputBg,
                  prefixIcon: Icon(Icons.key, color: onSurface.withOpacity(0.5)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: onSurface.withOpacity(0.5)),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Confirmar contraseña
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  labelText: 'Confirmar Nueva Contraseña',
                  labelStyle: TextStyle(color: onSurface.withOpacity(0.6)),
                  filled: true,
                  fillColor: inputBg,
                  prefixIcon: Icon(Icons.check_circle_outline, color: onSurface.withOpacity(0.5)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: onSurface.withOpacity(0.5)),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text('Cancelar', style: TextStyle(color: onSurface.withOpacity(0.7))),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Actualizar Clave', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
