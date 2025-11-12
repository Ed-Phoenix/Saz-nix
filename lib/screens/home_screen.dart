import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/recipe.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../widgets/recipe_card.dart';
import '../widgets/custom_button.dart';
import 'favorites_screen.dart';
import 'create_recipe_screen.dart';
import 'recipe_detail_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _isLoading = true;
  String _selectedCategory = 'Todas';
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'Todas',
    'Desayuno',
    'Comida',
    'Cena',
    'Postre',
    'Bebidas',
    'Snacks',
    'Vegetariano',
    'Internacional',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);

    final recipes = await DatabaseHelper.instance.getAllRecipes();
    final currentUserId = AuthService.instance.currentUser?.id;

    if (currentUserId != null) {
      for (var recipe in recipes) {
        recipe.isFavorite = await DatabaseHelper.instance.isFavorite(
          currentUserId,
          recipe.id!,
        );
      }
    }

    setState(() {
      _recipes = recipes;
      _filteredRecipes = recipes;
      _isLoading = false;
    });
  }

  void _filterRecipes() {
    setState(() {
      _filteredRecipes = _recipes.where((recipe) {
        final matchesCategory = _selectedCategory == 'Todas' ||
            recipe.category == _selectedCategory;
        final matchesSearch = _searchController.text.isEmpty ||
            recipe.title
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            recipe.ingredients
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) return;

    if (recipe.isFavorite) {
      await DatabaseHelper.instance.removeFavorite(currentUserId, recipe.id!);
    } else {
      await DatabaseHelper.instance.addFavorite(currentUserId, recipe.id!);
    }

    setState(() {
      recipe.isFavorite = !recipe.isFavorite;
    });
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sazónix',
          style: GoogleFonts.pacifico(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFDD2140),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              ).then((_) => _loadRecipes());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecipes,
        color: const Color(0xFFDD2140),
        child: Column(
          children: [
            // Header con botones principales
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDD2140),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '¡Hola, ${user?.username ?? "Usuario"}!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Favoritos',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FavoritesScreen(),
                              ),
                            ).then((_) => _loadRecipes());
                          },
                          icon: Icons.star,
                          color: Colors.white,
                          textColor: const Color(0xFFDD2140),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Nueva Receta',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const CreateRecipeScreen(),
                              ),
                            ).then((_) => _loadRecipes());
                          },
                          icon: Icons.add,
                          color: Colors.white,
                          textColor: const Color(0xFFDD2140),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar recetas...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFDD2140),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterRecipes();
                    },
                  )
                      : null,
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
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (_) => _filterRecipes(),
              ),
            ),
            const SizedBox(height: 16),
            // Filtros de categoría
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _filterRecipes();
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: const Color(0xFFDD2140),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      checkmarkColor: Colors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Lista de recetas
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFDD2140),
                ),
              )
                  : _filteredRecipes.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No se encontraron recetas',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¡Sé el primero en compartir!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filteredRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = _filteredRecipes[index];
                  return RecipeCard(
                    recipe: recipe,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              RecipeDetailScreen(recipe: recipe),
                        ),
                      ).then((_) => _loadRecipes());
                    },
                    onFavoriteToggle: () => _toggleFavorite(recipe),
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