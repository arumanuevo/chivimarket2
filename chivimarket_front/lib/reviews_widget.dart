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

  int _selectedRating = 5;
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
        setState(() => _selectedRating = 5);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Reseña publicada con éxito!')));
        _fetchReviews();
      } else if (res.statusCode == 403) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya has calificado esto antes.', backgroundColor: Colors.orange)));
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reseñas', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 4),
                  Text(_average > 0 ? _average.toString() : 'Nuevo', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('  ($_total)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
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
              color: Colors.black45,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Dejar una opinión', style: GoogleFonts.outfit(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildStarSelector(),
                TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '¿Qué te pareció?',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent.withOpacity(0.8),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.send, size: 18),
                  label: const Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: const [
                Icon(Icons.lock_outline, color: Colors.white54),
                SizedBox(width: 12),
                Expanded(child: Text('Debes iniciar sesión para publicar reseñas.', style: TextStyle(color: Colors.white54))),
              ],
            ),
          ),
        
        const SizedBox(height: 24),

        // Lista de Comentarios
        if (_ratings.isEmpty)
          const Center(child: Text('Aún no hay opiniones. ¡Sé el primero!', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)))
        else
          ..._ratings.map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 16, backgroundColor: Colors.white24, child: const Icon(Icons.person, size: 16, color: Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(r['user'] != null ? r['user']['name'] : 'Anónimo', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      _buildStars(r['rating'] ?? 5),
                    ],
                  ),
                  if (r['comment'] != null && r['comment'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('"${r['comment']}"', style: TextStyle(color: Colors.white.withOpacity(0.8), fontStyle: FontStyle.italic)),
                  ]
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}
