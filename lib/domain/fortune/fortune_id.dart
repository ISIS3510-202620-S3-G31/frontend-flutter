/// The id of a fortune, worked out from its text.
///
/// It must match the Kotlin app, which uses `abs(quote.hashCode())`: the same
/// phrase kept on either phone is then the same favorite in Firestore
/// (`users/{uid}/favorite_fortunes/{id}`). So this is Java's `String.hashCode`
/// over UTF-16 code units, wrapped to a 32-bit signed int, and Kotlin's `abs`,
/// which leaves the smallest int negative because it has no positive twin.
int fortuneIdOf(String quote) {
  var hash = 0;
  for (final unit in quote.trim().codeUnits) {
    hash = (31 * hash + unit) & 0xFFFFFFFF;
  }
  if (hash >= 0x80000000) hash -= 0x100000000;
  return hash == _minInt32 ? hash : hash.abs();
}

const _minInt32 = -0x80000000;
