import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'create_community_post_page.dart';
import 'community_post_detail_page.dart';

class MyCommunityPostsPage extends StatefulWidget {
  const MyCommunityPostsPage({Key? key}) : super(key: key);

  @override
  State<MyCommunityPostsPage> createState() => _MyCommunityPostsPageState();
}

class _MyCommunityPostsPageState extends State<MyCommunityPostsPage> {
  bool _isLoading = true;
  List<dynamic> _posts = [];

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
  }

  Future<void> _fetchMyPosts() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/my-community-posts');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _posts = data is List ? data : []);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleStatus(int id) async {
    try {
      final res = await ApiService.post('/community-posts/$id/toggle-status', {});
      if (res.statusCode == 200) {
        _fetchMyPosts();
      }
    } catch (_) {}
  }

  Future<void> _deletePost(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Publicación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta publicación permanentemente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.delete('/community-posts/$id');
        if (res.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Publicación eliminada correctamente.')),
            );
          }
          _fetchMyPosts();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Trueques y Usados', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateCommunityPostPage()),
          );
          if (res == true) _fetchMyPosts();
        },
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Publicar Nuevo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 70, color: theme.colorScheme.primary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Aún no publicaste artículos',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Publicá lo que ya no usás para trueque o venta comunitaria'),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateCommunityPostPage()),
                          );
                          if (res == true) _fetchMyPosts();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Primera Publicación'),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchMyPosts,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final item = _posts[index];
                      final isActive = item['is_active'] == true;
                      final type = item['type'] ?? 'both';
                      final typeLabel = type == 'both'
                          ? 'Venta o Trueque'
                          : (type == 'barter' ? 'Solo Trueque' : 'Venta Usado');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isActive ? '● ACTIVA' : '⏸ PAUSADA',
                                      style: TextStyle(
                                        color: isActive ? Colors.green : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    typeLabel,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '👀 ${item['views_count'] ?? 0} vistas',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['title'] ?? '',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              if (item['price'] != null && double.tryParse(item['price'].toString()) != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '\$${item['price']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => CommunityPostDetailPage(post: item)),
                                    ),
                                    icon: const Icon(Icons.visibility, size: 16),
                                    label: const Text('Ver'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _toggleStatus(item['id']),
                                    icon: Icon(isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 16),
                                    label: Text(isActive ? 'Pausar' : 'Reactivar'),
                                  ),
                                  IconButton(
                                    onPressed: () => _deletePost(item['id']),
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
