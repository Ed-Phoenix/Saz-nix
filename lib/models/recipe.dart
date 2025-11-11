class Recipe {
  final int? id;
  final String title;
  final String ingredients;
  final String procedure;
  final String? imagePath;
  final int userId;
  final String category;
  final int prepTime; // en minutos
  final int servings;
  final DateTime createdAt;
  double rating;
  int totalRatings;
  bool isFavorite;

  Recipe({
    this.id,
    required this.title,
    required this.ingredients,
    required this.procedure,
    this.imagePath,
    required this.userId,
    required this.category,
    required this.prepTime,
    required this.servings,
    DateTime? createdAt,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.isFavorite = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'ingredients': ingredients,
      'procedure': procedure,
      'imagePath': imagePath,
      'userId': userId,
      'category': category,
      'prepTime': prepTime,
      'servings': servings,
      'createdAt': createdAt.toIso8601String(),
      'rating': rating,
      'totalRatings': totalRatings,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      title: map['title'],
      ingredients: map['ingredients'],
      procedure: map['procedure'],
      imagePath: map['imagePath'],
      userId: map['userId'],
      category: map['category'],
      prepTime: map['prepTime'],
      servings: map['servings'],
      createdAt: DateTime.parse(map['createdAt']),
      rating: map['rating']?.toDouble() ?? 0.0,
      totalRatings: map['totalRatings'] ?? 0,
    );
  }

  Recipe copyWith({
    int? id,
    String? title,
    String? ingredients,
    String? procedure,
    String? imagePath,
    int? userId,
    String? category,
    int? prepTime,
    int? servings,
    DateTime? createdAt,
    double? rating,
    int? totalRatings,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      procedure: procedure ?? this.procedure,
      imagePath: imagePath ?? this.imagePath,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      prepTime: prepTime ?? this.prepTime,
      servings: servings ?? this.servings,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}