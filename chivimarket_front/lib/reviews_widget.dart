import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';

class ReviewsWidget extends StatefulWidget {
  final String entityType; // 'businesses' o 'products'
  final int entityId;
  final bool isLoggedIn;

  const ReviewsWidget({
    Key? key,
    required this.entityType,
    required this.entityId,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  State<ReviewsWidget> createState() => _ReviewsWidgetState();
}

class _ReviewsWidgetState extends State<ReviewsWidget> {
  bool _isLoading = true;
  List<dynamic> _ratings = [];
  double _average = 0.0;
  int _total = 0;

  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final res = await ApiService.get('/${widget.entityType}/${widget.entityId}/ratings');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _ratings = data['ratings'] ?? [];
            _average = double.tryParse(data['average_rating'].toString()) ?? 0.0;
            _total = data['total_ratings'] ?? 0;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Haz clic en las estrellas para indicar tu calificación.'), backgroundColor: Colors.orange));
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recomendamos escribir un pequeño comentario')));
      // No cortamos la ejecución porque el backend permite nullable string
    }

    setState(() => _isSubmitting = true);
    
    try {
      final res = await ApiService.post('/${widget.entityType}/${widget.entityId}/ratings', {
        'rating': _selectedRating,
        'comment': _commentController.text.trim(),
      });

      if (res.statusCode == 201) {
        _commentController.clear();
        setState(() => _selectedRating = 0);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Reseña publicada con éxito!')));
        _fetchReviews();
      } else if (res.statusCode == 403) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya has calificado esto antes.'), backgroundColor: Colors.orange));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al publicar la reseña.')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión.')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStarSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          icon: Icon(
            starValue <= _selectedRating ? Icons.star : Icons.star_border,
            color: Colors.amberAccent,
            size: 32,
          ),
          onPressed: () => setState(() => _selectedRating = starValue),
        );
      }),
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) => Icon(
        index < rating ? Icons.star : Icons.star_border,
        color: Colors.amberAccent,
        size: 14,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color onSurface = theme.colorScheme.onSurface;
    final Color primary = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reseñas', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), 
                borderRadius: BorderRadius.circular(16)
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(_average > 0 ? _average.toString() : 'Nuevo', style: TextStyle(fontWeight: FontWeight.bold, color: onSurface)),
                  Text('  ($_total)', style: TextStyle(color: onSurface.withOpacity(0.55), fontSize: 12)),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 16),

        // Formulario de Posteo
        if (widget.isLoggedIn)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black45 : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Dejar una opinión', style: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildStarSelector(),
                TextField(
                  controller: _commentController,
                  style: TextStyle(color: onSurface),
                  decoration: InputDecoration(
                    hintText: '¿Qué te pareció?',
                    hintStyle: TextStyle(color: onSurface.withOpacity(0.4)),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  icon: _isSubmitting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.send, size: 18),
                  label: const Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04), 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: onSurface.withOpacity(0.5)),
                const SizedBox(width: 12),
                Expanded(child: Text('Debes iniciar sesión para publicar reseñas.', style: TextStyle(color: onSurface.withOpacity(0.6)))),
              ],
            ),
          ),
        
        const SizedBox(height: 24),

        // Lista de Comentarios
        if (_ratings.isEmpty)
          Center(child: Text('Aún no hay opiniones. ¡Sé el primero!', style: TextStyle(color: onSurface.withOpacity(0.5), fontStyle: FontStyle.italic)))
        else
          ..._ratings.map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                boxShadow: isDark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16, 
                        backgroundColor: isDark ? Colors.white24 : Colors.black12, 
                        child: Icon(Icons.person, size: 16, color: onSurface.withOpacity(0.8))
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(r['user'] != null ? r['user']['name'] : 'Anónimo', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold))),
                      _buildStars(r['rating'] ?? 5),
                    ],
                  ),
                  if (r['comment'] != null && r['comment'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('"${r['comment']}"', style: TextStyle(color: onSurface.withOpacity(0.8), fontStyle: FontStyle.italic)),
                  ]
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}
