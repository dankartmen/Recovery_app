class Sound {
  final String name;
  final String path;
  double volume;
  bool isAsset;
  final String? originalName;

  Sound({
    required this.name,
    required this.path,
    this.volume = 1.0,
    this.isAsset = true,
    this.originalName,
  });
}
