import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recipe.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../widgets/recipe_card.dart';
import '../widgets/custom_button.dart';
import 'recipe_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Recipe> _myRecipes = [];
  bool _isLoading = true;
  bool _isEditingBio = false;
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final currentUser = AuthService.instance.currentUser;
    if (currentUser != null) {
      _bioController.text = currentUser.bio ?? '';
      _myRecipes = await DatabaseHelper.instance.getRecipesByUser(currentUser.id!);

      // Marcar favoritos
      for (var recipe in _myRecipes) {
        recipe.isFavorite = await DatabaseHelper.instance.isFavorite(
          currentUser.id!,
          recipe.id!,
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateBio() async {
    final result = await AuthService.instance.updateProfile(
      bio: _bioController.text.trim(),
    );

    if (mounted) {
      if (result['success']) {
        setState(() => _isEditingBio = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biografía actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _calculateAverageRating() {
    if (_myRecipes.isEmpty) return 0.0;
    final totalRating = _myRecipes.fold<double>(
      0,
          (sum, recipe) => sum + recipe.rating,
    );
    return totalRating / _myRecipes.length;
  }

  int _getTotalRatings() {
    return _myRecipes.fold<int>(
      0,
          (sum, recipe) => sum + recipe.totalRatings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          backgroundColor: const Color(0xFFDD2140),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No hay sesión activa'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
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
          : RefreshIndicator(
        onRefresh: _loadProfile,
        color: const Color(0xFFDD2140),
        child: ListView(
          children: [
            // Header del perfil
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFDD2140),
                    const Color(0xFFFF6B6B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        user.username.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDD2140),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Miembro desde ${DateFormat('MMMM yyyy', 'es').format(user.createdAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Estadísticas
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    Icons.restaurant_menu,
                    '${_myRecipes.length}',
                    'Recetas',
                  ),
                  _buildStatCard(
                    Icons.star,
                    _calculateAverageRating().toStringAsFixed(1),
                    'Promedio',
                  ),
                  _buildStatCard(
                    Icons.thumb_up,
                    '${_getTotalRatings()}',
                    'Valoraciones',
                  ),
                ],
              ),
            ),
            const Divider(),
            // Biografía
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Biografía',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isEditingBio)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFFDD2140)),
                          onPressed: () {
                            setState(() => _isEditingBio = true);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isEditingBio)
                    Column(
                      children: [
                        TextField(
                          controller: _bioController,
                          decoration: InputDecoration(
                            hintText: 'Cuéntanos sobre ti...',
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
                          maxLines: 4,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditingBio = false;
                                  _bioController.text = user.bio ?? '';
                                });
                              },
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _updateBio,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDD2140),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.bio?.isEmpty ?? true
                            ? 'Aún no has agregado una biografía'
                            : user.bio!,
                        style: TextStyle(
                          fontSize: 16,
                          color: user.bio?.isEmpty ?? true
                              ? Colors.grey[600]
                              : Colors.black87,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            // Mis recetas
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mis Recetas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_myRecipes.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No has publicado recetas aún',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _myRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _myRecipes[index];
                        return RecipeCard(
                          recipe: recipe,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecipeDetailScreen(recipe: recipe),
                              ),
                            ).then((_) => _loadProfile());
                          },
                          onFavoriteToggle: null,
                          showFavorite: false,
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDD2140).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFFDD2140),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
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
      ),
    );
  }
}