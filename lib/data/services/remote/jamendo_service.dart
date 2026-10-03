import 'dart:convert';
import 'dart:io';

import '../../models/breathing_music_model.dart';

class JamendoService {
  JamendoService({String? clientId, HttpClient? httpClient})
    : clientId = clientId ?? defaultClientId,
      _client = httpClient ?? HttpClient();

  static const String defaultClientId = 'a74e6c84';
  static const String _baseUrl = 'https://api.jamendo.com/v3.0';

  final String clientId;
  final HttpClient _client;

  /// Fetches ambient instrumental tracks from Jamendo API.
  /// Falls back to the curated tracks if network request fails or device is offline.
  Future<List<BreathingMusicTrack>> fetchAmbientTracks({
    int limit = 10,
    String tags = 'ambient+instrumental',
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/tracks/?client_id=$clientId&format=json&limit=$limit&tags=$tags&audioformat=mp32',
    );

    try {
      final request = await _client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final results = (data['results'] as List<dynamic>?) ?? [];

        final fetchedTracks = results
            .whereType<Map<String, dynamic>>()
            .map((item) => BreathingMusicTrack.fromJamendoJson(item))
            .where((track) => track.audioUrl.isNotEmpty)
            .toList();

        if (fetchedTracks.isNotEmpty) {
          // Prepend curated tracks if not already present to guarantee their availability
          final trackMap = <String, BreathingMusicTrack>{};
          for (final track in BreathingMusicTrack.curatedTracks) {
            trackMap[track.id] = track;
          }
          for (final track in fetchedTracks) {
            trackMap[track.id] = track;
          }
          return trackMap.values.toList();
        }
      }
    } catch (_) {
      // fallback gracefully
    }

    return List.from(BreathingMusicTrack.curatedTracks);
  }

  // Download tracks ig
  Future<File> downloadTrackToFile(
    String audioUrl,
    String destinationPath,
  ) async {
    final destinationFile = File(destinationPath);
    final tempFile = File('$destinationPath.tmp');

    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      await tempFile.parent.create(recursive: true);

      final uri = Uri.parse(audioUrl);
      final request = await _client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException(
          'Jamendo audio download failed with status ${response.statusCode}',
          uri: uri,
        );
      }

      final sink = tempFile.openWrite();
      await response.pipe(sink);
      await sink.flush();
      await sink.close();

      if (await destinationFile.exists()) {
        await destinationFile.delete();
      }
      await tempFile.rename(destinationPath);
      return destinationFile;
    } catch (e) {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }
}
