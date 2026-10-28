import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'legal_terms_page.dart';

class SelectedPhoto {
  final Uint8List bytes;
  final String name;

  SelectedPhoto({required this.bytes, required this.name});
}

class CreateCommunityPostPage extends StatefulWidget {
  const CreateCommunityPostPage({Key? key}) : super(key: key);

  @override
  State<CreateCommunityPostPage> createState() => _CreateCommunityPostPageState();
}

class _CreateCommunityPostPageState extends State<CreateCommunityPostPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String _type = 'both'; // 'barter', 'sale', 'both'
  String _condition = 'buen_estado'; // 'como_nuevo', 'muy_bueno', 'buen_estado', 'con_detalles'

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _barterForController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  final List<SelectedPhoto> _selectedPhotos = [];
  bool _acceptedTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _barterForController.dispose();
    _whatsappController.dispose();
    _zoneController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    if (_selectedPhotos.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya agregaste el máximo de 4 fotos.')),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.teal),
              title: const Text('Elegir de Galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.teal),
              title: const Text('Tomar Foto con Cámara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      if (source == ImageSource.camera) {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 80,
        );
        if (photo != null) {
          final bytes = await photo.readAsBytes();
          if (mounted) {
            setState(() {
              _selectedPhotos.add(SelectedPhoto(bytes: bytes, name: photo.name));
            });
          }
        }
      } else {
        final List<XFile> photos = await _picker.pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 80,
        );
        if (photos.isNotEmpty) {
          final availableSlots = 4 - _selectedPhotos.length;
          final photosToAdd = photos.take(availableSlots);
          for (final photo in photosToAdd) {
            final bytes = await photo.readAsBytes();
            if (mounted) {
              setState(() {
                _selectedPhotos.add(SelectedPhoto(bytes: bytes, name: photo.name));
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar foto: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar la declaración jurada y los términos legales para continuar.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fields = <String, String>{
        'title': _titleController.text.trim(),
        'type': _type,
        'description': _descController.text.trim(),
        'condition': _condition,
        'contact_whatsapp': _whatsappController.text.trim(),
        'zone': _zoneController.text.trim().isNotEmpty ? _zoneController.text.trim() : 'Chivilcoy',
        'accepted_terms': '1',
      };

      if (_priceController.text.trim().isNotEmpty) {
        fields['price'] = _priceController.text.trim();
      }
      if ((_type == 'barter' || _type == 'both') && _barterForController.text.trim().isNotEmpty) {
        fields['barter_for'] = _barterForController.text.trim();
      }
      if (_imageUrlController.text.trim().isNotEmpty) {
        fields['image_url'] = _imageUrlController.text.trim();
      }

      http.Response response;

      if (_selectedPhotos.isNotEmpty) {
        final multipartFiles = <http.MultipartFile>[];
        for (int i = 0; i < _selectedPhotos.length; i++) {
          multipartFiles.add(
            http.MultipartFile.fromBytes(
              'photos[]',
              _selectedPhotos[i].bytes,
              filename: _selectedPhotos[i].name.isNotEmpty ? _selectedPhotos[i].name : 'photo_$i.jpg',
            ),
          );
        }

        final streamed = await ApiService.postMultipart('/community-posts', fields, multipartFiles);
        response = await http.Response.fromStream(streamed);
      } else {
        response = await ApiService.post('/community-posts', fields);
      }

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Publicación creada exitosamente en Trueques y Usados! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final err = jsonDecode(response.body);
        final msg = err['message'] ?? err['detail'] ?? 'Error al crear la publicación';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 5)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Publicar Trueque o Usado', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner explicativo y de protección
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.handshake_outlined, color: Colors.blueAccent, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tablón Comunitario de Vecinos',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueAccent),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Publicá gratis lo que ya no usás para venderlo o intercambiarlo por trueque con otros vecinos de Chivilcoy.',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Selector de Modalidad (Trueque / Venta / Ambos)
              Text('Modalidad de la Publicación', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeOption(
                      value: 'both',
                      label: 'Venta o Trueque',
                      icon: Icons.sync_alt,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeOption(
                      value: 'barter',
                      label: 'Solo Trueque',
                      icon: Icons.swap_horiz,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeOption(
                      value: 'sale',
                      label: 'Solo Venta',
                      icon: Icons.sell_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==========================================
              // SUBIDA DE FOTOS (HASTA 4 CON COMPRESIÓN)
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fotos del Artículo (Máx. 4)', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${_selectedPhotos.length}/4 fotos', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Las fotos se optimizan y reescalan automáticamente para cargar al instante y no saturar el servidor.',
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 10),

              // Grilla de fotos seleccionadas
              SizedBox(
                height: 95,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedPhotos.length < 4 ? _selectedPhotos.length + 1 : 4,
                  itemBuilder: (context, index) {
                    if (index == _selectedPhotos.length && _selectedPhotos.length < 4) {
                      return InkWell(
                        onTap: _pickPhotos,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.withOpacity(0.5), style: BorderStyle.solid),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo_outlined, color: Colors.teal, size: 28),
                              SizedBox(height: 4),
                              Text('Agregar', style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }

                    final photo = _selectedPhotos[index];
                    return Stack(
                      children: [
                        Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: MemoryImage(photo.bytes),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 14,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPhotos.removeAt(index)),
                            child: const CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.redAccent,
                              child: Icon(Icons.close, size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                        if (index == 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Principal', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Título
              TextFormField(
                controller: _titleController,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: 'Título del artículo *',
                  hintText: 'Ej: Bicicleta mountain bike rodado 26, Heladera con freezer, etc.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 4) return 'Ingresá un título descriptivo (mínimo 4 letras)';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Estado de conservación del bien
              Text('Estado de Conservación *', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.verified_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'como_nuevo', child: Text('✨ Como nuevo (impecable / sin marcas)')),
                  DropdownMenuItem(value: 'muy_bueno', child: Text('👌 Muy bueno (poco uso / excelente)')),
                  DropdownMenuItem(value: 'buen_estado', child: Text('👍 Buen estado (funciona 100% / uso normal)')),
                  DropdownMenuItem(value: 'con_detalles', child: Text('🔧 Con detalles (para reparar o restaurar)')),
                ],
                onChanged: (val) => setState(() => _condition = val ?? 'buen_estado'),
              ),

              const SizedBox(height: 16),

              // Precio (si aplica venta o referencia)
              if (_type == 'sale' || _type == 'both') ...[
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _type == 'both' ? 'Precio de venta (opcional en trueque)' : 'Precio de venta en \$ ARS *',
                    hintText: 'Ej: 15000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  validator: (val) {
                    if (_type == 'sale') {
                      if (val == null || val.trim().isEmpty) return 'Ingresá el precio de venta';
                      if (double.tryParse(val.trim()) == null) return 'Ingresá un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // ¿Qué buscas a cambio? (para trueque)
              if (_type == 'barter' || _type == 'both') ...[
                TextFormField(
                  controller: _barterForController,
                  maxLength: 250,
                  decoration: InputDecoration(
                    labelText: '¿Qué te gustaría recibir a cambio? (Trueque) *',
                    hintText: 'Ej: Celular, herramientas, ropa de bebé talle 2, o escucho ofertas',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.swap_horizontal_circle_outlined),
                  ),
                  validator: (val) {
                    if (_type == 'barter' && (val == null || val.trim().length < 3)) {
                      return 'Indicá qué objetos o categorías te interesan a cambio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Descripción detallada
              TextFormField(
                controller: _descController,
                maxLines: 4,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: 'Descripción detallada del estado y funcionamiento *',
                  hintText: 'Describí con honestidad el estado, antigüedad, detalles estéticos, accesorios incluidos o motivos del trueque...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 10) return 'Por favor brindá una descripción de al menos 10 caracteres';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // WhatsApp de contacto
              TextFormField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Número de WhatsApp para contacto *',
                  hintText: 'Ej: 2346554433 (con código de área sin 0 ni 15)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.chat, color: Colors.green),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 6) return 'Ingresá un número de contacto válido para coordinar';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Barrio o zona de encuentro aproximada
              TextFormField(
                controller: _zoneController,
                decoration: InputDecoration(
                  labelText: 'Zona aproximada en Chivilcoy (Opcional)',
                  hintText: 'Ej: Plaza Principal, San Cayetano, Hospital, etc.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),

              const SizedBox(height: 16),

              // Enlace alternativo si no suben foto
              if (_selectedPhotos.isEmpty) ...[
                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'O bien ingresá URL de foto externa (Opcional)',
                    hintText: 'https://ejemplo.com/mifoto.jpg',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              // ==========================================
              // BLINDAJE LEGAL Y POLÍTICA DE SEGURIDAD
              // ==========================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gavel, color: Colors.redAccent, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Aviso Legal y Artículos Prohibidos',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Queda estrictamente PROHIBIDA la publicación de armas de fuego o réplicas, municiones, estupefacientes, medicamentos bajo receta, sustancias inflamables, bienes hurtados o de procedencia ilegítima, réplicas o animales vivos.\n'
                      '• ChiviMarket colabora activamente con las autoridades judiciales y policiales ante cualquier denuncia.',
                      style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurface.withOpacity(0.85), height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Checkbox de Declaración Jurada Obligatoria
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _acceptedTerms 
                      ? Colors.green.withOpacity(0.08) 
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _acceptedTerms ? Colors.green.withOpacity(0.4) : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      activeColor: Colors.green,
                      onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                        child: Text.rich(
                          TextSpan(
                            text: 'Declaro bajo fe de juramento ser titular de dominio legítimo del bien ofrecido, que no proviene de un ilícito y que su estado coincide con lo descrito. ',
                            style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurface),
                            children: [
                              TextSpan(
                                text: 'Acepto los Términos y Condiciones de Trueque y Usados y eximo expresamente a ChiviMarket de cualquier reclamo o responsabilidad.',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalTermsPage())),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Leer bases legales completas de ChiviMarket', style: TextStyle(fontSize: 11.5)),
                ),
              ),

              const SizedBox(height: 16),

              // Botón de Enviar
              ElevatedButton(
                onPressed: (_isLoading || !_acceptedTerms) ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Publicar en Trueques y Usados',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _type == value;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => _type = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.grey, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
