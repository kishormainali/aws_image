import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// {@template aws_cache_manager}
/// Manages local caching of AWS S3 images with expiration support.
///
/// This manager handles:
/// - Storing images on disk with metadata
/// - Checking cache validity based on duration
/// - Automatic cache invalidation for expired entries
/// - Cache cleanup operations
///
/// ## Usage
///
/// ```dart
/// final cacheManager = AwsCacheManager.instance;
///
/// // Cache an image
/// await cacheManager.cacheImage('my-key', imageBytes);
///
/// // Check if cache is valid
/// final isValid = await cacheManager.isCacheValid(
///   'my-key',
///   const Duration(days: 7),
/// );
///
/// // Get cached image
/// if (isValid) {
///   final bytes = await cacheManager.getFromCache('my-key');
/// }
/// ```
/// {@endtemplate}
class AwsCacheManager {
  AwsCacheManager._();

  /// Singleton instance of the cache manager.
  static final AwsCacheManager instance = AwsCacheManager._();

  static const String _cacheDir = 'aws_image_cache';
  static const String _metadataExtension = '.meta';

  /// cache directory
  Directory? _cacheDirectory;

  /// Gets or creates the cache directory.
  Future<Directory> get cacheDirectory async {
    if (_cacheDirectory != null) return _cacheDirectory!;

    final appDir = await getTemporaryDirectory();
    _cacheDirectory = Directory(path.join(appDir.path, _cacheDir));

    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }

    return _cacheDirectory!;
  }

  /// Returns the file path for a cache key.
  Future<String> _getFilePath(String key) async {
    final dir = await cacheDirectory;
    final sanitizedKey = _sanitizeKey(key);
    return path.join(dir.path, sanitizedKey);
  }

  /// Returns the metadata file path for a cache key.
  Future<String> _getMetadataPath(String key) async {
    final filePath = await _getFilePath(key);
    return '$filePath$_metadataExtension';
  }

  /// Sanitizes a cache key for use as a filename.
  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^\w\-.]'), '_');
  }

  /// Caches image bytes with the current timestamp.
  ///
  /// Stores both the image data and a metadata file containing
  /// the cache timestamp for expiration checking.
  Future<void> cacheImage(String key, Uint8List bytes) async {
    final filePath = await _getFilePath(key);
    final metadataPath = await _getMetadataPath(key);

    final file = File(filePath);
    final metadataFile = File(metadataPath);

    await Future.wait([
      file.writeAsBytes(bytes, flush: true),
      metadataFile.writeAsString(
        DateTime.now().millisecondsSinceEpoch.toString(),
        flush: true,
      ),
    ]);
  }

  /// Retrieves cached image bytes if available.
  ///
  /// Returns null if the cache entry doesn't exist.
  Future<Uint8List?> getFromCache(String key) async {
    final filePath = await _getFilePath(key);
    final file = File(filePath);

    if (!await file.exists()) return null;

    return file.readAsBytes();
  }

  /// Checks if a cache entry exists and is within the valid duration.
  ///
  /// Returns `true` if:
  /// - The cache file exists
  /// - The metadata file exists
  /// - The cache age is less than [duration]
  Future<bool> isCacheValid(String key, Duration duration) async {
    final metadataPath = await _getMetadataPath(key);
    final metadataFile = File(metadataPath);

    if (!await metadataFile.exists()) return false;

    try {
      final timestampStr = await metadataFile.readAsString();
      final timestamp = int.parse(timestampStr.trim());
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      return now.difference(cachedAt) < duration;
    } catch (_) {
      // Corrupted metadata, invalidate cache
      await invalidate(key);
      return false;
    }
  }

  /// Returns the cache age for a key, or null if not cached.
  Future<Duration?> getCacheAge(String key) async {
    final metadataPath = await _getMetadataPath(key);
    final metadataFile = File(metadataPath);

    if (!await metadataFile.exists()) return null;

    try {
      final timestampStr = await metadataFile.readAsString();
      final timestamp = int.parse(timestampStr.trim());
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);

      return DateTime.now().difference(cachedAt);
    } catch (_) {
      return null;
    }
  }

  /// Invalidates (deletes) a specific cache entry.
  Future<void> invalidate(String key) async {
    final filePath = await _getFilePath(key);
    final metadataPath = await _getMetadataPath(key);

    await Future.wait([
      _deleteIfExists(File(filePath)),
      _deleteIfExists(File(metadataPath)),
    ]);
  }

  /// Clears all expired cache entries.
  ///
  /// Iterates through all cached files and removes those
  /// older than [maxAge].
  Future<int> clearExpired(Duration maxAge) async {
    final dir = await cacheDirectory;
    var cleared = 0;

    if (!await dir.exists()) return cleared;

    final entities = await dir.list().toList();
    final now = DateTime.now();

    for (final entity in entities) {
      if (entity is! File) continue;
      if (entity.path.endsWith(_metadataExtension)) continue;

      final metadataFile = File('${entity.path}$_metadataExtension');

      if (!await metadataFile.exists()) {
        await _deleteIfExists(entity);
        cleared++;
        continue;
      }

      try {
        final timestampStr = await metadataFile.readAsString();
        final timestamp = int.parse(timestampStr.trim());
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);

        if (now.difference(cachedAt) >= maxAge) {
          await Future.wait([
            _deleteIfExists(entity),
            _deleteIfExists(metadataFile),
          ]);
          cleared++;
        }
      } catch (_) {
        // Corrupted entry, remove both files
        await Future.wait([
          _deleteIfExists(entity),
          _deleteIfExists(metadataFile),
        ]);
        cleared++;
      }
    }

    return cleared;
  }

  /// Clears the entire cache.
  Future<void> clearAll() async {
    final dir = await cacheDirectory;

    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }

    _cacheDirectory = null;
  }

  /// Returns the total cache size in bytes.
  Future<int> getCacheSize() async {
    final dir = await cacheDirectory;

    if (!await dir.exists()) return 0;

    var totalSize = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  /// Returns the number of cached entries.
  Future<int> getCacheCount() async {
    final dir = await cacheDirectory;

    if (!await dir.exists()) return 0;

    var count = 0;
    await for (final entity in dir.list()) {
      if (entity is File && !entity.path.endsWith(_metadataExtension)) {
        count++;
      }
    }

    return count;
  }

  /// Safely deletes a file if it exists.
  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore deletion errors
    }
  }
}
