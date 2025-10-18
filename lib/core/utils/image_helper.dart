import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Utility class for handling image display in the Foody app
/// Supports both local file paths and S3 URLs with proper caching
class ImageHelper {
  // In-memory cache to store fetched image bytes
  static final Map<String, Uint8List> _imageCache = {};
  
  // Track which local paths have been verified to exist
  static final Map<String, bool> _localFileExistsCache = {};

  /// Determines if the imagePath is an S3 URL or local file path
  static bool isS3Url(String? imagePath) {
    return imagePath != null && imagePath.startsWith('s3://');
  }

  /// Determines if the imagePath is a local file path
  static bool isLocalPath(String? imagePath) {
    return imagePath != null &&
        !imagePath.startsWith('s3://') &&
        !imagePath.startsWith('http');
  }

  /// Checks if local file exists (with caching)
  static Future<bool> localFileExists(String? filePath) async {
    if (filePath == null || !isLocalPath(filePath)) return false;
    
    // Check cache first
    if (_localFileExistsCache.containsKey(filePath)) {
      return _localFileExistsCache[filePath]!;
    }
    
    try {
      final file = File(filePath);
      final exists = await file.exists();
      _localFileExistsCache[filePath] = exists;
      return exists;
    } catch (e) {
      _localFileExistsCache[filePath] = false;
      return false;
    }
  }

  /// Clears the image cache (useful when user signs out)
  static void clearCache() {
    _imageCache.clear();
    _localFileExistsCache.clear();
    _imageSourceCache.clear();
    print('🗑️ ImageHelper: All caches cleared');
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
        borderRadius:
            borderRadius != null ? BorderRadius.circular(borderRadius) : null,
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
        borderRadius:
            borderRadius != null ? BorderRadius.circular(borderRadius) : null,
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
      headers: const {
        'Accept': 'image/*',
        'User-Agent': 'FoodyApp/1.0',
      },
    );
  }

  /// Builds an S3 image widget that fetches base64 data and converts to image
  /// Uses in-memory cache to avoid re-fetching on every rebuild
  static Widget _buildS3ImageFromBase64({
    required String imagePath,
    required double width,
    required double height,
    required BoxFit fit,
    required Widget Function(BuildContext, Object, StackTrace?) errorBuilder,
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder,
  }) {
    // Check if image is already in cache
    if (_imageCache.containsKey(imagePath)) {
      final cachedBytes = _imageCache[imagePath]!;
      print('✅ ImageHelper: Using cached image (${cachedBytes.length} bytes)');
      
      return Image.memory(
        cachedBytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          print('❌ ImageHelper: Failed to decode cached image from bytes');
          print('❌ ImageHelper: Error: $error');
          return errorBuilder(context, error, stackTrace);
        },
      );
    }

    // Image not in cache, fetch it
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
  /// Caches the result in memory to avoid repeated network calls
  static Future<Uint8List> _getImageBytesFromS3(String s3Url) async {
    // Check cache first
    if (_imageCache.containsKey(s3Url)) {
      print('✅ ImageHelper: Returning cached image bytes');
      return _imageCache[s3Url]!;
    }

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

        // Cache the bytes
        _imageCache[s3Url] = imageBytes;
        print('💾 ImageHelper: Cached image bytes for: $s3Url');

        return imageBytes;
      } else {
        throw Exception(
            'Failed to get image data: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ ImageHelper: Error fetching image data: $e');
      rethrow;
    }
  }

  // Cache for determined image sources (keyed by a combination of paths)
  static final Map<String, _ImageSource> _imageSourceCache = {};

  /// Creates appropriate image widget for FoodAnalysis with hybrid local/S3 support
  /// This properly handles offline-first with validation and fallback
  /// OPTIMIZED: Caches source determination to avoid blink on refresh
  ///
  /// Parameters:
  /// - [analysis]: FoodAnalysis object with local and S3 image paths
  /// - [width]: Image width
  /// - [height]: Image height
  /// - [fit]: How the image should fit within the bounds
  /// - [errorBuilder]: Widget to show if image fails to load
  /// - [loadingBuilder]: Optional loading widget for network images
  static Widget buildHybridImageWidget({
    required dynamic analysis, // FoodAnalysis object
    required double width,
    required double height,
    required BoxFit fit,
    required Widget Function(BuildContext, Object, StackTrace?) errorBuilder,
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder,
  }) {
    // Create a unique key for this analysis based on its image paths
    final cacheKey = _createCacheKey(analysis);
    
    // Check if we've already determined the source for this analysis
    if (_imageSourceCache.containsKey(cacheKey)) {
      final cachedSource = _imageSourceCache[cacheKey]!;
      print('⚡ ImageHelper: Using cached source determination');
      
      return _buildImageFromSource(
        imageSource: cachedSource,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
        loadingBuilder: loadingBuilder,
      );
    }

    // First time seeing this analysis - determine source with FutureBuilder
    return FutureBuilder<_ImageSource>(
      future: _determineImageSource(analysis),
      builder: (context, snapshot) {
        // While determining source, show loading if available
        if (snapshot.connectionState == ConnectionState.waiting) {
          return createLoadingWidget(
            width: width,
            height: height,
            backgroundColor: Colors.grey[300],
          );
        }

        // If determination failed, show error
        if (snapshot.hasError || !snapshot.hasData) {
          return errorBuilder(
            context,
            snapshot.error ?? 'No image source available',
            null,
          );
        }

        final imageSource = snapshot.data!;
        
        // Cache the determined source for future rebuilds
        _imageSourceCache[cacheKey] = imageSource;
        print('💾 ImageHelper: Cached source determination for: $cacheKey');

        return _buildImageFromSource(
          imageSource: imageSource,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
          loadingBuilder: loadingBuilder,
        );
      },
    );
  }

  /// Creates a cache key from analysis image paths
  static String _createCacheKey(dynamic analysis) {
    final local = analysis.localImagePath ?? '';
    final s3 = analysis.s3ImageUrl ?? '';
    final legacy = analysis.imagePath ?? '';
    return '$local|$s3|$legacy';
  }

  /// Builds image widget from a determined image source
  static Widget _buildImageFromSource({
    required _ImageSource imageSource,
    required double width,
    required double height,
    required BoxFit fit,
    required Widget Function(BuildContext, Object, StackTrace?) errorBuilder,
    Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder,
  }) {
    switch (imageSource.type) {
      case _ImageSourceType.local:
        print('📱 ImageHelper: Using LOCAL image: ${imageSource.path}');
        return Image.file(
          File(imageSource.path!),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
        );

      case _ImageSourceType.s3:
        print('☁️ ImageHelper: Using S3 image: ${imageSource.path}');
        return _buildS3ImageFromBase64(
          imagePath: imageSource.path!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
          loadingBuilder: loadingBuilder,
        );

      case _ImageSourceType.network:
        print('🌐 ImageHelper: Using NETWORK image: ${imageSource.path}');
        return buildNetworkImageWithRetry(
          imageUrl: imageSource.path!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
          loadingBuilder: loadingBuilder,
        );

      case _ImageSourceType.none:
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        );
    }
  }

  /// Determines the best image source to use (local or S3)
  /// OFFLINE-FIRST: Prioritizes local file if it exists
  static Future<_ImageSource> _determineImageSource(dynamic analysis) async {
    // 1. Check if local file exists and is valid
    if (analysis.localImagePath != null &&
        analysis.localImagePath.isNotEmpty) {
      final localExists = await localFileExists(analysis.localImagePath);
      if (localExists) {
        print('✅ ImageHelper: Local file exists: ${analysis.localImagePath}');
        return _ImageSource(
          type: _ImageSourceType.local,
          path: analysis.localImagePath,
        );
      } else {
        print('⚠️ ImageHelper: Local file does NOT exist: ${analysis.localImagePath}');
      }
    }

    // 2. Try s3ImageUrl field (could be S3 URL or HTTP/HTTPS network URL)
    if (analysis.s3ImageUrl != null && analysis.s3ImageUrl.isNotEmpty) {
      final url = analysis.s3ImageUrl as String;

      // Check if it's an S3 URL (s3://)
      if (isS3Url(url)) {
        print('☁️ ImageHelper: Using S3 URL: $url');
        return _ImageSource(
          type: _ImageSourceType.s3,
          path: url,
        );
      }

      // Check if it's a regular HTTP/HTTPS URL (like OpenFoodFacts images)
      if (url.startsWith('http://') || url.startsWith('https://')) {
        print('🌐 ImageHelper: Using network URL: $url');
        return _ImageSource(
          type: _ImageSourceType.network,
          path: url,
        );
      }
    }

    // 3. Try legacy imagePath field
    if (analysis.imagePath != null && analysis.imagePath.isNotEmpty) {
      if (isS3Url(analysis.imagePath)) {
        print('☁️ ImageHelper: Using legacy S3 URL: ${analysis.imagePath}');
        return _ImageSource(
          type: _ImageSourceType.s3,
          path: analysis.imagePath,
        );
      } else {
        // Legacy local path - verify it exists
        final localExists = await localFileExists(analysis.imagePath);
        if (localExists) {
          print('✅ ImageHelper: Legacy local file exists: ${analysis.imagePath}');
          return _ImageSource(
            type: _ImageSourceType.local,
            path: analysis.imagePath,
          );
        } else {
          print('⚠️ ImageHelper: Legacy local file does NOT exist: ${analysis.imagePath}');
        }
      }
    }

    // 4. No valid image source found
    print('❌ ImageHelper: No valid image source found');
    return _ImageSource(type: _ImageSourceType.none);
  }
}

/// Internal class to represent image source determination result
enum _ImageSourceType { local, s3, network, none }

class _ImageSource {
  final _ImageSourceType type;
  final String? path;

  _ImageSource({required this.type, this.path});
}