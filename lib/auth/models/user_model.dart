/// {@template user_model}
/// Модель данных пользователя.
/// Содержит основную информацию о пользователе системы.
/// {@endtemplate}
class User {
  /// Уникальный идентификатор пользователя.
  /// Может быть null для новых пользователей.
  final int? id;

  /// Имя пользователя для входа в систему.
  final String username;

  /// Флаг заполнения анкеты пользователем.
  /// true если пользователь заполнил анкету, false в противном случае.
  final bool hasQuestionnaire;

  /// {@macro user_model}
  User({this.id, required this.username, this.hasQuestionnaire = false});

  /// Фабричный метод для создания пользователя из JSON данных.
  /// Принимает:
  /// - [json] - Map<String, dynamic> с данными пользователя в формате JSON.
  /// Возвращает:
  /// - Новый экземпляр [User] с распарсенными данными.
  /// При ошибке парсинга выбрасывает [FormatException].
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
}