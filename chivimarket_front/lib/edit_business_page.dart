import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ltlng;
import 'api_service.dart';
import 'main.dart'; // Para GlassContainer y Fondos
import 'products_page.dart';

class EditBusinessPage extends StatefulWidget {
  final Map<String, dynamic> business;

  EditBusinessPage({Key? key, required this.business}) : super(key: key);

  @override
  State<EditBusinessPage> createState() => _EditBusinessPageState();
}

class _EditBusinessPageState extends State<EditBusinessPage> {
  bool _isLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _addressController;
  
  String _modality = 'fisico';
  Timer? _debounce;
  final String _mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? 'FALTA_TOKEN';
  List<Map<String, dynamic>> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  double? _latitude;
  double? _longitude;
  final MapController _mapPreviewController = MapController();
  
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  
  // Variables estandarizadas de horarios
  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 18, minute: 0);
  final List<String> _daysOfWeek = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
  List<String> _selectedDays = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie'];

  List<dynamic> _galleryImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business['name']);
    _descController = TextEditingController(text: widget.business['description'] ?? '');
    _modality = widget.business['modality'] ?? 'fisico';
    _addressController = TextEditingController(text: widget.business['address'] ?? '');
    
    _phoneController = TextEditingController(text: widget.business['phone'] ?? '');
    _emailController = TextEditingController(text: widget.business['email'] ?? '');
    _websiteController = TextEditingController(text: widget.business['website'] ?? '');
    
    final meta = widget.business['metadata'] ?? {};
    _facebookController = TextEditingController(text: meta['facebook'] ?? '');
    _instagramController = TextEditingController(text: meta['instagram'] ?? '');

    if (widget.business['latitude'] != null) {
      _latitude = double.tryParse(widget.business['latitude'].toString());
    }
    if (widget.business['longitude'] != null) {
      _longitude = double.tryParse(widget.business['longitude'].toString());
    }
    
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

  Future<void> _searchMapboxAddress(String query) async {
    if (query.length < 3) {
      setState(() => _addressSuggestions = []);
      return;
    }
    setState(() => _isSearchingAddress = true);
    try {
      final String url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json?access_token=$_mapboxToken&bbox=-60.0768,-34.9392,-59.9576,-34.8471&proximity=-60.0172,-34.8953';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'] ?? [];
        if (mounted) {
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto subida a la galería'), backgroundColor: Colors.green));
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir imagen al servidor.'), backgroundColor: Colors.red));
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
        backgroundColor: Color(0xFF1E293B),
        title: Text('Borrar foto', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('¿Estás seguro de que deseas eliminar esta fotografía?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.60)))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto eliminada'), backgroundColor: Colors.green));
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
        'modality': _modality,
        'address': _modality == 'online' ? null : _addressController.text,
        'latitude': _modality == 'online' ? null : _latitude,
        'longitude': _modality == 'online' ? null : _longitude,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'metadata': {
          'facebook': _facebookController.text.trim(),
          'instagram': _instagramController.text.trim(),
          'hours': '${_selectedDays.join(', ')} - ${_openTime.hour.toString().padLeft(2, '0')}:${_openTime.minute.toString().padLeft(2, '0')} a ${_closeTime.hour.toString().padLeft(2, '0')}:${_closeTime.minute.toString().padLeft(2, '0')}'
        }
      });

      if (textResponse.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Detalles guardados exitosamente'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          String errorMessage = 'Verifique los campos: ${textResponse.statusCode}';
          try {
            final decoded = jsonDecode(textResponse.body);
            if (decoded['message'] != null) {
              errorMessage = decoded['message'];
            } else if (decoded is Map) {
              errorMessage = "Error: ${decoded.values.first[0]}";
            }
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent));
        }
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
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface))
            : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos Generales', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                  SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(labelText: 'Nombre Comercio', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(labelText: 'Descripción', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
                  ),
                  SizedBox(height: 16),
                  
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
                  const SizedBox(height: 32),

                  Text('Contacto y Horarios', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                  SizedBox(height: 16),
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
                  ),
                  const SizedBox(height: 24),
                  SizedBox(height: 16),
                  
                  if (_modality != 'online') ...[
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
                                    flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom, // Evita scroll vertical sin querer
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
                                        alignment: Alignment.topCenter,
                                        child: Icon(Icons.location_on, color: Colors.redAccent, size: 40),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FloatingActionButton.small(
                                      heroTag: 'mapZoomInEdit',
                                      backgroundColor: Theme.of(context).colorScheme.surface,
                                      onPressed: () {
                                        final currentZoom = _mapPreviewController.camera.zoom;
                                        _mapPreviewController.move(_mapPreviewController.camera.center, currentZoom + 1);
                                      },
                                      child: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                                    ),
                                    const SizedBox(height: 4),
                                    FloatingActionButton.small(
                                      heroTag: 'mapZoomOutEdit',
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
                  SizedBox(height: 24),
                  
                  // BOTÓN GUARDAR TEXTO
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black87),
                      onPressed: _saveTextData,
                      icon: Icon(Icons.save),
                      label: Text('Guardar Modificaciones Teóricas', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // BOTÓN IR AL CATÁLOGO
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black87),
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsPage(business: widget.business)));
                      },
                      icon: Icon(Icons.inventory),
                      label: Text('Gestionar Productos de este Local', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),

                  Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24), height: 48),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Galería Activa', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                      IconButton(
                        onPressed: _uploadNewImage,
                        icon: Icon(Icons.add_a_photo, color: Colors.greenAccent),
                        tooltip: 'Añadir nueva foto',
                      )
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Las fotos que agregues aquí se subirán al instante y aparecerán en tu vidriera.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.60), fontSize: 13)),
                  SizedBox(height: 16),
                  
                  // GRID DINÁMICO
                  _galleryImages.isEmpty 
                    ? Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No hay fotos en galería.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)))))
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                                      errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
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
                                    decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: Icon(Icons.delete, color: Colors.redAccent, size: 16),
                                  ),
                                ),
                              ),
                              if (isPrimary)
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
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

