import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/recipe.dart';
import '../models/comment.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sazonix.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        username $textType,
        email $textType UNIQUE,
        password $textType,
        bio TEXT,
        createdAt $textType
      )
    ''');

    // Tabla de recetas
    await db.execute('''
      CREATE TABLE recipes (
        id $idType,
        title $textType,
        ingredients $textType,
        procedure $textType,
        imagePath TEXT,
        userId $intType,
        category $textType,
        prepTime $intType,
        servings $intType,
        createdAt $textType,
        rating $realType DEFAULT 0.0,
        totalRatings $intType DEFAULT 0,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de comentarios
    await db.execute('''
      CREATE TABLE comments (
        id $idType,
        recipeId $intType,
        userId $intType,
        username $textType,
        text $textType,
        createdAt $textType,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de favoritos
    await db.execute('''
      CREATE TABLE favorites (
        userId $intType,
        recipeId $intType,
        PRIMARY KEY (userId, recipeId),
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de calificaciones
    await db.execute('''
      CREATE TABLE ratings (
        userId $intType,
        recipeId $intType,
        rating $realType,
        PRIMARY KEY (userId, recipeId),
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');
  }

  // ===== OPERACIONES DE USUARIOS =====
  Future<User> createUser(User user) async {
    final db = await instance.database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ===== OPERACIONES DE RECETAS =====
  Future<Recipe> createRecipe(Recipe recipe) async {
    final db = await instance.database;
    final id = await db.insert('recipes', recipe.toMap());
    return recipe.copyWith(id: id);
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await instance.database;
    final result = await db.query('recipes', orderBy: 'createdAt DESC');
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  Future<List<Recipe>> getRecipesByUser(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'recipes',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  Future<Recipe?> getRecipeById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Recipe.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'recipes',
      where: 'title LIKE ? OR ingredients LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  Future<List<Recipe>> getRecipesByCategory(String category) async {
    final db = await instance.database;
    final result = await db.query(
      'recipes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  Future<int> updateRecipe(Recipe recipe) async {
    final db = await instance.database;
    return db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<int> deleteRecipe(int id) async {
    final db = await instance.database;
    return db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== OPERACIONES DE COMENTARIOS =====
  Future<Comment> createComment(Comment comment) async {
    final db = await instance.database;
    final id = await db.insert('comments', comment.toMap());
    return comment.copyWith(id: id);
  }

  Future<List<Comment>> getCommentsByRecipe(int recipeId) async {
    final db = await instance.database;
    final result = await db.query(
      'comments',
      where: 'recipeId = ?',
      whereArgs: [recipeId],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Comment.fromMap(json)).toList();
  }

  // ===== OPERACIONES DE FAVORITOS =====
  Future<void> addFavorite(int userId, int recipeId) async {
    final db = await instance.database;
    await db.insert('favorites', {
      'userId': userId,
      'recipeId': recipeId,
    });
  }

  Future<void> removeFavorite(int userId, int recipeId) async {
    final db = await instance.database;
    await db.delete(
      'favorites',
      where: 'userId = ? AND recipeId = ?',
      whereArgs: [userId, recipeId],
    );
  }

  Future<bool> isFavorite(int userId, int recipeId) async {
    final db = await instance.database;
    final result = await db.query(
      'favorites',
      where: 'userId = ? AND recipeId = ?',
      whereArgs: [userId, recipeId],
    );
    return result.isNotEmpty;
  }

  Future<List<Recipe>> getFavoriteRecipes(int userId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT recipes.* FROM recipes
      INNER JOIN favorites ON recipes.id = favorites.recipeId
      WHERE favorites.userId = ?
      ORDER BY recipes.createdAt DESC
    ''', [userId]);
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  // ===== OPERACIONES DE CALIFICACIONES =====
  Future<void> rateRecipe(int userId, int recipeId, double rating) async {
    final db = await instance.database;

    // Insertar o actualizar la calificación
    await db.insert(
      'ratings',
      {
        'userId': userId,
        'recipeId': recipeId,
        'rating': rating,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Recalcular el promedio
    final result = await db.rawQuery('''
      SELECT AVG(rating) as avgRating, COUNT(*) as total
      FROM ratings
      WHERE recipeId = ?
    ''', [recipeId]);

    final avgRating = result.first['avgRating'] as double;
    final total = result.first['total'] as int;

    // Actualizar la receta
    await db.update(
      'recipes',
      {
        'rating': avgRating,
        'totalRatings': total,
      },
      where: 'id = ?',
      whereArgs: [recipeId],
    );
  }

  Future<double?> getUserRating(int userId, int recipeId) async {
    final db = await instance.database;
    final result = await db.query(
      'ratings',
      where: 'userId = ? AND recipeId = ?',
      whereArgs: [userId, recipeId],
    );
    if (result.isNotEmpty) {
      return result.first['rating'] as double;
    }
    return null;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}

extension CommentCopyWith on Comment {
  Comment copyWith({
    int? id,
    int? recipeId,
    int? userId,
    String? username,
    String? text,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}