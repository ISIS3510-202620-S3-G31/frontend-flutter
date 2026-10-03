import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

import '../models/breathing_music_model.dart';
import '../services/local/breathing_audio_storage_service.dart';
import '../services/local/breathing_local_database_service.dart';
import '../services/network/network_connectivity_service.dart';
import '../services/remote/jamendo_service.dart';

/// Repository coordinating Jamendo music tracks, local file caching, and SQLite persistence for breathing exercises.
class BreathingRepository {
  BreathingRepository({
    JamendoService? jamendoService,
    BreathingAudioStorageService? storageService,
    BreathingLocalDatabaseService? databaseService,
    NetworkConnectivityService? connectivityService,
  }) : _jamendo = jamendoService ?? JamendoService(),
       _storage = storageService ?? BreathingAudioStorageService(),
       _db = databaseService ?? BreathingLocalDatabaseService(),
       _connectivity = connectivityService ?? NetworkConnectivityService();

  final JamendoService _jamendo;
  final BreathingAudioStorageService _storage;
  final BreathingLocalDatabaseService _db;
  final NetworkConnectivityService _connectivity;

  final StreamController<BreathingMusicTrack> _trackCachedController =
      StreamController<BreathingMusicTrack>.broadcast();

  /// Stream emitting when a track has completed background or explicit caching.
  Stream<BreathingMusicTrack> get onTrackCached =>
      _trackCachedController.stream;

  Future<bool> isOnline() => _connectivity.checkOnline();

  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged;

  Future<List<BreathingMusicTrack>> getTracks({
    bool refreshFromRemote = false,
  }) async {
    final online = await isOnline();

    // 1. Fetch tracks currently stored in local database
    var localTracks = await _db.getTracks();

    // 2. If DB is empty, seed with the curated tracks
    if (localTracks.isEmpty) {
      localTracks = List.from(BreathingMusicTrack.curatedTracks);
      await _db.saveTracks(localTracks);
    }

    // 3. If online and either refresh requested or we only have seeds, try Jamendo API
    if (online &&
        (refreshFromRemote ||
            localTracks.length <= BreathingMusicTrack.curatedTracks.length)) {
      try {
        final remoteTracks = await _jamendo.fetchAmbientTracks();
        if (remoteTracks.isNotEmpty) {
          // Merge remote tracks preserving any existing cached paths
          final localMap = {for (final t in localTracks) t.id: t};
          final merged = remoteTracks.map((remote) {
            final existing = localMap[remote.id];
            if (existing != null && existing.isCached) {
              return remote.copyWith(
                isCached: true,
                cachedFilePath: existing.cachedFilePath,
                lastPlayedAt: existing.lastPlayedAt,
              );
            }
            return remote;
          }).toList();

          await _db.saveTracks(merged);
          localTracks = merged;
        }
      } catch (_) {
        // If remote fetch fails, fallback to localTracks
      }
    }

    // 4. Validate physical cache files on disk for each track
    final verifiedTracks = <BreathingMusicTrack>[];
    for (final track in localTracks) {
      final hasFile = await _storage.hasCachedFile(track.id);
      final filePath = hasFile
          ? await _storage.getFilePathForTrack(track.id)
          : null;
      if (track.isCached != hasFile || track.cachedFilePath != filePath) {
        await _db.updateTrackCacheStatus(
          track.id,
          isCached: hasFile,
          cachedFilePath: filePath,
        );
        verifiedTracks.add(
          track.copyWith(isCached: hasFile, cachedFilePath: filePath),
        );
      } else {
        verifiedTracks.add(track);
      }
    }

    return verifiedTracks;
  }

  Future<Source> resolveAudioSource(BreathingMusicTrack track) async {
    // Check if physically cached on disk
    final cachedFile = await _storage.getCachedFile(track.id);
    if (cachedFile != null) {
      await _db.recordTrackPlayed(track.id);
      return DeviceFileSource(cachedFile.path);
    }

    // Not cached yet: check internet connectivity
    final online = await isOnline();
    if (!online) {
      throw const SocketException(
        'This track is not available offline. Please connect to the internet to listen and cache it.',
      );
    }

    // Trigger background caching so next time it is played offline from local storage
    unawaited(_cacheTrackInBackground(track));

    await _db.recordTrackPlayed(track.id);
    return UrlSource(track.audioUrl);
  }

  /// Downloads and caches a track explicitly (e.g. user pressed download button).
  Future<BreathingMusicTrack> downloadAndCacheTrack(
    BreathingMusicTrack track,
  ) async {
    final destinationPath = await _storage.getFilePathForTrack(track.id);
    await _jamendo.downloadTrackToFile(track.audioUrl, destinationPath);

    await _db.updateTrackCacheStatus(
      track.id,
      isCached: true,
      cachedFilePath: destinationPath,
    );

    final updatedTrack = track.copyWith(
      isCached: true,
      cachedFilePath: destinationPath,
    );

    _trackCachedController.add(updatedTrack);
    return updatedTrack;
  }

  /// Background caching handler that does not throw to the caller.
  Future<void> _cacheTrackInBackground(BreathingMusicTrack track) async {
    try {
      await downloadAndCacheTrack(track);
    } catch (_) {
      // Background caching failed silently, playback was unaffected
    }
  }

  /// Removes a cached track file from local storage and updates the database.
  Future<BreathingMusicTrack> removeCachedTrack(
    BreathingMusicTrack track,
  ) async {
    await _storage.deleteCachedFile(track.id);
    await _db.updateTrackCacheStatus(
      track.id,
      isCached: false,
      cachedFilePath: null,
    );
    final updated = track.copyWith(isCached: false, cachedFilePath: null);
    _trackCachedController.add(updated);
    return updated;
  }

  Future<String?> getSelectedTrackId() => _db.getSelectedTrackId();

  Future<void> setSelectedTrackId(String id) => _db.setSelectedTrackId(id);

  Future<bool> isMusicEnabled() => _db.isMusicEnabled();

  Future<void> setMusicEnabled(bool enabled) => _db.setMusicEnabled(enabled);

  void dispose() {
    _trackCachedController.close();
  }
}
