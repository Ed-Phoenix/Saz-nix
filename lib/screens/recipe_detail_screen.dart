import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../models/recipe.dart';
import '../models/comment.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({Key? key, required this.recipe}) : super(key: key);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe;
  List<Comment> _comments = [];
  User? _author;
  bool _isLoading = true;
  final _commentController = TextEditingController();
  double _userRating = 0;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Cargar autor
    _author = await DatabaseHelper.instance.getUserById(_recipe.userId);

    // Cargar comentarios
    _comments = await DatabaseHelper.instance.getCommentsByRecipe(_recipe.id!);

    // Cargar calificación del usuario actual
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId != null) {
      final rating = await DatabaseHelper.instance.getUserRating(
        currentUserId,
        _recipe.id!,
      );
      _userRating = rating ?? 0;

      // Actualizar estado de favorito
      _recipe.isFavorite = await DatabaseHelper.instance.isFavorite(
        currentUserId,
        _recipe.id!,
      );
    }

    // Recargar receta para obtener rating actualizado
    final updatedRecipe = await DatabaseHelper.instance.getRecipeById(_recipe.id!);
    if (updatedRecipe != null) {
      _recipe = updatedRecipe;
      _recipe.isFavorite = await DatabaseHelper.instance.isFavorite(
        currentUserId!,
        _recipe.id!,
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) return;

    final comment = Comment(
      recipeId: _recipe.id!,
      userId: currentUser.id!,
      username: currentUser.username,
      text: _commentController.text.trim(),
    );

    await DatabaseHelper.instance.createComment(comment);
    _commentController.clear();
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comentario agregado'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _rateRecipe(double rating) async {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) return;

    await DatabaseHelper.instance.rateRecipe(
      currentUserId,
      _recipe.id!,
      rating,
    );

    setState(() => _userRating = rating);
    await _loadData();
  }

  Future<void> _toggleFavorite() async {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) return;

    if (_recipe.isFavorite) {
      await DatabaseHelper.instance.removeFavorite(currentUserId, _recipe.id!);
    } else {
      await DatabaseHelper.instance.addFavorite(currentUserId, _recipe.id!);
    }

    setState(() => _recipe.isFavorite = !_recipe.isFavorite);
  }

  Future<void> _deleteRecipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar receta'),
        content: const Text('¿Estás seguro de que deseas eliminar esta receta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteRecipe(_recipe.id!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.instance.currentUser?.id;
    final isOwner = currentUserId == _recipe.userId;

    return Scaffold(
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFDD2140),
        ),
      )
          : CustomScrollView(
        slivers: [
          // AppBar con imagen
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFFDD2140),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _recipe.imagePath != null && _recipe.imagePath!.isNotEmpty
                      ? Image.file(
                    File(_recipe.imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder();
                    },
                  )
                      : _buildPlaceholder(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _recipe.isFavorite ? Icons.star : Icons.star_border,
                  color: _recipe.isFavorite ? Colors.amber : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteRecipe,
                ),
            ],
          ),
          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y categoría
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _recipe.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDD2140),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _recipe.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Autor y fecha
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFDD2140),
                        child: Text(
                          _author?.username.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _author?.username ?? 'Usuario',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_recipe.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Info rápida
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoCard(
                        Icons.access_time,
                        '${_recipe.prepTime} min',
                        'Tiempo',
                      ),
                      _buildInfoCard(
                        Icons.restaurant,
                        '${_recipe.servings}',
                        'Porciones',
                      ),
                      _buildInfoCard(
                        Icons.star,
                        _recipe.rating.toStringAsFixed(1),
                        '${_recipe.totalRatings} votos',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Calificar receta
                  if (!isOwner) ...[
                    const Text(
                      'Califica esta receta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: RatingBar.builder(
                        initialRating: _userRating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Color(0xFFDD2140),
                        ),
                        onRatingUpdate: _rateRecipe,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Ingredientes
                  const Text(
                    'Ingredientes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _recipe.ingredients,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Procedimiento
                  const Text(
                    'Procedimiento',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _recipe.procedure,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Comentarios
                  const Text(
                    'Comentarios',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Campo de comentario
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Escribe un comentario...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFDD2140),
                                width: 2,
                              ),
                            ),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Color(0xFFDD2140),
                        ),
                        onPressed: _addComment,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Lista de comentarios
                  if (_comments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No hay comentarios aún',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._comments.map((comment) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFDD2140),
                                  child: Text(
                                    comment.username.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm')
                                            .format(comment.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(comment.text),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 80,
          color: Color(0xFFDD2140),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDD2140).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFDD2140),
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}