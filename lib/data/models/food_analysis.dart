import 'package:flutter/material.dart';

@immutable
class FoodAnalysis {
  final String name;
  final double protein;
  final double carbs;
  final double fat;
  final double calories;
  final double healthScore;
  final String? imagePath;

  const FoodAnalysis({
    required this.name,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
    required this.healthScore,
    this.imagePath,
  });

  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    return FoodAnalysis(
      name: json['name'] as String,
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      healthScore: (json['healthScore'] as num).toDouble(),
      imagePath: json['imagePath'] as String?,
    );
  }
}
