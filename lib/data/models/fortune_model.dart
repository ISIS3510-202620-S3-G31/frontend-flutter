import '../../domain/fortune/fortune_id.dart';

/// One fortune cookie phrase.
class Fortune {
  Fortune({
    required this.quote,
    this.category = 'Wisdom',
    DateTime? savedAt,
    int? id,
  }) : id = id ?? fortuneIdOf(quote),
       savedAt = savedAt ?? DateTime.now();

  factory Fortune.fromJson(Map<String, Object?> json) {
    final quote = (json['quote'] as String).trim();
    final savedAt = json['savedAt'];
    return Fortune(
      quote: quote,
      id: (json['id'] as num?)?.toInt(),
      category: json['category'] as String? ?? 'Wisdom',
      savedAt: savedAt is num
          ? DateTime.fromMillisecondsSinceEpoch(savedAt.toInt())
          : null,
    );
  }

  /// The same phrase always has the same id, on this phone and in Kotlin.
  final int id;
  final String quote;

  /// "Wisdom" for traditional fortunes, "Advice" for advice slips.
  final String category;

  /// When it was downloaded, opened or kept, depending on the list.
  final DateTime savedAt;

  Fortune copyWith({DateTime? savedAt}) => Fortune(
    quote: quote,
    id: id,
    category: category,
    savedAt: savedAt ?? this.savedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'quote': quote,
    'category': category,
    'savedAt': savedAt.millisecondsSinceEpoch,
  };

  @override
  bool operator ==(Object other) => other is Fortune && other.id == id;

  @override
  int get hashCode => id;
}

/// Where the phrase of a cookie came from.
enum FortuneSource {
  /// Downloaded just now.
  internet,

  /// Downloaded earlier and kept on the phone.
  phone,

  /// One of the phrases that come with the app.
  builtIn,
}

/// One of the three cookies on the table.
class TableFortune {
  const TableFortune(this.fortune, this.source, {required this.isOffline});

  final Fortune fortune;
  final FortuneSource source;

  /// True when the table had to be set without a connection.
  final bool isOffline;
}

/// What opening a cookie gives back.
class OpenedFortune {
  const OpenedFortune(this.fortune, this.remainingChances);

  final Fortune fortune;
  final int remainingChances;
}
