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
  final String? imagePath;
  final int orderNumber;
  final DateTime date;
  final int dateOrderNumber;
  final bool syncedToAws;

  FoodAnalysis({
    this.id,
    required this.name,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
    required this.healthScore,
    this.imagePath,
    this.orderNumber = 0,
    DateTime? date,
    this.dateOrderNumber = 0,
    this.syncedToAws = false,
  }) : date = date ?? DateTime.now();

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
    return FoodAnalysis(
      name: name,
      protein: protein,
      carbs: carbs,
      fat: fat,
      calories: calories,
      healthScore: healthScore,
      imagePath: imagePath,
      orderNumber: orderNumber,
      date: DateTime.now(),
      dateOrderNumber: 0,
      syncedToAws: syncedToAws,
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
          ? DateTime.fromMillisecondsSinceEpoch(json['date'] as int)
          : DateTime.now(),
      dateOrderNumber: json['dateOrderNumber'] as int? ?? 0,
      syncedToAws: json['syncedToAws'] as bool? ?? false,
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
    };
  }

  // SQLite-specific methods
  Map<String, dynamic> toMap() {
    const uuid = Uuid();
    return {
      'id': id ?? uuid.v4(), // Generate UUID if not provided
      'user_id': 'local_user',
      'image_url': imagePath,
      'food_name': name,
      'calories': calories.round(),
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'health_score': healthScore.round(),
      'analysis_date': date.toIso8601String().split('T')[0],
      'created_at': DateTime.now().millisecondsSinceEpoch,
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
      imagePath: map['image_url'] as String?,
      orderNumber: 0, // Not stored in database anymore
      date: DateTime.parse(map['analysis_date'] as String),
      dateOrderNumber: 0, // Not stored in database anymore
      syncedToAws: (map['synced_to_aws'] as int? ?? 0) == 1,
    );
  }

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
    );
  }
}
