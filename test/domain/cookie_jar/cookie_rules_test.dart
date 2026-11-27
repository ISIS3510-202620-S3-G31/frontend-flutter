import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/domain/cookie_jar/cookie_rules.dart';

void main() {
  group('cleanTitle', () {
    test('trims and keeps one space between words', () {
      expect(CookieRules.cleanTitle('  Mi   grado \n'), 'Mi grado');
    });

    test('leaves a clean title as it is', () {
      expect(CookieRules.cleanTitle('Mi grado'), 'Mi grado');
    });
  });

  group('titleKeyOf', () {
    test('ignores case, accents and extra spaces', () {
      expect(
        CookieRules.titleKeyOf('Mi Grado'),
        CookieRules.titleKeyOf('  mí   grado '),
      );
      expect(CookieRules.titleKeyOf('Mí Grado'), 'mi grado');
    });

    test('ñ counts as n, like the Kotlin app', () {
      expect(CookieRules.titleKeyOf('Año Nuevo'), 'ano nuevo');
    });
  });

  group('withSuffix', () {
    test('adds -N at the end', () {
      expect(CookieRules.withSuffix('Mi grado', 1), 'Mi grado-1');
      expect(CookieRules.withSuffix('Mi grado', 12), 'Mi grado-12');
    });

    test('cuts a long base so the result never passes 60 characters', () {
      final base = 'a' * 60;
      final result = CookieRules.withSuffix(base, 2);
      expect(result.length, CookieRules.maxTitleLength);
      expect(result, '${'a' * 58}-2');
    });

    test('does not leave a space before the suffix after cutting', () {
      final base = '${'a' * 57} bcd';
      expect(CookieRules.withSuffix(base, 1), '${'a' * 57}-1');
    });
  });

  group('uniqueTitle', () {
    Set<String> keysOf(List<String> titles) =>
        titles.map(CookieRules.titleKeyOf).toSet();

    test('a new title is kept, only cleaned', () {
      expect(CookieRules.uniqueTitle('  Mi   grado ', {}), 'Mi grado');
    });

    test('a repeated title gets -1', () {
      expect(
        CookieRules.uniqueTitle('Mi grado', keysOf(['Mi grado'])),
        'Mi grado-1',
      );
    });

    test('a repeat is found even with other case and accents', () {
      expect(
        CookieRules.uniqueTitle('mí GRADO', keysOf(['Mi grado'])),
        'mí GRADO-1',
      );
    });

    test('takes the first free number', () {
      final existing = keysOf(['Mi grado', 'Mi grado-1', 'Mi grado-3']);
      expect(CookieRules.uniqueTitle('Mi grado', existing), 'Mi grado-2');
    });

    test('a long repeated title still fits in 60 characters', () {
      final title = 'b' * 60;
      final result = CookieRules.uniqueTitle(title, keysOf([title]));
      expect(result.length, lessThanOrEqualTo(CookieRules.maxTitleLength));
      expect(result.endsWith('-1'), isTrue);
    });
  });

  group('validation', () {
    test('an empty title or text is not valid', () {
      expect(CookieRules.validationError('   ', 'text'),
          CookieRules.emptyTitleError);
      expect(CookieRules.validationError('Title', '  '),
          CookieRules.emptyTextError);
    });

    test('limits are 60 for the title and 280 for the text', () {
      expect(CookieRules.titleError('a' * 60), isNull);
      expect(CookieRules.titleError('a' * 61), isNotNull);
      expect(CookieRules.textError('a' * 280), isNull);
      expect(CookieRules.textError('a' * 281), isNotNull);
    });

    test('a good cookie has no error', () {
      expect(CookieRules.validationError('Mi grado', 'Lo logré'), isNull);
    });
  });
}
