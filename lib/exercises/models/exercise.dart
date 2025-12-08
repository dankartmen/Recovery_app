class Exercise {
  final int? id;
  final String title;
  final String generalDescription;
  final Map<String, String> injurySpecificInfo;
  final List<String> suitableFor;
  final int maxPainLevel;
  final List<String> steps;
  final List<String> tags;
  final String? imageUrl;

  Exercise({
    this.id,
    required this.title,
    required this.generalDescription,
    this.injurySpecificInfo = const {},
    required this.suitableFor,
    required this.maxPainLevel,
    required this.steps,
    required this.tags,
    this.imageUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      title: json['title'],
      generalDescription: json['general_description'],
      injurySpecificInfo: _parseInjuryInfo(json['injury_specific_info']),
      suitableFor: List<String>.from(json['suitable_for']),
      maxPainLevel: json['max_pain_level'],
      steps: List<String>.from(json['steps']),
      tags: List<String>.from(json['tags']),
      imageUrl: json['image_url'],
    );
  }
  // Вспомогательный метод для обработки injury_specific_info
  static Map<String, String> _parseInjuryInfo(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      return data.map((key, value) => MapEntry(key, value.toString()));
    }
    return {};
  }
}