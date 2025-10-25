/// {@template sound}
/// Модель звукового файла для воспроизведения в приложении.
/// Поддерживает как системные (asset), так и пользовательские звуки.
/// {@endtemplate}
class Sound {
  /// Отображаемое имя звука в интерфейсе
  final String name;

  /// Путь к файлу звука (asset путь или файловый путь)
  final String path;

  /// Громкость воспроизведения (от 0.0 до 1.0)
  double volume;

  /// Флаг, указывающий является ли звук системным (true) или пользовательским (false)
  bool isAsset;

  /// Оригинальное имя файла (для пользовательских звуков)
  final String? originalName;

  /// {@macro sound}
  Sound({
    required this.name,
    required this.path,
    this.volume = 1.0,
    this.isAsset = true,
    this.originalName,
  });
}
