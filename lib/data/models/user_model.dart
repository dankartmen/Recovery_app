class User {
  final int? id;
  final String username;
  final bool hasQuestionnaire;

  User({this.id, required this.username, this.hasQuestionnaire = false});

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'] as int? ?? 0, // Значение по умолчанию, если null
        username: json['username'] as String,
      );
    } catch (e) {
      throw FormatException('Ошибка парсинга пользователя: $e');
    }
  }
  static int _parseId(dynamic id) {
    if (id == null) return 0;
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    throw FormatException('Invalid ID type: ${id.runtimeType}');
  }
}
