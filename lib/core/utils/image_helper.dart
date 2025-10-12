import 'dart:io';
import 'package:flutter/material.dart';

/// Utility class for handling image display in the Foody app
/// Supports both local file paths and S3 URLs
class ImageHelper {
  /// Determines if the imagePath is an S3 URL or local file path
  static bool isS3Url(String? imagePath) {
    return imagePath != null && imagePath.startsWith('s3://');
  }

  /// Converts S3 URL to image serve endpoint URL
  /// Example: s3://bucket/key -> https://api.foody.com/image-serve?key=key
  static String s3UrlToImageServeUrl(String s3Url) {
    // Extract the key from s3://bucket/key format
    final parts = s3Url.replaceFirst('s3://', '').split('/');
    if (parts.length >= 2) {
      final key = parts.sublist(1).join('/');
      return 'https://xpdvcgcji6.execute-api.us-east-1.amazonaws.com/prod/image-serve?key=$key';
    }
    return s3Url; // Return original if parsing fails
  }

  /// Creates appropriate image widget for both local files and S3 URLs
  /// 
  /// Parameters:
  /// - [imagePath]: Either a local file path or S3 URL
  /// - [width]: Image width
  /// - [height]: Image height
  /// - [fit]: How the image should fit within the bounds
  /// - [errorBuilder]: Widget to show if image fails to load
  /// - [loadingBuilder]: Optional loading widget for network images
  static Widget buildImageWidget({
    required String? imagePath,
    required double width,
    required double height,
    required BoxFit fit,
    required Widget Function(BuildContext, Object, StackTrace?) errorBuilder,
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder,
  }) {
    if (imagePath == null) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      );
    }

    if (isS3Url(imagePath)) {
      // Use Image.network for S3 URLs
      final imageUrl = s3UrlToImageServeUrl(imagePath);
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
        loadingBuilder: loadingBuilder,
      );
    } else {
      // Use Image.file for local file paths
      return Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
  }

  /// Creates a loading widget for network images
  static Widget createLoadingWidget({
    required double width,
    required double height,
    Color? backgroundColor,
    double? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[300],
        borderRadius: borderRadius != null 
            ? BorderRadius.circular(borderRadius) 
            : null,
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Creates an error placeholder widget
  static Widget createErrorWidget({
    required double width,
    required double height,
    Color? backgroundColor,
    double? borderRadius,
    IconData? icon,
    String? text,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[300],
        borderRadius: borderRadius != null 
            ? BorderRadius.circular(borderRadius) 
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.image_not_supported,
            size: width * 0.3,
            color: Colors.grey[600],
          ),
          if (text != null) ...[
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
