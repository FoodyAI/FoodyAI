import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

@immutable
class FoodAnalysis {
  final String? id;
  final String name;
  final double protein;
  final double carbs;
  final double fat;
  final double calories;
  final double healthScore;
  final String? imagePath; // Legacy field - will be deprecated
  final String? localImagePath; // Local file path
  final String? s3ImageUrl; // S3 URL
  final int orderNumber;
  final DateTime date;
  final int dateOrderNumber;
  final bool syncedToAws;
  final DateTime createdAt; // Add created_at field for consistent ordering

  FoodAnalysis({
    this.id,
    required this.name,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
    required this.healthScore,
    this.imagePath,
    this.localImagePath,
    this.s3ImageUrl,
    this.orderNumber = 0,
    DateTime? date,
    this.dateOrderNumber = 0,
    this.syncedToAws = false,
    DateTime? createdAt,
  })  : date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory FoodAnalysis.withCurrentDate({
    required String name,
    required double protein,
    required double carbs,
    required double fat,
    required double calories,
    required double healthScore,
    String? imagePath,
    int orderNumber = 0,
    bool syncedToAws = false,
  }) {
    final now = DateTime.now();
    return FoodAnalysis(
      name: name,
      protein: protein,
      carbs: carbs,
      fat: fat,
      calories: calories,
      healthScore: healthScore,
      imagePath: imagePath,
      orderNumber: orderNumber,
      date: now,
      dateOrderNumber: 0,
      syncedToAws: syncedToAws,
      createdAt: now,
    );
  }

  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    return FoodAnalysis(
      name: json['name'] as String,
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      healthScore: (json['healthScore'] as num).toDouble(),
      imagePath: json['imagePath'] as String?,
      orderNumber: json['orderNumber'] as int? ?? 0,
      date: json['date'] != null
          ? (json['date'] is String
              ? DateTime.parse(json['date'])
              : DateTime.fromMillisecondsSinceEpoch(json['date'] as int))
          : DateTime.now(),
      dateOrderNumber: json['dateOrderNumber'] as int? ?? 0,
      syncedToAws: json['syncedToAws'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'])
              : DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calories': calories,
      'healthScore': healthScore,
      'imagePath': imagePath,
      'orderNumber': orderNumber,
      'date': date.millisecondsSinceEpoch,
      'dateOrderNumber': dateOrderNumber,
      'syncedToAws': syncedToAws,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // SQLite-specific methods
  // Note: user_id should be set by the caller (SQLiteService)
  Map<String, dynamic> toMap() {
    const uuid = Uuid();
    return {
      'id': id ?? uuid.v4(), // Generate UUID if not provided
      'user_id': 'placeholder', // Will be overwritten by SQLiteService
      'image_url': imagePath, // Legacy field
      'local_image_path': localImagePath,
      's3_image_url': s3ImageUrl,
      'food_name': name,
      'calories': calories.round(),
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'health_score': healthScore.round(),
      'analysis_date': date.toIso8601String().split('T')[0],
      'created_at': createdAt.millisecondsSinceEpoch,
      'synced_to_aws': syncedToAws ? 1 : 0,
    };
  }

  factory FoodAnalysis.fromMap(Map<String, dynamic> map) {
    return FoodAnalysis(
      id: map['id'] as String?,
      name: map['food_name'] as String,
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      calories: (map['calories'] as num).toDouble(),
      healthScore: (map['health_score'] as num).toDouble(),
      imagePath: map['image_url'] as String?, // Legacy field
      localImagePath: map['local_image_path'] as String?,
      s3ImageUrl: map['s3_image_url'] as String?,
      orderNumber: 0, // Not stored in database anymore
      date: DateTime.parse(map['analysis_date'] as String),
      dateOrderNumber: 0, // Not stored in database anymore
      syncedToAws: (map['synced_to_aws'] as int? ?? 0) == 1,
      createdAt: map['created_at'] != null
          ? (map['created_at'] is String
              ? DateTime.parse(map['created_at'])
              : DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int))
          : DateTime.now(),
    );
  }

  /// Gets the best available image path (local first, then S3, then legacy)
  String? getBestImagePath() {
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      return localImagePath;
    }
    if (s3ImageUrl != null && s3ImageUrl!.isNotEmpty) {
      return s3ImageUrl;
    }
    return imagePath; // Legacy fallback
  }

  /// Checks if local image file exists
  bool get hasLocalImage =>
      localImagePath != null && localImagePath!.isNotEmpty;

  /// Checks if S3 image URL is available
  bool get hasS3Image => s3ImageUrl != null && s3ImageUrl!.isNotEmpty;

  // Method to create a copy with updated sync status
  FoodAnalysis copyWith({
    String? name,
    double? protein,
    double? carbs,
    double? fat,
    double? calories,
    double? healthScore,
    String? imagePath,
    int? orderNumber,
    DateTime? date,
    int? dateOrderNumber,
    bool? syncedToAws,
    DateTime? createdAt,
  }) {
    return FoodAnalysis(
      name: name ?? this.name,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      calories: calories ?? this.calories,
      healthScore: healthScore ?? this.healthScore,
      imagePath: imagePath ?? this.imagePath,
      orderNumber: orderNumber ?? this.orderNumber,
      date: date ?? this.date,
      dateOrderNumber: dateOrderNumber ?? this.dateOrderNumber,
      syncedToAws: syncedToAws ?? this.syncedToAws,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
