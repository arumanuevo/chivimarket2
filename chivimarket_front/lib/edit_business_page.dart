import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
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
  
  // Fotografías (Máximo 4) - Usamos XFile para compatibilidad Multiplataforma (Web/Móvil)
  final ImagePicker _picker = ImagePicker();
  List<XFile?> _selectedImages = <XFile?>[null, null, null, null];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business['name']);
    _descController = TextEditingController(text: widget.business['description']);
  }

  Future<void> _pickImage(int index) async {
    // PROTECCIÓN DE RECURSOS: Forzamos reducción masiva de calidad y tamaño (máx 800px)
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50, // 50% de calidad JPEG
      maxWidth: 800,
      maxHeight: 800,
    );
    if (image != null) {
      setState(() => _selectedImages[index] = image);
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
        
        // 2. Subir las imágenes si hay alguna seleccionada
        List<http.MultipartFile> multipartFiles = [];
        
        for (int i = 0; i < _selectedImages.length; i++) {
          if (_selectedImages[i] != null) {
            String fieldName = (i == 0) ? 'cover_image' : 'imagen$i';
            // Magia Web: Leemos los bytes crudos porque en Chrome no existen las rutas absolutas de disco
            final bytes = await _selectedImages[i]!.readAsBytes();
            multipartFiles.add(http.MultipartFile.fromBytes(
              fieldName,
              bytes,
              filename: _selectedImages[i]!.name,
            ));
          }
        }

        if (multipartFiles.isNotEmpty) {
           // Hacemos el poste multipar a Laravel a tu ruta POST nativa /update
           var imageResponse = await ApiService.postMultipart(
             '/businesses/${widget.business['id']}/update', 
             {}, 
             multipartFiles
           );
           
           if (imageResponse.statusCode == 200 || imageResponse.statusCode == 201) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos y Fotos guardados DPM!'), backgroundColor: Colors.green));
           } else {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Textos guardados, pero fallaron las fotos.'), backgroundColor: Colors.orange));
           }
        } else {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Textos actualizados!'), backgroundColor: Colors.green));
        }

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
                  
                  // GRILLA FOTOGRÁFICA MÁS PEQUEÑA (crossAxisCount: 4)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // 4 columnas para que se vean como pequeñas miniaturas
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
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
                                  // Compatible tanto con Móvil (archivo crudo) como con la Web (Url dinámica de memoria Blob)
                                  child: kIsWeb 
                                      ? Image.network(_selectedImages[index]!.path, fit: BoxFit.cover)
                                      : Image.file(File(_selectedImages[index]!.path), fit: BoxFit.cover),
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
