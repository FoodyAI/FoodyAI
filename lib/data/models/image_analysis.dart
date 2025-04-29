class ImageAnalysis {
  /// The textual description returned by the AI model.
  final String description;

  /// Optional error message if something went wrong.
  final String? error;

  ImageAnalysis({
    required this.description,
    this.error,
  });

  /// Parse a successful response JSON:
  ///   { "description": "...", "error": null }
  factory ImageAnalysis.fromJson(Map<String, dynamic> json) {
    return ImageAnalysis(
      description: json['description'] as String? ?? '',
      error: json['error'] as String?,
    );
  }

  /// Construct an instance representing an error:
  factory ImageAnalysis.error(String errorMessage) {
    return ImageAnalysis(description: '', error: errorMessage);
  }
}
