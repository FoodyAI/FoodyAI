class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic data;

  AppError({
    required this.message,
    this.code,
    this.data,
  });

  @override
  String toString() =>
      'AppError: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkError extends AppError {
  NetworkError({
    required String message,
    String? code,
    dynamic data,
  }) : super(
          message: message,
          code: code,
          data: data,
        );
}

class ValidationError extends AppError {
  ValidationError({
    required String message,
    String? code,
    dynamic data,
  }) : super(
          message: message,
          code: code,
          data: data,
        );
}
