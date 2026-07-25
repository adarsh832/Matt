class AiModel {
  final String id;
  final String name;

  AiModel({
    required this.id,
    required this.name,
  });

  factory AiModel.fromJson(Map<String, dynamic> json) {
    return AiModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
