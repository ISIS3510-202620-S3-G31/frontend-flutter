import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

import '../models/breathing_model.dart';
import '../services/local/breathing_audio_storage_service.dart';
import '../services/local/breathing_local_database_service.dart';
import '../services/network/network_connectivity_service.dart';
import '../services/remote/jamendo_service.dart';

/// Repository coordinating Jamendo music tracks, local file caching, and SQLite persistence for breathing exercises.
class BreathingRepository {
  /// With no dependencies, returns one shared instance for the whole app so its in-memory caches survive navigating between tools. Pass any dependency to get a standalone instance (e.g. in tests).
  factory BreathingRepository({
    JamendoService? jamendoService,
    BreathingAudioStorageService? storageService,
    BreathingLocalDatabaseService? databaseService,
    NetworkConnectivityService? connectivityService,
  }) {
    if (jamendoService != null ||
        storageService != null ||
        databaseService != null ||
        connectivityService != null) {
      return BreathingRepository._internal(
        jamendoService,
        storageService,
        databaseService,
        connectivityService,
      );
    }
    return _instance ??= BreathingRepository._internal(null, null, null, null);
  }

  BreathingRepository._internal(
    JamendoService? jamendoService,
    BreathingAudioStorageService? storageService,
    BreathingLocalDatabaseService? databaseService,
    NetworkConnectivityService? connectivityService,
  ) : _jamendo = jamendoService ?? JamendoService(),
      _storage = storageService ?? BreathingAudioStorageService(),
      _db = databaseService ?? BreathingLocalDatabaseService(),
      _connectivity = connectivityService ?? NetworkConnectivityService();

  static BreathingRepository? _instance;

  final JamendoService _jamendo;
  final BreathingAudioStorageService _storage;
  final BreathingLocalDatabaseService _db;
  final NetworkConnectivityService _connectivity;

  /// In-memory layer of the last-started-pattern cache. Reads are synchronous and instant; writes go through to SQLite so the value also survives app restarts.
  BreathingPattern? _lastStartedPattern;

  /// In-memory layer of the last-session-duration cache; same write-through strategy as [_lastStartedPattern].
  int? _lastSessionMinutes;

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

  /// The last breathing pattern a session was started with, read from the in-memory cache. Synchronous on purpose: when the cache is warm the breathing tool can preselect the pattern without awaiting anything. Null on a cold start until [loadLastStartedPattern] hydrates the cache.
  BreathingPattern? get lastStartedPattern => _lastStartedPattern;

  /// Cache-aside load: returns the in-memory value if the cache is warm, otherwise reads the persisted value from SQLite, warms the cache with it, and returns it. Call once at startup.
  Future<BreathingPattern?> loadLastStartedPattern() async {
    final cached = _lastStartedPattern;
    if (cached != null) return cached;
    final stored = await _db.getLastStartedPattern();
    if (stored != null) {
      _lastStartedPattern = stored;
    }
    return stored;
  }

  /// Write-through save: updates the in-memory cache immediately and persists [pattern] to SQLite, so it is still there after an app restart.
  Future<void> rememberStartedPattern(BreathingPattern pattern) async {
    _lastStartedPattern = pattern;
    await _db.setLastStartedPattern(pattern);
  }

  /// The last selected session duration in minutes, read from the in-memory cache. Null on a cold start until [loadLastSessionMinutes] hydrates the cache.
  int? get lastSessionMinutes => _lastSessionMinutes;

  /// Cache-aside load of the last selected session duration; see [loadLastStartedPattern].
  Future<int?> loadLastSessionMinutes() async {
    final cached = _lastSessionMinutes;
    if (cached != null) return cached;
    final stored = await _db.getLastSessionMinutes();
    if (stored != null) {
      _lastSessionMinutes = stored;
    }
    return stored;
  }

  /// Write-through save of the selected session duration; see [rememberStartedPattern].
  Future<void> rememberSessionMinutes(int minutes) async {
    _lastSessionMinutes = minutes;
    await _db.setLastSessionMinutes(minutes);
  }

  void dispose() {
    _trackCachedController.close();
  }
}
