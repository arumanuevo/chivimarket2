import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import 'main.dart'; // Para reutilizar GlassContainer y AnimatedGradientBackground

class CreateBusinessPage extends StatefulWidget {
  const CreateBusinessPage({Key? key}) : super(key: key);

  @override
  State<CreateBusinessPage> createState() => _CreateBusinessPageState();
}

class _CreateBusinessPageState extends State<CreateBusinessPage> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Controladores y estados
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _modality = 'fisico'; // fisico, online, domicilio, mixto
  final _addressController = TextEditingController();
  
  // Categoría Principal
  String _selectedCategory = '1';

  // Constructor dinámico de Metadata (Elasticidad real)
  // Almacenaremos propiedades como {"Atención 24hs": true, "Tipo de Especialidad": "Electricista"}
  final Map<String, dynamic> _customMetadata = {};
  
  // Controladores para agregar nueva propiedad a mano
  final _customFeatureKeyController = TextEditingController();
  final _customFeatureValueController = TextEditingController();
  String _customFeatureType = 'Booleano (Si/No)'; // O 'Texto'

  // Fotografías (Máximo 4) - Usamos XFile para compatibilidad Multiplataforma (Web/Móvil)
  final ImagePicker _picker = ImagePicker();
  List<XFile?> _selectedImages = <XFile?>[null, null, null, null];

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50, 
      maxWidth: 800,
      maxHeight: 800,
    );
    if (image != null) {
      setState(() => _selectedImages[index] = image);
    }
  }

  Future<void> _submitBusiness() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/businesses', {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'modality': _modality,
        'address': _modality == 'online' ? null : _addressController.text,
        'categories': [int.parse(_selectedCategory)],
        'metadata': _customMetadata // <- Magia Elástica pura
      });

      if (response.statusCode == 201) {
        
        // 2. Si el texto se creó y nos devuelve el ID, subimos las imágenes
        final createdBusiness = jsonDecode(response.body);
        final businessId = createdBusiness['id'];

        List<http.MultipartFile> multipartFiles = [];
        for (int i = 0; i < _selectedImages.length; i++) {
          if (_selectedImages[i] != null) {
            String fieldName = (i == 0) ? 'cover_image' : 'imagen$i';
            final bytes = await _selectedImages[i]!.readAsBytes();
            multipartFiles.add(http.MultipartFile.fromBytes(
              fieldName,
              bytes,
              filename: _selectedImages[i]!.name,
            ));
          }
        }

        if (multipartFiles.isNotEmpty) {
           var imageResponse = await ApiService.postMultipart('/businesses/$businessId/update', {}, multipartFiles);
           if (imageResponse.statusCode != 200 && imageResponse.statusCode != 201) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tienda creada, pero falló la carga de fotos', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange));
           }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Tienda Creada Exitosamente con sus Fotos!'), backgroundColor: Colors.green));
          Navigator.pop(context, true); // Volver al Dashboard
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.statusCode}'), backgroundColor: Colors.red));
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
        title: Text('Crear Nuevo Negocio', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Theme(
                // Modificar el tema del Stepper para que luzca bien sobre fondo oscuro
                data: ThemeData(
                  canvasColor: Colors.transparent,
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Theme.of(context).colorScheme.primary,
                    onSurface: Colors.white,
                  ),
                ),
                child: Stepper(
                  type: MediaQuery.of(context).size.width > 600 ? StepperType.horizontal : StepperType.vertical,
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep == 0) {
                      if (_nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre comercial es obligatorio', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                        return;
                      }
                      setState(() => _currentStep += 1);
                    } else if (_currentStep == 1) {
                      if (_modality != 'online' && _addressController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La dirección es obligatoria', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                        return;
                      }
                      setState(() => _currentStep += 1);
                    } else {
                      _submitBusiness();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep -= 1);
                    }
                  },
                  controlsBuilder: (BuildContext context, ControlsDetails details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                            child: _isLoading && _currentStep == 2 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_currentStep == 2 ? 'Crear Negocio' : 'Continuar'),
                          ),
                          if (_currentStep > 0)
                            TextButton(onPressed: details.onStepCancel, child: const Text('Atrás', style: TextStyle(color: Colors.white70))),
                        ],
                      ),
                    );
                  },
                  steps: [
                    // PASO 1: DATOS BÁSICOS
                    Step(
                      title: Text('Perfil', style: GoogleFonts.outfit(color: Colors.white)),
                      isActive: _currentStep >= 0,
                      content: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Nombre Comercial', labelStyle: TextStyle(color: Colors.white70)),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Descripción del rubro', labelStyle: TextStyle(color: Colors.white70)),
                          ),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            value: _modality,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Modalidad de Servicio', labelStyle: TextStyle(color: Colors.white70)),
                            items: const [
                              DropdownMenuItem(value: 'fisico', child: Text('Local Físico (Presencial)')),
                              DropdownMenuItem(value: 'domicilio', child: Text('Servicio a Domicilio')),
                              DropdownMenuItem(value: 'online', child: Text('Puramente Online / Digital')),
                              DropdownMenuItem(value: 'mixto', child: Text('Mixto (Físico y Online)')),
                            ],
                            onChanged: (value) => setState(() => _modality = value!),
                          ),
                        ],
                      ),
                    ),
                    
                    // PASO 2: UBICACIÓN Y CATEGORÍA
                    Step(
                      title: Text('Datos y Ubicación', style: GoogleFonts.outfit(color: Colors.white)),
                      isActive: _currentStep >= 1,
                      content: Column(
                        children: [
                          if (_modality != 'online')
                            TextField(
                              controller: _addressController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'Dirección Completa', labelStyle: TextStyle(color: Colors.white70)),
                            ),
                          if (_modality == 'online')
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Como seleccionaste Online, tu negocio buscará posicionarse sin limitación geográfica.', style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                            ),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Categoría Principal', labelStyle: TextStyle(color: Colors.white70)),
                            items: const [
                              DropdownMenuItem(value: '1', child: Text('Gastronomía')),
                              DropdownMenuItem(value: '2', child: Text('Indumentaria y Moda')),
                              DropdownMenuItem(value: '3', child: Text('Servicios y Profesionales')),
                              DropdownMenuItem(value: '4', child: Text('Tecnología')),
                              DropdownMenuItem(value: '5', child: Text('Salud y Cuidado')),
                              DropdownMenuItem(value: '6', child: Text('Otro Rubro / General')),
                            ],
                            onChanged: (value) => setState(() => _selectedCategory = value!),
                          ),
                        ],
                      ),
                    ),

                    // PASO 3: ATRIBUTOS AD-HOC Y ELÁSTICOS (CONSTRUCTOR)
                    Step(
                      title: Text('Atributos y Fotos', style: GoogleFonts.outfit(color: Colors.white)),
                      isActive: _currentStep >= 2,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Agrega características específicas de tu rubro:', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 16),
                          
                          // LISTA DE ATRIBUTOS AGREGADOS
                          if (_customMetadata.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: _customMetadata.entries.map((entry) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(entry.key, style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                                    subtitle: Text(entry.value is bool ? (entry.value ? 'Sí' : 'No') : entry.value.toString(), style: const TextStyle(color: Colors.white)),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => setState(() => _customMetadata.remove(entry.key)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                          // FORMULARIO PARA AGREGAR NUEVO ATRIBUTO
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Añadir nueva característica', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _customFeatureKeyController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(labelText: 'Nombre (Ej: Pet Friendly, Wi-Fi)', labelStyle: TextStyle(color: Colors.white70, fontSize: 12)),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _customFeatureType,
                                  dropdownColor: const Color(0xFF1E293B),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(labelText: 'Tipo de Respuesta', labelStyle: TextStyle(color: Colors.white70, fontSize: 12)),
                                  items: const [
                                    DropdownMenuItem(value: 'Booleano (Si/No)', child: Text('Sí / No')),
                                    DropdownMenuItem(value: 'Texto', child: Text('Texto Libre')),
                                  ],
                                  onChanged: (value) => setState(() => _customFeatureType = value!),
                                ),
                                if (_customFeatureType == 'Texto') ...[
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _customFeatureValueController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(labelText: 'Valor (Ej: Fibra Óptica 100MB)', labelStyle: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final key = _customFeatureKeyController.text.trim();
                                      if (key.isNotEmpty) {
                                        setState(() {
                                          _customMetadata[key] = _customFeatureType == 'Booleano (Si/No)' ? true : _customFeatureValueController.text.trim();
                                          _customFeatureKeyController.clear();
                                          _customFeatureValueController.clear();
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.add, color: Colors.orangeAccent),
                                    label: const Text('Agregar Etiqueta', style: TextStyle(color: Colors.orangeAccent)),
                                  ),
                                )
                              ],
                            ),
                          ),

                          Text('Fotografías (Primera es Portada)', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4, 
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
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white30),
                                  ),
                                  child: _selectedImages[index] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: kIsWeb 
                                              ? Image.network(_selectedImages[index]!.path, fit: BoxFit.cover)
                                              : Image.file(File(_selectedImages[index]!.path), fit: BoxFit.cover),
                                        )
                                      : const Icon(Icons.add_a_photo, color: Colors.white54, size: 24),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
