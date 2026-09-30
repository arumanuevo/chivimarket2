import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'api_service.dart';
import 'main.dart'; 

class ProductsPage extends StatefulWidget {
  final Map<String, dynamic> business;

  const ProductsPage({Key? key, required this.business}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _isLoading = true;
  List<dynamic> _products = [];
  List<dynamic> _categories = [];

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final catRes = await ApiService.get('/product-categories');
      if (catRes.statusCode == 200) {
        _categories = jsonDecode(catRes.body);
      }
      
      final prodRes = await ApiService.get('/businesses/${widget.business['id']}/products');
      if (prodRes.statusCode == 200) {
        _products = jsonDecode(prodRes.body);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error red: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProduct(Map<String, dynamic>? existingProduct) async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _stockCtrl.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete todos los campos obligatorios'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
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
      if (existingProduct == null) {
         // Crear NUEVO producto
         res = await ApiService.post('/businesses/${widget.business['id']}/products', payload);
      } else {
         // EDITAR producto (Ruta Shallow)
         res = await ApiService.patch('/products/${existingProduct['id']}', payload);
      }

      if (res.statusCode == 201 || res.statusCode == 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(existingProduct == null ? 'Producto creado' : 'Producto actualizado'), backgroundColor: Colors.green));
        Navigator.pop(context); // Cierra el modal
        _fetchData();
      } else {
         final error = jsonDecode(res.body);
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error['message'] ?? 'Falló guardado'), backgroundColor: Colors.red));
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
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Eliminar Producto', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que deseas eliminar permanentemente este producto del catálogo?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
       // Shallow route DELETE /products/{id} (Dado de baja temporal o físico según tu lógica backend)
       final res = await ApiService.delete('/products/$productId');
       if (res.statusCode == 200 || res.statusCode == 204) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto eliminado'), backgroundColor: Colors.redAccent));
          _fetchData();
       } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo borrar: ${res.statusCode}'), backgroundColor: Colors.orange));
       }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showProductModal({Map<String, dynamic>? product}) {
    // Si viene producto, es Edición. Precargar.
    if (product != null) {
      _nameCtrl.text = product['name'] ?? '';
      _descCtrl.text = product['description'] ?? '';
      _priceCtrl.text = product['price'].toString();
      _stockCtrl.text = product['stock'].toString();
      _selectedCategory = product['category_id']?.toString();
    } else {
      _nameCtrl.clear();
      _descCtrl.clear();
      _priceCtrl.clear();
      _stockCtrl.clear();
      _selectedCategory = null;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product == null ? 'Nuevo Producto' : 'Editar Producto', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Nombre del Producto', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                       Expanded(
                         child: TextField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Precio (\$)', labelStyle: TextStyle(color: Colors.white70)),
                          ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: TextField(
                            controller: _stockCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Stock Inicial', labelStyle: TextStyle(color: Colors.white70)),
                          ),
                       ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Categoría', labelStyle: TextStyle(color: Colors.white70)),
                    items: _categories.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Descripción corta', labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black87),
                        onPressed: () => _saveProduct(product),
                        child: Text(product == null ? 'Guardar' : 'Actualizar', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Catálogo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero
                ),
                onPressed: () => _showProductModal(product: null), // NUEVO PRODUCTO
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          )
        ],
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _products.isEmpty 
               ? Center(child: Text('Aún no tienes productos.\nToca "Nuevo" arriba a la derecha.', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16)))
               : ListView.builder(
                   padding: const EdgeInsets.all(16),
                   itemCount: _products.length,
                   itemBuilder: (ctx, index) {
                     final p = _products[index];
                     return Card(
                        color: Colors.white.withOpacity(0.1),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                      Text(p['name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                                      const SizedBox(height: 6),
                                      Text('Precio: \$${p['price']}  •  Stock: ${p['stock']}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(p['description'] ?? 'Sin descripción', style: const TextStyle(color: Colors.white60)),
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
