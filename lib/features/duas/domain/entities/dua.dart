class Dua {
  final int? id;
  final String text;
  final int sortOrder;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Dua({
    this.id,
    required this.text,
    required this.sortOrder,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });
}