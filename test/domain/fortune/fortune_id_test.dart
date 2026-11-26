import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/domain/fortune/fortune_id.dart';

void main() {
  test('matches Java String.hashCode, as the Kotlin app does', () {
    expect(fortuneIdOf('hello'), 99162322);
    expect(fortuneIdOf('hello world'), 1794106052);
    // The classic Java collision: both hash to 2112.
    expect(fortuneIdOf('Aa'), 2112);
    expect(fortuneIdOf('BB'), 2112);
  });

  test('a negative hash becomes positive, like Kotlin abs', () {
    // In Java this phrase from the app's own jar hashes to -291635673.
    expect(
      fortuneIdOf('Peace begins with a deep breath and a quiet mind.'),
      291635673,
    );
  });

  test('the smallest int stays negative, as Kotlin abs leaves it', () {
    // "polygenelubricants".hashCode() is Integer.MIN_VALUE in Java.
    expect(fortuneIdOf('polygenelubricants'), -2147483648);
  });

  test('surrounding spaces do not change the id', () {
    expect(fortuneIdOf('  Keep going.  '), fortuneIdOf('Keep going.'));
  });
}
