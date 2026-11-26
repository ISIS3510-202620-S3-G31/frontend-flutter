/// The image of a fortune the user shared.
class FortuneCard {
  const FortuneCard({
    required this.cookieId,
    required this.quote,
    required this.localPath,
    required this.savedAt,
  });

  /// The fortune it shows.
  final int cookieId;
  final String quote;

  /// The app's own copy, in its private documents folder. The one in the
  /// phone's gallery belongs to the user and may be deleted from there.
  final String localPath;
  final DateTime savedAt;
}
