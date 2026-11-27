class StoredCookieImage {
  const StoredCookieImage({
    required this.cookieId,
    required this.bytes,
    required this.lastOpenedAt,
    required this.isSynced,
  });

  final String cookieId;
  final int bytes;
  final int lastOpenedAt;

  final bool isSynced;
}


abstract final class CookieImageBudget {
  static const maxBytes = 50 * 1024 * 1024;


  static List<String> toEvict(
    List<StoredCookieImage> images, {
    Set<String> protectedIds = const {},
    int limit = maxBytes,
  }) {
    var used = images.fold(0, (sum, image) => sum + image.bytes);
    if (used <= limit) return const [];

    final candidates =
        images
            .where((i) => i.isSynced && !protectedIds.contains(i.cookieId))
            .toList()
          ..sort((a, b) => a.lastOpenedAt.compareTo(b.lastOpenedAt));

    final evicted = <String>[];
    for (final image in candidates) {
      if (used <= limit) break;
      evicted.add(image.cookieId);
      used -= image.bytes;
    }
    return evicted;
  }
}
