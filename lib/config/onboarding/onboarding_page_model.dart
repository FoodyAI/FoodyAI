import 'package:flutter/material.dart';
import 'onboarding_config.dart';

/// Model representing a single onboarding page
class OnboardingPageModel {
  final String id;
  final String title;
  final String description;
  final String backgroundImage;
  final String backgroundImageUrl;
  final String? backgroundVideoUrl;
  final bool useVideo;
  final String icon;
  final Color? primaryColorOverride;

  OnboardingPageModel({
    required this.id,
    required this.title,
    required this.description,
    required this.backgroundImage,
    required this.backgroundImageUrl,
    this.backgroundVideoUrl,
    this.useVideo = false,
    required this.icon,
    this.primaryColorOverride,
  });

  /// Create page model from JSON
  factory OnboardingPageModel.fromJson(Map<String, dynamic> json) {
    return OnboardingPageModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      backgroundImage: json['background_image'] as String,
      backgroundImageUrl: json['background_image_url'] as String,
      backgroundVideoUrl: json['background_video_url'] as String?,
      useVideo: json['use_video'] as bool? ?? false,
      icon: json['icon'] as String,
      primaryColorOverride: json['primary_color_override'] != null
          ? OnboardingConfig.hexToColor(json['primary_color_override'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'background_image': backgroundImage,
      'background_image_url': backgroundImageUrl,
      'icon': icon,
      'primary_color_override': primaryColorOverride != null
          ? '#${primaryColorOverride!.value.toRadixString(16).substring(2)}'
          : null,
    };
  }

  /// Get icon data based on icon name
  IconData getIconData() {
    switch (icon.toLowerCase()) {
      case 'nutrition':
        return Icons.restaurant_menu;
      case 'calculator':
        return Icons.calculate;
      case 'activity':
        return Icons.fitness_center;
      case 'health':
        return Icons.favorite;
      case 'tracking':
        return Icons.track_changes;
      case 'diet':
        return Icons.food_bank;
      case 'analytics':
        return Icons.analytics;
      case 'water':
        return Icons.water_drop;
      case 'sleep':
        return Icons.bedtime;
      case 'exercise':
        return Icons.directions_run;
      default:
        return Icons.star;
    }
  }

  /// Copy with new values
  OnboardingPageModel copyWith({
    String? id,
    String? title,
    String? description,
    String? backgroundImage,
    String? backgroundImageUrl,
    String? backgroundVideoUrl,
    bool? useVideo,
    String? icon,
    Color? primaryColorOverride,
  }) {
    return OnboardingPageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      backgroundVideoUrl: backgroundVideoUrl ?? this.backgroundVideoUrl,
      useVideo: useVideo ?? this.useVideo,
      icon: icon ?? this.icon,
      primaryColorOverride: primaryColorOverride ?? this.primaryColorOverride,
    );
  }
}
