import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  
  // Opciones de Metadata ad-hoc basadas en el nicho (Por ahora simulan Veterinaria/Servicios)
  bool _isOpen24h = false;
  bool _hasDelivery = false;
  String _selectedCategory = '1';

  Future<void> _submitBusiness() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/businesses', {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'modality': _modality,
        'address': _modality == 'online' ? null : _addressController.text,
        'categories': [int.parse(_selectedCategory)],
        'metadata': {
          'open_24h': _isOpen24h,
          'has_delivery': _hasDelivery,
        }
      });

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Tienda Creada Exitosamente!'), backgroundColor: Colors.green));
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
                    if (_currentStep < 2) {
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
                              DropdownMenuItem(value: '4', child: Text('Tecnología')),
                              DropdownMenuItem(value: '3', child: Text('Servicios y Profesionales')),
                              DropdownMenuItem(value: '5', child: Text('Salud y Cuidado')),
                            ],
                            onChanged: (value) => setState(() => _selectedCategory = value!),
                          ),
                        ],
                      ),
                    ),

                    // PASO 3: ATRIBUTOS AD-HOC Y ELÁSTICOS
                    Step(
                      title: Text('Servicios Extra', style: GoogleFonts.outfit(color: Colors.white)),
                      isActive: _currentStep >= 2,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estos parámetros se guardarán dinámicamente en tu perfil JSON:', style: TextStyle(color: Colors.orangeAccent)),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('¿Ofrece cobertura de 24 horas?', style: TextStyle(color: Colors.white)),
                            value: _isOpen24h,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (bool value) => setState(() => _isOpen24h = value),
                          ),
                          SwitchListTile(
                            title: const Text('¿Tiene equipo de Delivery/Envío?', style: TextStyle(color: Colors.white)),
                            value: _hasDelivery,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (bool value) => setState(() => _hasDelivery = value),
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
