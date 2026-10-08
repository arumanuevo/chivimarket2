import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ltlng;
import 'api_service.dart';
import 'main.dart'; // Para reutilizar GlassContainer y AnimatedGradientBackground

class CreateBusinessPage extends StatefulWidget {
  CreateBusinessPage({Key? key}) : super(key: key);

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
  
  // Contacto & Redes
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  
  // Variables estandarizadas de horarios
  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 18, minute: 0);
  final List<String> _daysOfWeek = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
  List<String> _selectedDays = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie'];
  
  // Geolocation parameters Mapbox
  Timer? _debounce;
  // Carga desde el archivo .env creado localmente!
  final String _mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? 'FALTA_TOKEN';
  List<Map<String, dynamic>> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  double? _latitude;
  double? _longitude;
  final MapController _mapPreviewController = MapController();
  
  // Categoría Principal
  String _selectedCategory = '1';

  // Constructor dinámico de Metadata (Elasticidad real)
  // Almacenaremos propiedades como {"Atención 24hs": true, "Tipo de Especialidad": "Electricista"}
  final Map<String, dynamic> _customMetadata = {};
  
  // Controladores para agregar nueva propiedad a mano
  final _customFeatureKeyController = TextEditingController();
  final _customFeatureValueController = TextEditingController();
  String _customFeatureType = 'Booleano (Si/No)'; // O 'Texto'

  // Fotografías en preparación para subir (Usamos XFile para compatibilidad Multiplataforma (Web/Móvil))
  final ImagePicker _picker = ImagePicker();
  List<XFile> _pendingImages = [];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50, 
      maxWidth: 800,
      maxHeight: 800,
    );
    if (image != null) {
      setState(() => _pendingImages.add(image));
    }
  }

  void _removePendingImage(int index) {
    setState(() => _pendingImages.removeAt(index));
  }

  Future<void> _searchMapboxAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _addressSuggestions = []);
      return;
    }
    
    setState(() => _isSearchingAddress = true);
    
    final String queryConChivilcoy = "$query, Chivilcoy";
    final String bbox = "-60.1544,-34.9961,-59.8234,-34.8063"; // Chivilcoy limit
    
    final String url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(queryConChivilcoy)}.json'
        '?bbox=$bbox'
        '&proximity=-60.0167,-34.8997'
        '&country=AR'
        '&fuzzyMatch=true'
        '&autocomplete=true'
        '&access_token=$_mapboxToken'
        '&language=es';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null) {
          final List<dynamic> features = data['features'];
          setState(() {
            _addressSuggestions = features.map((feature) {
              return {
                'place_name': feature['place_name'] as String,
                'lat': (feature['geometry']['coordinates'][1] as num).toDouble(),
                'lng': (feature['geometry']['coordinates'][0] as num).toDouble(),
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print("Mapbox error: $e");
    } finally {
      if (mounted) setState(() => _isSearchingAddress = false);
    }
  }

  void _onAddressChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchMapboxAddress(value);
    });
  }

  Future<void> _submitBusiness() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/businesses', {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'modality': _modality,
        'address': _modality == 'online' ? null : _addressController.text,
        'latitude': _modality == 'online' ? null : _latitude,
        'longitude': _modality == 'online' ? null : _longitude,
        'categories': [int.parse(_selectedCategory)],
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'metadata': {
          'facebook': _facebookController.text.trim(),
          'instagram': _instagramController.text.trim(),
          'hours': '${_selectedDays.join(', ')} - ${_openTime.hour.toString().padLeft(2, '0')}:${_openTime.minute.toString().padLeft(2, '0')} a ${_closeTime.hour.toString().padLeft(2, '0')}:${_closeTime.minute.toString().padLeft(2, '0')}',
          ..._customMetadata
        }
      });

      if (response.statusCode == 201) {
        
        // 2. Si el texto se creó y nos devuelve el ID, subimos las imágenes
        final createdBusiness = jsonDecode(response.body);
        final businessId = createdBusiness['id'];

        bool allImagesUploaded = true;
        
        // Subimos las fotos en memoria una a una directo al controlador de la Galería
        for (int i = 0; i < _pendingImages.length; i++) {
          final bytes = await _pendingImages[i].readAsBytes();
          List<http.MultipartFile> singleMultipart = [
            http.MultipartFile.fromBytes('image', bytes, filename: _pendingImages[i].name)
          ];
          
          var imageResponse = await ApiService.postMultipart(
            '/businesses/$businessId/images', 
            <String, String>{}, 
            singleMultipart
          );
          
          if (imageResponse.statusCode != 200 && imageResponse.statusCode != 201) {
             allImagesUploaded = false;
          }
        }

        if (mounted) {
          if (allImagesUploaded && _pendingImages.isNotEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡Tienda Creada Exitosamente con Galería!'), backgroundColor: Colors.green));
          } else if (_pendingImages.isNotEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tienda creada, pero fallaron algunas fotos.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)), backgroundColor: Colors.orange));
          } else {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡Tienda Creada Exitosamente!'), backgroundColor: Colors.green));
          }
          Navigator.pop(context, true); // Volver al Dashboard
        }
      } else {
        if (mounted) {
          String errorMessage = 'Ocurrió un error inesperado al procesar la solicitud.';
          try {
            final decoded = jsonDecode(response.body);
            if (decoded['message'] != null) {
              errorMessage = decoded['message'];
            } else if (decoded is Map) {
              errorMessage = "Por favor completa correctamente los campos: ${decoded.values.first[0]}";
            }
          } catch (_) {}
          
          if (response.statusCode == 403) {
            errorMessage = 'Límite de negocios alcanzado. Por favor sube de plan para crear más tiendas.';
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 5)));
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
        title: Text('Crear Nuevo Negocio', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
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
                    onSurface: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                child: Stepper(
                  type: MediaQuery.of(context).size.width > 600 ? StepperType.horizontal : StepperType.vertical,
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep == 0) {
                      if (_nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('El nombre comercial es obligatorio', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)), backgroundColor: Colors.red));
                        return;
                      }
                      setState(() => _currentStep += 1);
                    } else if (_currentStep == 1) {
                      // Validación de contacto se puede omitir porque son opcionales
                      setState(() => _currentStep += 1);
                    } else if (_currentStep == 2) {
                      if (_modality != 'online' && _addressController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('La dirección es obligatoria', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)), backgroundColor: Colors.red));
                        return;
                      }
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
                            onPressed: _isLoading ? null : details.onStepContinue,
                            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onSurface),
                            child: _isLoading && _currentStep == 2 
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface, strokeWidth: 2))
                              : Text(_currentStep == 2 ? 'Crear Negocio' : 'Continuar'),
                          ),
                          if (_currentStep > 0)
                            TextButton(
                              onPressed: _isLoading ? null : details.onStepCancel, 
                              child: Text('Atrás', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70)))
                            ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    // PASO 1: DATOS BÁSICOS
                    Step(
                      title: Text('Perfil', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface)),
                      isActive: _currentStep >= 0,
                      content: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(labelText: 'Nombre Comercial', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(labelText: 'Descripción del rubro', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
                          ),
                          SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            value: _modality,
                            dropdownColor: Color(0xFF1E293B),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(labelText: 'Modalidad de Servicio', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
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
                    // PASO 2: CONTACTO Y HORARIOS
                    Step(
                      title: Text('Contacto', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface)),
                      isActive: _currentStep >= 1,
                      content: Column(
                        children: [
                          TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Teléfono / WhatsApp', prefixIcon: Icon(Icons.phone, color: Colors.greenAccent)), style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 12),
                          TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email Comercial', prefixIcon: Icon(Icons.email, color: Colors.blueAccent)), style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 12),
                          TextField(controller: _facebookController, decoration: InputDecoration(labelText: 'Página de Facebook', prefixIcon: Icon(Icons.facebook, color: Colors.blue)), style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 12),
                          TextField(controller: _instagramController, decoration: InputDecoration(labelText: 'Instagram (URL o @usuario)', prefixIcon: Icon(Icons.camera_alt, color: Colors.pinkAccent)), style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 16),
                          
                          // Selector de Horarios
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Días de Apertura:', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                                Wrap(
                                  spacing: 4,
                                  children: _daysOfWeek.map((day) {
                                    final isSelected = _selectedDays.contains(day);
                                    return ChoiceChip(
                                      label: Text(day, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
                                      selected: isSelected,
                                      selectedColor: Colors.orangeAccent,
                                      backgroundColor: Colors.transparent,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedDays.add(day);
                                          } else {
                                            _selectedDays.remove(day);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        Text('Apertura', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black45, foregroundColor: Colors.white),
                                          icon: Icon(Icons.sunny, size: 16, color: Colors.yellowAccent),
                                          label: Text(_openTime.format(context)),
                                          onPressed: () async {
                                            final t = await showTimePicker(context: context, initialTime: _openTime);
                                            if (t != null) setState(() => _openTime = t);
                                          },
                                        )
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text('Cierre', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black45, foregroundColor: Colors.white),
                                          icon: Icon(Icons.nightlight_round, size: 16, color: Colors.indigoAccent),
                                          label: Text(_closeTime.format(context)),
                                          onPressed: () async {
                                            final t = await showTimePicker(context: context, initialTime: _closeTime);
                                            if (t != null) setState(() => _closeTime = t);
                                          },
                                        )
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                          )

                        ],
                      ),
                    ),
                    
                    
                    // PASO 2: UBICACIÓN Y CATEGORÍA
                    Step(
                      title: Text('Datos y Ubicación', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface)),
                      isActive: _currentStep >= 2,
                      content: Column(
                        children: [
                          if (_modality != 'online') ...[
                            Text('Busca tu dirección para geolocalizarte en Chivilcoy', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
                            SizedBox(height: 8),
                            TextField(
                              controller: _addressController,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              decoration: InputDecoration(
                                labelText: 'Dirección (Ej: Lavalle 194)', 
                                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70)),
                                suffixIcon: _isSearchingAddress 
                                    ? Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) 
                                    : Icon(Icons.location_searching, color: Theme.of(context).colorScheme.primary),
                              ),
                              onChanged: _onAddressChanged,
                            ),
                            if (_addressSuggestions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                ),
                                constraints: BoxConstraints(maxHeight: 200),
                                child: Material(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _addressSuggestions.length,
                                    itemBuilder: (context, index) {
                                      final suggestion = _addressSuggestions[index];
                                      return ListTile(
                                        leading: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                                        title: Text(suggestion['place_name'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                        onTap: () {
                                          setState(() {
                                            _addressController.text = suggestion['place_name'];
                                            _latitude = suggestion['lat'];
                                            _longitude = suggestion['lng'];
                                            _addressSuggestions.clear();
                                            FocusScope.of(context).unfocus(); // Cierra teclado
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            if (_latitude != null && _longitude != null) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    SizedBox(width: 4),
                                    Text('Dirección verificada (\u00B0 $_latitude, $_longitude)', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Stack(
                                    children: [
                                      FlutterMap(
                                        key: ValueKey('$_latitude-$_longitude'),
                                        mapController: _mapPreviewController,
                                        options: MapOptions(
                                          initialCenter: ltlng.LatLng(_latitude!, _longitude!),
                                          initialZoom: 15.0,
                                          interactionOptions: const InteractionOptions(
                                            flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom, // Permite mover y hacer pinch, limitando otras rotaciones
                                          ),
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=$_mapboxToken',
                                          ),
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: ltlng.LatLng(_latitude!, _longitude!),
                                                width: 40,
                                                height: 40,
                                                alignment: Alignment.topCenter, // Ajusta para que la punta del pin apunte a la coordenada
                                                child: Icon(Icons.location_on, color: Colors.redAccent, size: 40),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Controles de Acercamiento (+) y (-)
                                      Positioned(
                                        right: 8,
                                        bottom: 8,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FloatingActionButton.small(
                                              heroTag: 'mapZoomIn',
                                              backgroundColor: Theme.of(context).colorScheme.surface,
                                              onPressed: () {
                                                final currentZoom = _mapPreviewController.camera.zoom;
                                                _mapPreviewController.move(_mapPreviewController.camera.center, currentZoom + 1);
                                              },
                                              child: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                                            ),
                                            const SizedBox(height: 4),
                                            FloatingActionButton.small(
                                              heroTag: 'mapZoomOut',
                                              backgroundColor: Theme.of(context).colorScheme.surface,
                                              onPressed: () {
                                                final currentZoom = _mapPreviewController.camera.zoom;
                                                _mapPreviewController.move(_mapPreviewController.camera.center, currentZoom - 1);
                                              },
                                              child: Icon(Icons.remove, color: Theme.of(context).colorScheme.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                          if (_modality == 'online')
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Como seleccionaste Online, tu negocio buscará posicionarse sin limitación geográfica.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70), fontStyle: FontStyle.italic)),
                            ),
                          SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            dropdownColor: Color(0xFF1E293B),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(labelText: 'Categoría Principal', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
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
                      title: Text('Atributos y Fotos', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface)),
                      isActive: _currentStep >= 2,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Agrega características específicas de tu rubro:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
                          SizedBox(height: 16),
                          
                          // LISTA DE ATRIBUTOS AGREGADOS
                          if (_customMetadata.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: _customMetadata.entries.map((entry) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(entry.key, style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                                    subtitle: Text(entry.value is bool ? (entry.value ? 'Sí' : 'No') : entry.value.toString(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete, color: Colors.redAccent),
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
                            decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Añadir nueva característica', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                SizedBox(height: 12),
                                TextField(
                                  controller: _customFeatureKeyController,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  decoration: InputDecoration(labelText: 'Nombre (Ej: Pet Friendly, Wi-Fi)', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70), fontSize: 12)),
                                ),
                                SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _customFeatureType,
                                  dropdownColor: Color(0xFF1E293B),
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  decoration: InputDecoration(labelText: 'Tipo de Respuesta', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70), fontSize: 12)),
                                  items: const [
                                    DropdownMenuItem(value: 'Booleano (Si/No)', child: Text('Sí / No')),
                                    DropdownMenuItem(value: 'Texto', child: Text('Texto Libre')),
                                  ],
                                  onChanged: (value) => setState(() => _customFeatureType = value!),
                                ),
                                if (_customFeatureType == 'Texto') ...[
                                  SizedBox(height: 12),
                                  TextField(
                                    controller: _customFeatureValueController,
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                    decoration: InputDecoration(labelText: 'Valor (Ej: Fibra Óptica 100MB)', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70), fontSize: 12)),
                                  ),
                                ],
                                SizedBox(height: 16),
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
                                    icon: Icon(Icons.add, color: Colors.orangeAccent),
                                    label: Text('Agregar Etiqueta', style: TextStyle(color: Colors.orangeAccent)),
                                  ),
                                )
                              ],
                            ),
                          ),

                          Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24), height: 48),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Preparar Galería', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                              IconButton(
                                onPressed: _pickImage,
                                icon: Icon(Icons.add_a_photo, color: Colors.greenAccent),
                                tooltip: 'Añadir nueva foto',
                              )
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('Las fotos que agregues aquí se subirán al momento de pulsar Crear Tienda.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.60), fontSize: 13)),
                          SizedBox(height: 16),
                          
                          // GRID DINÁMICO
                          _pendingImages.isEmpty 
                            ? Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No hay fotos en preparación.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)))))
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4, 
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1,
                                ),
                                itemCount: _pendingImages.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: index == 0 ? Colors.orangeAccent : Theme.of(context).colorScheme.onSurface.withOpacity(0.24), width: index == 0 ? 2 : 1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            // kIsWeb previene el error usando network con la URL blob temporal
                                            child: kIsWeb 
                                                ? Image.network(_pendingImages[index].path, fit: BoxFit.cover)
                                                : Image.file(File(_pendingImages[index].path), fit: BoxFit.cover),
                                          ),
                                        ),
                                      ),
                                      // Botón de eliminar superpuesto
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removePendingImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                            child: Icon(Icons.delete, color: Colors.redAccent, size: 16),
                                          ),
                                        ),
                                      ),
                                      if (index == 0)
                                        Positioned(
                                          bottom: 4, left: 4, right: 4,
                                          child: Container(
                                            color: Colors.black54,
                                            child: Text('PORTADA', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 10, fontWeight: FontWeight.bold)),
                                          )
                                        )
                                    ],
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

