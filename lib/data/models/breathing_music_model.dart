class BreathingMusicTrack {
  const BreathingMusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.duration = 0,
    this.cachedFilePath,
    this.isCached = false,
    this.lastPlayedAt,
  });

  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final int duration;
  final String? cachedFilePath;
  final bool isCached;
  final DateTime? lastPlayedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audio_url': audioUrl,
      'duration': duration,
      'cached_file_path': cachedFilePath,
      'is_cached': isCached ? 1 : 0,
      'last_played_at': lastPlayedAt?.millisecondsSinceEpoch,
    };
  }

  factory BreathingMusicTrack.fromMap(Map<String, dynamic> map) {
    return BreathingMusicTrack(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      audioUrl: map['audio_url'] as String,
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      cachedFilePath: map['cached_file_path'] as String?,
      isCached: (map['is_cached'] as int? ?? 0) == 1,
      lastPlayedAt: map['last_played_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_played_at'] as int)
          : null,
    );
  }

  factory BreathingMusicTrack.fromJamendoJson(Map<String, dynamic> json) {
    return BreathingMusicTrack(
      id: (json['id'] ?? '').toString(),
      title: (json['name'] ?? 'Untitled Track').toString(),
      artist: (json['artist_name'] ?? 'Unknown Artist').toString(),
      audioUrl: (json['audio'] ?? '').toString(),
      duration: (json['duration'] as num?)?.toInt() ?? 0,
    );
  }

  BreathingMusicTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? audioUrl,
    int? duration,
    String? cachedFilePath,
    bool? isCached,
    DateTime? lastPlayedAt,
  }) {
    return BreathingMusicTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      cachedFilePath: cachedFilePath ?? this.cachedFilePath,
      isCached: isCached ?? this.isCached,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  /// Default curated list of Jamendo tracks.
  static const List<BreathingMusicTrack> curatedTracks = [
    BreathingMusicTrack(
      id: '16398',
      title: 'Eau bénite et feu sacré',
      artist: 'Philippe Mangold',
      audioUrl:
          'https://prod-1.storage.jamendo.com/?trackid=16398&format=mp32&from=HlL4l9QaCPjx43C3x5c7IQ%3D%3D%7CwgxG1iCePB53BExtHdxvsA%3D%3D',
      duration: 245,
    ),
    BreathingMusicTrack(
      id: '1985894',
      title: '432 Hz Meditation with Theta Waves Binaural Beats',
      artist: 'Gaia Meditation',
      audioUrl:
          'https://prod-1.storage.jamendo.com/?trackid=1985894&format=mp32&from=XZWQY%2BAsQQCAH4x5ehQWCw%3D%3D%7CHbpFh54VH%2FN%2BchW905lRfA%3D%3D',
      duration: 0,
    ),
    BreathingMusicTrack(
      id: '1699096',
      title: 'Gratitude (Full Track)',
      artist: 'AudioSphere',
      audioUrl:
          'https://prod-1.storage.jamendo.com/?trackid=1699096&format=mp32&from=AhQmKwTTI4egZk6tAmoRBw%3D%3D%7Ct%2Bn7F0e4kZyAWPC8zQYsZw%3D%3D',
      duration: 244,
    ),
    BreathingMusicTrack(
      id: '1920257',
      title: 'Winter Dream',
      artist: 'Nargo',
      audioUrl:
          'https://prod-1.storage.jamendo.com/?trackid=1920257&format=mp32&from=I1%2F1C4VTD3tupTXbJ7i5rg%3D%3D%7CK0sJxXnQzhk7zxH5o3GFlw%3D%3D',
      duration: 297,
    ),
    BreathingMusicTrack(
      id: '1906544',
      title: 'Ambient Harp',
      artist: 'Raw Vibrations',
      audioUrl:
          'https://prod-1.storage.jamendo.com/?trackid=1906544&format=mp32&from=LrwbzCN2oTZG2CmaYnrKsg%3D%3D%7CZIWfstqvGvX2e1VdFeswVw%3D%3D',
      duration: 396,
    ),
    BreathingMusicTrack(
      id: '1705713',
      title: 'Blissful Sky',
      artist: 'AudioSphere',
      audioUrl:
          'https://prod-1.storage.jamendo.com/?trackid=1705713&format=mp32&from=un%2BPPB%2BRmu%2FfPWfDjAW00A%3D%3D%7CYfi6obcT5egK%2BmEsECshRA%3D%3D',
      duration: 124,
    ),
  ];
}
