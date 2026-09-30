import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'api_service.dart';
import 'main.dart'; // AnimatedGradientBackground y GlassContainer

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
      // 1. Obtener categorias para combobox 
      final catRes = await ApiService.get('/product-categories');
      if (catRes.statusCode == 200) {
        _categories = jsonDecode(catRes.body);
      }
      
      // 2. Obtener productos de ESTE negocio
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

  Future<void> _createProduct() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _stockCtrl.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete todos los campos obligatorios'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('/businesses/${widget.business['id']}/products', {
        'name': _nameCtrl.text,
        'description': _descCtrl.text,
        'price': double.tryParse(_priceCtrl.text) ?? 0.0,
        'stock': int.tryParse(_stockCtrl.text) ?? 0,
        'category_id': int.parse(_selectedCategory!),
        'is_active': true
      });

      if (res.statusCode == 201) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto creado'), backgroundColor: Colors.green));
        _nameCtrl.clear();
        _descCtrl.clear();
        _priceCtrl.clear();
        _stockCtrl.clear();
        _selectedCategory = null;
        Navigator.pop(context); // Cierra el modal
        _fetchData();
      } else {
         final error = jsonDecode(res.body);
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error['message'] ?? 'Falló validación'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddProductModal() {
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
                  Text('Nuevo Producto', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
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
                            decoration: const InputDecoration(labelText: 'Stock', labelStyle: TextStyle(color: Colors.white70)),
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
                        onPressed: _createProduct,
                        child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
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
                onPressed: _showAddProductModal,
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
               ? Center(child: Text('Aún no tienes productos.\nToca "Nuevo" para empezar.', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16)))
               : ListView.builder(
                   padding: const EdgeInsets.all(16),
                   itemCount: _products.length,
                   itemBuilder: (ctx, index) {
                     final p = _products[index];
                     return Card(
                        color: Colors.white.withOpacity(0.1),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(p['name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Precio: \$${p['price']}  •  Stock: ${p['stock']}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(p['description'] ?? 'Sin descripción', style: const TextStyle(color: Colors.white60)),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.inventory_2, color: Colors.white30),
                        ),
                     );
                   }
                 )
        ),
      ),
    );
  }
}
