
abstract final class CookieRules {
  static const maxTitleLength = 60;

  /// The same limit as the check-in note and the feedback comment.
  static const maxTextLength = 280;

  static const emptyTitleError = 'Give your cookie a title';
  static const emptyTextError = 'Write what you want to remember';

  static final _spaces = RegExp(r'\s+');


  static String cleanTitle(String title) {
    return title.trim().replaceAll(_spaces, ' ');
  }

  static String titleKeyOf(String title) {
    return _withoutAccents(cleanTitle(title)).toLowerCase();
  }


  static String withSuffix(String base, int number) {
    final suffix = '-$number';
    final room = maxTitleLength - suffix.length;
    final trimmedBase = base.length > room
        ? base.substring(0, room).trimRight()
        : base;
    return '$trimmedBase$suffix';
  }


  static String uniqueTitle(String title, Set<String> existingKeys) {
    final base = cleanTitle(title);
    if (!existingKeys.contains(titleKeyOf(base))) return base;
    for (var number = 1; ; number++) {
      final candidate = withSuffix(base, number);
      if (!existingKeys.contains(titleKeyOf(candidate))) return candidate;
    }
  }

  /// The message to show under the title field, or null when it is good.
  static String? titleError(String title) {
    final clean = cleanTitle(title);
    if (clean.isEmpty) return emptyTitleError;
    if (clean.length > maxTitleLength) {
      return 'Title cannot exceed $maxTitleLength characters';
    }
    return null;
  }

  /// The message to show under the text field, or null when it is good.
  static String? textError(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return emptyTextError;
    if (clean.length > maxTextLength) {
      return 'Text cannot exceed $maxTextLength characters';
    }
    return null;
  }

  /// The first problem of a new cookie, or null when it can be saved.
  static String? validationError(String title, String text) =>
      titleError(title) ?? textError(text);


  static const _accents = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
    'Á': 'A',
    'À': 'A',
    'Ä': 'A',
    'Â': 'A',
    'Ã': 'A',
    'É': 'E',
    'È': 'E',
    'Ë': 'E',
    'Ê': 'E',
    'Í': 'I',
    'Ì': 'I',
    'Ï': 'I',
    'Î': 'I',
    'Ó': 'O',
    'Ò': 'O',
    'Ö': 'O',
    'Ô': 'O',
    'Õ': 'O',
    'Ú': 'U',
    'Ù': 'U',
    'Ü': 'U',
    'Û': 'U',
    'Ñ': 'N',
    'Ç': 'C',
  };

  static String _withoutAccents(String text) =>
      text.split('').map((letter) => _accents[letter] ?? letter).join();
}
