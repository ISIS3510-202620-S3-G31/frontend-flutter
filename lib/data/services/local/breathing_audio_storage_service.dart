import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Handles physical file storage for cached breathing audio tracks.
class BreathingAudioStorageService {
  Directory? _cacheDir;

  Future<Directory> get cacheDirectory async {
    if (_cacheDir != null) return _cacheDir!;
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(documents.path, 'breathing_audio_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  /// Gets the full local file path where a track with [trackId] should be stored.
  Future<String> getFilePathForTrack(String trackId) async {
    final dir = await cacheDirectory;
    final sanitizedId = trackId.replaceAll(RegExp(r'[^\w\.-]'), '_');
    return p.join(dir.path, '$sanitizedId.mp3');
  }

  /// Checks if the cached audio file for [trackId] exists and is non-empty.
  Future<bool> hasCachedFile(String trackId) async {
    final path = await getFilePathForTrack(trackId);
    final file = File(path);
    return (await file.exists()) && (await file.length()) > 0;
  }

  /// Returns the cached audio file if it exists, otherwise null.
  Future<File?> getCachedFile(String trackId) async {
    final path = await getFilePathForTrack(trackId);
    final file = File(path);
    if ((await file.exists()) && (await file.length()) > 0) {
      return file;
    }
    return null;
  }

  /// Deletes a cached track audio file.
  Future<void> deleteCachedFile(String trackId) async {
    final path = await getFilePathForTrack(trackId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Clears all cached audio files.
  Future<void> clearAllCache() async {
    final dir = await cacheDirectory;
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
  }

  /// Calculates total size of all cached tracks in bytes.
  Future<int> getCacheSizeBytes() async {
    final dir = await cacheDirectory;
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
