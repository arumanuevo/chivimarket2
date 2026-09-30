import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import 'main.dart'; // Para GlassContainer y Fondos
import 'products_page.dart';

class EditBusinessPage extends StatefulWidget {
  final Map<String, dynamic> business;

  const EditBusinessPage({Key? key, required this.business}) : super(key: key);

  @override
  State<EditBusinessPage> createState() => _EditBusinessPageState();
}

class _EditBusinessPageState extends State<EditBusinessPage> {
  bool _isLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  
  List<dynamic> _galleryImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business['name']);
    _descController = TextEditingController(text: widget.business['description']);
    
    // Cargar la lista unificada
    if (widget.business['images'] != null) {
      _galleryImages = List.from(widget.business['images']);
    }
  }

  String _buildFullUrl(String dbUrl) {
    if (dbUrl.startsWith('http')) return dbUrl;
    
    // Limpiar para asegurar format correcto y evitar doble slash
    String base = ApiService.baseUrl.replaceAll('/api', '');
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (!dbUrl.startsWith('/')) dbUrl = '/$dbUrl';
    
    return '$base$dbUrl';
  }

  Future<void> _uploadNewImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50, 
      maxWidth: 800,
      maxHeight: 800,
    );

    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await image.readAsBytes();
        var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/businesses/${widget.business['id']}/images'));
        
        final token = await ApiService.getToken();
        request.headers.addAll({
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        });

        request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name));

        final response = await request.send();
        if (response.statusCode == 201 || response.statusCode == 200) {
          final resData = await response.stream.bytesToString();
          final newImage = jsonDecode(resData);
          if (mounted) {
            setState(() {
               _galleryImages.add(newImage);
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto subida a la galería'), backgroundColor: Colors.green));
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir imagen al servidor.'), backgroundColor: Colors.red));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de red: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteImage(int index, int imageId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Borrar foto', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: const Text('¿Estás seguro de que deseas eliminar esta fotografía?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.60)))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      final token = await ApiService.getToken();
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/businesses/${widget.business['id']}/images/$imageId'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() => _galleryImages.removeAt(index));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto eliminada'), backgroundColor: Colors.green));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo borrar: ${response.statusCode}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTextData() async {
    setState(() => _isLoading = true);
    try {
      final textResponse = await ApiService.patch('/businesses/${widget.business['id']}', {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
      });

      if (textResponse.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detalles guardados exitosamente'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verifique los campos: ${textResponse.statusCode}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Editar Comercio', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
                  Text('Datos Generales', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: const InputDecoration(labelText: 'Nombre Comercio', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    style: const TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: const InputDecoration(labelText: 'Descripción', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
                  ),
                  const SizedBox(height: 24),
                  
                  // BOTÓN GUARDAR TEXTO
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black87),
                      onPressed: _saveTextData,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Modificaciones Teóricas', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // BOTÓN IR AL CATÁLOGO
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black87),
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsPage(business: widget.business)));
                      },
                      icon: const Icon(Icons.inventory),
                      label: const Text('Gestionar Productos de este Local', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24), height: 48),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Galería Activa', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                      IconButton(
                        onPressed: _uploadNewImage,
                        icon: const Icon(Icons.add_a_photo, color: Colors.greenAccent),
                        tooltip: 'Añadir nueva foto',
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Las fotos que agregues aquí se subirán al instante y aparecerán en tu vidriera.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.60), fontSize: 13)),
                  const SizedBox(height: 16),
                  
                  // GRID DINÁMICO
                  _galleryImages.isEmpty 
                    ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No hay fotos en galería.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)))))
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, // 4 columnas para que queden muy pequeñas y estéticas
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: _galleryImages.length,
                        itemBuilder: (context, index) {
                          final imgMap = _galleryImages[index];
                          final url = _buildFullUrl(imgMap['full_url'] ?? imgMap['url']);
                          final isPrimary = imgMap['is_primary'] == true || imgMap['is_primary'] == 1;

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: isPrimary ? Colors.orangeAccent : Theme.of(context).colorScheme.onSurface.withOpacity(0.24), width: isPrimary ? 2 : 1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(url, fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
                                    ),
                                  ),
                                ),
                              ),
                              // Botón de eliminar superpuesto
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _deleteImage(index, imgMap['id']),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                                  ),
                                ),
                              ),
                              if (isPrimary)
                                Positioned(
                                  bottom: 4, left: 4, right: 4,
                                  child: Container(
                                    color: Colors.black54,
                                    child: const Text('PORTADA', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 10, fontWeight: FontWeight.bold)),
                                  )
                                )
                            ],
                          );
                        },
                      ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
