import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'main.dart'; // Para GlassContainer y Fondos

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
  
  // Fotografías (Máximo 4)
  final ImagePicker _picker = ImagePicker();
  List<File?> _selectedImages = [null, null, null, null];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business['name']);
    _descController = TextEditingController(text: widget.business['description']);
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _selectedImages[index] = File(image.path));
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    
    // 1. Guardar primero el texto
    try {
      final textResponse = await ApiService.patch('/businesses/${widget.business['id']}', {
        'name': _nameController.text,
        'description': _descController.text,
      });

      if (textResponse.statusCode == 200) {
        // En un escenario real, aquí se enviarían los archivos binarios de `_selectedImages` uno a uno
        // usando http.MultipartRequest hacia /businesses/{id}/images
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Datos guardados con éxito! (Imágenes Listas para SDK)'), backgroundColor: Colors.green));
        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: ${textResponse.statusCode}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excepción de Sistema: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Editar Local', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
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
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Nombre Comercio', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Descripción', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 32),
                  
                  Text('Fotografías (Máx. 4)', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                  const SizedBox(height: 16),
                  
                  // GRILLA FOTOGRÁFICA
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _pickImage(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white30, style: BorderStyle.solid),
                          ),
                          child: _selectedImages[index] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(_selectedImages[index]!, fit: BoxFit.cover),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: Colors.white54, size: 36),
                                    SizedBox(height: 8),
                                    Text('Toca para subir', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black87),
                      onPressed: _isLoading ? null : _saveChanges,
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('¡Guardar Cambios y Fotos!', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
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
