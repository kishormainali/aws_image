import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// {@template image_cache_service}
/// A service for caching images.
/// It provides methods for getting, deleting, and clearing the image cache.
/// {@endtemplate}
class ImageCacheService {
  /// {@macro image_cache_service}
  const ImageCacheService._();

  /// Singleton instance of ImageCacheService
  factory ImageCacheService() => const ImageCacheService._();

  /// Get the image from the cache
  Future<Uint8List?> getCachedImage(String cacheKey) async {
    final cachePath = await _getCachedPath(cacheKey);
    final cacheFile = File(cachePath);
    if (await cacheFile.exists()) {
      final lastModified = (await cacheFile.stat()).changed;
      if (DateTime.now().difference(lastModified) <= const Duration(days: 7)) {
        return cacheFile.readAsBytes();
      } else {
        await cacheFile.delete();
      }
    }
    return null;
  }

  /// Deletes the image cache for the given bucket key.
  Future<void> deleteImageCache(String cacheKey) async {
    final filePath = await _getCachedPath(cacheKey);
    final cacheFile = File(join(filePath));
    if (cacheFile.existsSync()) {
      await cacheFile.delete();
    }
  }

  /// Returns the path to the cached image file.
  Future<String> _getCachedPath(String cacheKey) async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(join(tempDir.path, 'aws_image_cache'));
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }
    return join(cacheDir.path, cacheKey);
  }

  /// Caches the unsigned int data to a file.
  Future<void> cacheFile(String cacheKey, Uint8List data) async {
    final cachePath = await _getCachedPath(cacheKey);
    final cacheFile = File(cachePath);
    if (!cacheFile.existsSync()) {
      await cacheFile.create(recursive: true);
    }
    await cacheFile.writeAsBytes(data, flush: true);
  }

  /// Clears the image cache.
  /// Deletes the entire cache directory.
  /// This will remove all cached images.
  Future<void> clearCache() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(join(tempDir.path, 'aws_image_cache'));
    if (cacheDir.existsSync()) {
      await cacheDir.delete(recursive: true);
    }
  }
}
