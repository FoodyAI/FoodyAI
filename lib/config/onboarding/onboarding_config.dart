import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding_page_model.dart';

/// Configuration class for the onboarding screen
/// Loads and parses the onboarding JSON configuration
class OnboardingConfig {
  final String appName;
  final String tagline;
  final ThemeConfig theme;
  final List<OnboardingPageModel> pages;
  final UIElements uiElements;
  final PhoneMockupConfig phoneMockup;
  final AnimationConfig animations;
  final NavigationConfig navigation;

  OnboardingConfig({
    required this.appName,
    required this.tagline,
    required this.theme,
    required this.pages,
    required this.uiElements,
    required this.phoneMockup,
    required this.animations,
    required this.navigation,
  });

  /// Load configuration from JSON file
  static Future<OnboardingConfig> loadFromAssets(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return OnboardingConfig.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load onboarding config: $e');
    }
  }

  /// Create configuration from JSON
  factory OnboardingConfig.fromJson(Map<String, dynamic> json) {
    try {
      final appConfig = json['app_config'] as Map<String, dynamic>;
      final themeData = json['theme'] as Map<String, dynamic>;
      final pagesData = json['onboarding_pages'] as List<dynamic>;
      final uiElementsData = json['ui_elements'] as Map<String, dynamic>;
      final phoneMockupData = json['phone_mockup'] as Map<String, dynamic>;
      final animationsData = json['animations'] as Map<String, dynamic>;
      final navigationData = json['navigation'] as Map<String, dynamic>;

      return OnboardingConfig(
        appName: appConfig['app_name'] as String,
        tagline: appConfig['tagline'] as String,
        theme: ThemeConfig.fromJson(themeData),
        pages: pagesData
            .map((page) =>
                OnboardingPageModel.fromJson(page as Map<String, dynamic>))
            .toList(),
        uiElements: UIElements.fromJson(uiElementsData),
        phoneMockup: PhoneMockupConfig.fromJson(phoneMockupData),
        animations: AnimationConfig.fromJson(animationsData),
        navigation: NavigationConfig.fromJson(navigationData),
      );
    } catch (e) {
      throw Exception('Failed to parse onboarding config: $e');
    }
  }

  /// Convert hex color string to Color
  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// Theme configuration
class ThemeConfig {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundDark;
  final Color backgroundDarker;
  final Color textPrimary;
  final Color textSecondary;
  final GradientColors buttonGradient;

  ThemeConfig({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundDark,
    required this.backgroundDarker,
    required this.textPrimary,
    required this.textSecondary,
    required this.buttonGradient,
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    final gradientData = json['button_gradient'] as Map<String, dynamic>;

    return ThemeConfig(
      primaryColor: OnboardingConfig.hexToColor(json['primary_color'] as String),
      secondaryColor: OnboardingConfig.hexToColor(json['secondary_color'] as String),
      accentColor: OnboardingConfig.hexToColor(json['accent_color'] as String),
      backgroundDark: OnboardingConfig.hexToColor(json['background_dark'] as String),
      backgroundDarker: OnboardingConfig.hexToColor(json['background_darker'] as String),
      textPrimary: OnboardingConfig.hexToColor(json['text_primary'] as String),
      textSecondary: OnboardingConfig.hexToColor(json['text_secondary'] as String),
      buttonGradient: GradientColors(
        startColor: OnboardingConfig.hexToColor(gradientData['start_color'] as String),
        endColor: OnboardingConfig.hexToColor(gradientData['end_color'] as String),
      ),
    );
  }
}

/// Gradient color configuration
class GradientColors {
  final Color startColor;
  final Color endColor;

  GradientColors({
    required this.startColor,
    required this.endColor,
  });

  LinearGradient toLinearGradient() {
    return LinearGradient(
      colors: [startColor, endColor],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }
}

/// UI Elements configuration
class UIElements {
  final ButtonConfig skipButton;
  final ButtonConfig backButton;
  final ButtonConfig continueButton;
  final ButtonConfig getStartedButton;
  final PageIndicatorConfig pageIndicators;

  UIElements({
    required this.skipButton,
    required this.backButton,
    required this.continueButton,
    required this.getStartedButton,
    required this.pageIndicators,
  });

  factory UIElements.fromJson(Map<String, dynamic> json) {
    return UIElements(
      skipButton: ButtonConfig.fromJson(json['skip_button'] as Map<String, dynamic>),
      backButton: ButtonConfig.fromJson(json['back_button'] as Map<String, dynamic>),
      continueButton: ButtonConfig.fromJson(json['continue_button'] as Map<String, dynamic>),
      getStartedButton: ButtonConfig.fromJson(json['get_started_button'] as Map<String, dynamic>),
      pageIndicators: PageIndicatorConfig.fromJson(json['page_indicators'] as Map<String, dynamic>),
    );
  }
}

/// Button configuration
class ButtonConfig {
  final String text;
  final bool show;
  final String? position;
  final bool? showOnFirstPage;
  final bool? showOnLastPage;
  final String style;

  ButtonConfig({
    required this.text,
    required this.show,
    this.position,
    this.showOnFirstPage,
    this.showOnLastPage,
    required this.style,
  });

  factory ButtonConfig.fromJson(Map<String, dynamic> json) {
    return ButtonConfig(
      text: json['text'] as String,
      show: json['show'] as bool? ?? true,
      position: json['position'] as String?,
      showOnFirstPage: json['show_on_first_page'] as bool?,
      showOnLastPage: json['show_on_last_page'] as bool?,
      style: json['style'] as String? ?? 'filled',
    );
  }
}

/// Page indicator configuration
class PageIndicatorConfig {
  final String type;
  final double activeWidth;
  final double inactiveWidth;
  final double height;
  final double spacing;
  final Color activeColor;
  final Color inactiveColor;
  final int animationDurationMs;

  PageIndicatorConfig({
    required this.type,
    required this.activeWidth,
    required this.inactiveWidth,
    required this.height,
    required this.spacing,
    required this.activeColor,
    required this.inactiveColor,
    required this.animationDurationMs,
  });

  factory PageIndicatorConfig.fromJson(Map<String, dynamic> json) {
    return PageIndicatorConfig(
      type: json['type'] as String,
      activeWidth: (json['active_width'] as num).toDouble(),
      inactiveWidth: (json['inactive_width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      spacing: (json['spacing'] as num).toDouble(),
      activeColor: OnboardingConfig.hexToColor(json['active_color'] as String),
      inactiveColor: OnboardingConfig.hexToColor(json['inactive_color'] as String),
      animationDurationMs: json['animation_duration_ms'] as int,
    );
  }
}

/// Phone mockup configuration
class PhoneMockupConfig {
  final bool show;
  final String style;
  final double borderWidth;
  final Color borderColor;
  final double cornerRadius;
  final double notchWidth;
  final double notchHeight;
  final ShadowConfig shadow;
  final double contentPadding;

  PhoneMockupConfig({
    required this.show,
    required this.style,
    required this.borderWidth,
    required this.borderColor,
    required this.cornerRadius,
    required this.notchWidth,
    required this.notchHeight,
    required this.shadow,
    required this.contentPadding,
  });

  factory PhoneMockupConfig.fromJson(Map<String, dynamic> json) {
    return PhoneMockupConfig(
      show: json['show'] as bool,
      style: json['style'] as String,
      borderWidth: (json['border_width'] as num).toDouble(),
      borderColor: OnboardingConfig.hexToColor(json['border_color'] as String),
      cornerRadius: (json['corner_radius'] as num).toDouble(),
      notchWidth: (json['notch_width'] as num).toDouble(),
      notchHeight: (json['notch_height'] as num).toDouble(),
      shadow: ShadowConfig.fromJson(json['shadow'] as Map<String, dynamic>),
      contentPadding: (json['content_padding'] as num).toDouble(),
    );
  }
}

/// Shadow configuration
class ShadowConfig {
  final Color color;
  final double blurRadius;
  final double spreadRadius;

  ShadowConfig({
    required this.color,
    required this.blurRadius,
    required this.spreadRadius,
  });

  factory ShadowConfig.fromJson(Map<String, dynamic> json) {
    return ShadowConfig(
      color: OnboardingConfig.hexToColor(json['color'] as String),
      blurRadius: (json['blur_radius'] as num).toDouble(),
      spreadRadius: (json['spread_radius'] as num).toDouble(),
    );
  }

  BoxShadow toBoxShadow() {
    return BoxShadow(
      color: color,
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
    );
  }
}

/// Animation configuration
class AnimationConfig {
  final int pageTransitionDurationMs;
  final String pageTransitionCurve;
  final int backgroundFadeDurationMs;
  final int indicatorAnimationDurationMs;

  AnimationConfig({
    required this.pageTransitionDurationMs,
    required this.pageTransitionCurve,
    required this.backgroundFadeDurationMs,
    required this.indicatorAnimationDurationMs,
  });

  factory AnimationConfig.fromJson(Map<String, dynamic> json) {
    return AnimationConfig(
      pageTransitionDurationMs: json['page_transition_duration_ms'] as int,
      pageTransitionCurve: json['page_transition_curve'] as String,
      backgroundFadeDurationMs: json['background_fade_duration_ms'] as int,
      indicatorAnimationDurationMs: json['indicator_animation_duration_ms'] as int,
    );
  }

  /// Get curve based on string name
  Curve getCurve() {
    switch (pageTransitionCurve.toLowerCase()) {
      case 'easein':
        return Curves.easeIn;
      case 'easeout':
        return Curves.easeOut;
      case 'easeinout':
        return Curves.easeInOut;
      case 'linear':
        return Curves.linear;
      case 'decelerate':
        return Curves.decelerate;
      case 'fastoutslowIn':
        return Curves.fastOutSlowIn;
      default:
        return Curves.easeInOut;
    }
  }
}

/// Navigation configuration
class NavigationConfig {
  final String onCompleteRoute;
  final String onSkipRoute;
  final bool allowBackNavigation;

  NavigationConfig({
    required this.onCompleteRoute,
    required this.onSkipRoute,
    required this.allowBackNavigation,
  });

  factory NavigationConfig.fromJson(Map<String, dynamic> json) {
    return NavigationConfig(
      onCompleteRoute: json['on_complete_route'] as String,
      onSkipRoute: json['on_skip_route'] as String,
      allowBackNavigation: json['allow_back_navigation'] as bool,
    );
  }
}
