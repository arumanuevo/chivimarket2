import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'api_service.dart';
import 'main.dart'; 
import 'edit_business_page.dart'; 
import 'products_page.dart';
import 'business_promotions_page.dart';

class MyBusinessesPage extends StatefulWidget {
  MyBusinessesPage({Key? key}) : super(key: key);

  @override
  State<MyBusinessesPage> createState() => _MyBusinessesPageState();
}

class _MyBusinessesPageState extends State<MyBusinessesPage> {
  List<dynamic> _myBusinesses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyBusinesses();
  }

  Future<void> _fetchMyBusinesses() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => _myBusinesses = data['businesses'] ?? []);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Mis Locales', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: _isLoading && _myBusinesses.isEmpty
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface))
              : _myBusinesses.isEmpty
                  ? Center(
                      child: Text('Aún no tienes negocios.\n¡Crea uno desde el Dashboard!', 
                        textAlign: TextAlign.center, 
                        style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70), fontSize: 18)
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _myBusinesses.length,
                      itemBuilder: (context, index) {
                        final business = _myBusinesses[index];
                        return Card(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      child: Icon(Icons.storefront, color: Theme.of(context).colorScheme.onSurface),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(business['name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, fontSize: 18)),
                                          Text('Modalidad: ${business['modality'].toString().toUpperCase()}', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.onSurface, side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24))
                                      ),
                                      onPressed: () async {
                                        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditBusinessPage(business: business)));
                                        if (result == true) _fetchMyBusinesses();
                                      },
                                      icon: Icon(Icons.edit, size: 16),
                                      label: Text('Editar', style: TextStyle(fontSize: 12)),
                                    ),
                                    SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black87
                                      ),
                                      onPressed: () async {
                                        await Navigator.push(context, MaterialPageRoute(builder: (context) => BusinessPromotionsPage(business: business)));
                                        _fetchMyBusinesses(); 
                                      },
                                      icon: Icon(Icons.local_offer, size: 16),
                                      label: Text('Ofertas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.greenAccent, foregroundColor: Colors.black87
                                      ),
                                      onPressed: () async {
                                        await Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsPage(business: business)));
                                        _fetchMyBusinesses(); // Refrescar stock visual si aplica
                                      },
                                      icon: Icon(Icons.inventory, size: 16),
                                      label: Text('Catálogo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

