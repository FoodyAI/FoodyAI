class Product {
  final String barcode;
  final String name;
  final String? brand;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? imageUrl;
  final Map<String, dynamic>? nutriments;

  Product({
    required this.barcode,
    required this.name,
    this.brand,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.imageUrl,
    this.nutriments,
  });

  factory Product.fromOpenFoodFacts(Map<String, dynamic> data) {
    final nutriments = data['nutriments'] as Map<String, dynamic>?;

    return Product(
      barcode: data['code'] ?? '',
      name: data['product_name'] ?? 'Unknown Product',
      brand: data['brands'],
      calories: _parseDouble(nutriments?['energy-kcal_100g']),
      protein: _parseDouble(nutriments?['proteins_100g']),
      carbs: _parseDouble(nutriments?['carbohydrates_100g']),
      fat: _parseDouble(nutriments?['fat_100g']),
      imageUrl: data['image_url'],
      nutriments: nutriments,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
