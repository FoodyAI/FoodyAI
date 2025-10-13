import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      // Use a custom widget that fetches base64 data and converts to image
      return _buildS3ImageFromBase64(
        imagePath: imagePath,
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

  /// Creates a network image with better error handling and retry mechanism
  static Widget buildNetworkImageWithRetry({
    required String imageUrl,
    required double width,
    required double height,
    required BoxFit fit,
    required Widget Function(BuildContext, Object, StackTrace?) errorBuilder,
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder,
    int maxRetries = 3,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        print('❌ ImageHelper: Network image failed: $imageUrl');
        print('❌ ImageHelper: Error: $error');
        return errorBuilder(context, error, stackTrace);
      },
      loadingBuilder: loadingBuilder,
      // Add headers to help with image decoding
      headers: {
        'Accept': 'image/*',
        'User-Agent': 'FoodyApp/1.0',
      },
    );
  }

  /// Builds an S3 image widget that fetches base64 data and converts to image
  static Widget _buildS3ImageFromBase64({
    required String imagePath,
    required double width,
    required double height,
    required BoxFit fit,
    required Widget Function(BuildContext, Object, StackTrace?) errorBuilder,
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder,
  }) {
    return FutureBuilder<Uint8List>(
      future: _getImageBytesFromS3(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (loadingBuilder != null) {
            return createLoadingWidget(
              width: width,
              height: height,
              backgroundColor: Colors.grey[300],
            );
          }
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('❌ ImageHelper: Failed to get image bytes: ${snapshot.error}');
          return errorBuilder(context, snapshot.error!, null);
        }

        if (!snapshot.hasData) {
          return errorBuilder(context, 'No image data available', null);
        }

        final imageBytes = snapshot.data!;
        print('🖼️ ImageHelper: Loading image from bytes (${imageBytes.length} bytes)');

        return Image.memory(
          imageBytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            print('❌ ImageHelper: Failed to decode image from bytes');
            print('❌ ImageHelper: Error: $error');
            return errorBuilder(context, error, stackTrace);
          },
        );
      },
    );
  }

  /// Fetches base64 image data from Lambda and converts to bytes
  static Future<Uint8List> _getImageBytesFromS3(String s3Url) async {
    final imageUrl = s3UrlToImageServeUrl(s3Url);
    print('🔄 ImageHelper: Fetching base64 image data from: $imageUrl');

    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'Accept': 'image/*',
          'User-Agent': 'FoodyApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        // The response body contains base64 encoded image data
        final base64Data = response.body;
        print('✅ ImageHelper: Got base64 data (${base64Data.length} characters)');
        
        // Decode base64 to bytes
        final imageBytes = base64Decode(base64Data);
        print('✅ ImageHelper: Decoded to ${imageBytes.length} bytes');
        
        return imageBytes;
      } else {
        throw Exception('Failed to get image data: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ ImageHelper: Error fetching image data: $e');
      rethrow;
    }
  }
}
