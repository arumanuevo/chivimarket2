import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'api_service.dart';
import 'main.dart'; 

class MyBusinessesPage extends StatefulWidget {
  const MyBusinessesPage({Key? key}) : super(key: key);

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
        title: Text('Mis Locales', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: _isLoading && _myBusinesses.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _myBusinesses.isEmpty
                  ? Center(
                      child: Text('Aún no tienes negocios.\n¡Crea uno desde el Dashboard!', 
                        textAlign: TextAlign.center, 
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 18)
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _myBusinesses.length,
                      itemBuilder: (context, index) {
                        final business = _myBusinesses[index];
                        return Card(
                          color: Colors.white.withOpacity(0.1),
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: const Icon(Icons.storefront, color: Colors.white),
                            ),
                            title: Text(business['name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text('Modalidad: ${business['modality'].toString().toUpperCase()}', style: const TextStyle(color: Colors.white70)),
                            trailing: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.1),
                                foregroundColor: Colors.white,
                                elevation: 0
                              ),
                              onPressed: () {
                                // TODO: Abrir pantalla de edición y fotos
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Editar / Fotos'),
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
