
List<String> speechChunks(String text, {int maxLength = 4000}) {
  final sentences = text
      .split(RegExp(r'(?<=[.!?…])\s+|\n+'))
      .map((sentence) => sentence.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((sentence) => sentence.isNotEmpty);
  return [
    for (final sentence in sentences) ..._fit(sentence, maxLength),
  ];
}

/// Cuts a sentence that is still too long at the last space that fits.
Iterable<String> _fit(String sentence, int maxLength) sync* {
  var rest = sentence;
  while (rest.length > maxLength) {
    final space = rest.lastIndexOf(' ', maxLength);
    final end = space > 0 ? space : maxLength;
    yield rest.substring(0, end).trim();
    rest = rest.substring(end).trim();
  }
  if (rest.isNotEmpty) yield rest;
}
