import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Recipe> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId != null) {
      final favorites = await DatabaseHelper.instance.getFavoriteRecipes(currentUserId);

      for (var recipe in favorites) {
        recipe.isFavorite = true;
      }

      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(Recipe recipe) async {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) return;

    await DatabaseHelper.instance.removeFavorite(currentUserId, recipe.id!);
    await _loadFavorites();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eliminado de favoritos'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
        backgroundColor: const Color(0xFFDD2140),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFDD2140),
        ),
      )
          : _favorites.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes favoritos aún',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explora recetas y marca tus favoritas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadFavorites,
        color: const Color(0xFFDD2140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFFDD2140),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_favorites.length} recetas guardadas',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final recipe = _favorites[index];
                  return RecipeCard(
                    recipe: recipe,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              RecipeDetailScreen(recipe: recipe),
                        ),
                      ).then((_) => _loadFavorites());
                    },
                    onFavoriteToggle: () => _removeFavorite(recipe),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}