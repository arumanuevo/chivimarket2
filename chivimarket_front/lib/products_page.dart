import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class ProductsPage extends StatefulWidget {
  final Map<String, dynamic> business;

  const ProductsPage({Key? key, required this.business}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  String? _selectedCategory;
  
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final resProds = await ApiService.get('/businesses/${widget.business['id']}/products');
      final resCats = await ApiService.get('/business-categories');

      if (resProds.statusCode == 200 && resCats.statusCode == 200) {
        if (mounted) setState(() {
          _products = jsonDecode(resProds.body);
          _categories = jsonDecode(resCats.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  void _showProductModal({Map<String, dynamic>? product}) {
    if (product != null) {
      _nameCtrl.text = product['name'];
      _descCtrl.text = product['description'] ?? '';
      _priceCtrl.text = product['price'].toString();
      _stockCtrl.text = product['stock'].toString();
      _selectedCategory = product['category_id']?.toString();
    } else {
      _nameCtrl.clear();
      _descCtrl.clear();
      _priceCtrl.clear();
      _stockCtrl.clear();
      _selectedCategory = _categories.isNotEmpty ? _categories.first['id'].toString() : null;
    }
    
    _selectedImages.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(product == null ? 'Nuevo Producto' : 'Editar Producto', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 16),
                      TextFormField(controller: _nameCtrl, style: TextStyle(color: Theme.of(context).colorScheme.onSurface), decoration: const InputDecoration(labelText: 'Nombre del Producto')),
                      const SizedBox(height: 12),
                      TextFormField(controller: _descCtrl, style: TextStyle(color: Theme.of(context).colorScheme.onSurface), maxLines: 2, decoration: const InputDecoration(labelText: 'Descripción')),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _priceCtrl, style: TextStyle(color: Theme.of(context).colorScheme.onSurface), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio (\$)'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _stockCtrl, style: TextStyle(color: Theme.of(context).colorScheme.onSurface), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock (Ej: 10)'))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Categoría'),
                        items: _categories.map((c) => DropdownMenuItem<String>(value: c['id'].toString(), child: Text(c['name'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface)))).toList(),
                        onChanged: (val) => setStateModal(() => _selectedCategory = val),
                      ),
                      const SizedBox(height: 16),
                      
                      // Seleccion de fotos
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () async {
                            await _pickImages();
                            setStateModal(() {});
                          },
                          icon: Icon(Icons.add_a_photo, color: Theme.of(context).colorScheme.primary),
                          label: Text('Añadir fotos (Max según plan)', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        )
                      ),
                      if (_selectedImages.isNotEmpty)
                        Container(
                          height: 80,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, i) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(image: FileImage(_selectedImages[i]), fit: BoxFit.cover)
                                    ),
                                  ),
                                  Positioned(
                                    right: 4, top: 4,
                                    child: GestureDetector(
                                      onTap: () => setStateModal(() => _selectedImages.removeAt(i)),
                                      child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                                    )
                                  )
                                ],
                              );
                            },
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _saveProduct(product),
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Guardar Producto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _saveProduct(Map<String, dynamic>? existingProduct) async {
    if (!_formKey.currentState!.validate()) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      final payload = {
        'name': _nameCtrl.text,
        'description': _descCtrl.text,
        'price': double.tryParse(_priceCtrl.text) ?? 0.0,
        'stock': int.tryParse(_stockCtrl.text) ?? 0,
        'category_id': int.parse(_selectedCategory!),
        'is_active': true
      };

      http.Response res;
      int productId = 0;

      if (existingProduct == null) {
         res = await ApiService.post('/businesses/${widget.business['id']}/products', payload);
      } else {
         res = await ApiService.patch('/products/${existingProduct['id']}', payload);
         productId = existingProduct['id'];
      }

      if (res.statusCode == 201 || res.statusCode == 200) {
        if (existingProduct == null) {
           final data = jsonDecode(res.body);
           productId = data['id'];
        }

        // Subir imagenes si hay
        if (_selectedImages.isNotEmpty && productId != 0) {
            String? token = await ApiService.getToken();
            for (var fn in _selectedImages) {
               var req = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/products/$productId/images'));
               req.headers['Authorization'] = 'Bearer $token';
               req.headers['Accept'] = 'application/json';
               req.files.add(await http.MultipartFile.fromPath('image', fn.path));
               req.fields['is_primary'] = 'true';
               
               var response = await req.send();
               if (response.statusCode == 403) {
                  // Limites de plan
                  final rb = await response.stream.bytesToString();
                  final data = jsonDecode(rb);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Límite alcanzado'), backgroundColor: Colors.orange));
                  break; // Parar de subir mas fotos
               }
            }
        }

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(existingProduct == null ? 'Producto creado exitosamente' : 'Producto actualizado exitosamente'), backgroundColor: Colors.green));
        Navigator.pop(context); // Cierra modal
        _fetchData();
      } else {
         final error = jsonDecode(res.body);
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error['message'] ?? 'Falló el guardado'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(int productId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Eliminar Producto', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('¿Estás seguro de que deseas eliminar permanentemente este producto del catálogo?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
        ],
      )
    ) ?? false;

    if (!confirm) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      final res = await ApiService.delete('/products/$productId');
      if (res.statusCode == 200 || res.statusCode == 204) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto eliminado'), backgroundColor: Colors.green));
        _fetchData();
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error eliminando producto'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de red'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Productos de ${widget.business['name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          IconButton(icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary), onPressed: () => _showProductModal())
        ],
      ),
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : (_products.isEmpty 
               ? Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.inventory_2_outlined, size: 80, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                       const SizedBox(height: 16),
                       Text('Aún no tienes productos.\n¡Empieza a agregar stock!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.60))),
                     ],
                   ),
                 )
               : ListView.builder(
                   padding: const EdgeInsets.all(16),
                   itemCount: _products.length,
                   itemBuilder: (ctx, index) {
                     final p = _products[index];
                     return Card(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
                        child: InkWell( // Tap para editar
                          onTap: () => _showProductModal(product: p),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, fontSize: 18)),
                                      const SizedBox(height: 6),
                                      Text('Precio: \$${p['price']}  •  Stock: ${p['stock']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(p['description'] ?? 'Sin descripción', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.60))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _deleteProduct(p['id']),
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Eliminar Producto',
                                ),
                              ],
                            ),
                          ),
                        ),
                     );
                   }
                 )
        ),
      ),
    );
  }
}
