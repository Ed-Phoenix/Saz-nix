class Comment {
  final int? id;
  final int recipeId;
  final int userId;
  final String username;
  final String text;
  final DateTime createdAt;

  Comment({
    this.id,
    required this.recipeId,
    required this.userId,
    required this.username,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'userId': userId,
      'username': username,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      recipeId: map['recipeId'],
      userId: map['userId'],
      username: map['username'],
      text: map['text'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}