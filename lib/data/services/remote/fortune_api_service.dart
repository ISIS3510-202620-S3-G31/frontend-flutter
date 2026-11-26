import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/fortune_model.dart';

/// Downloads new phrases from two public APIs, the same ones the Kotlin app
/// uses: traditional fortunes from dumbapis and advice from adviceslip.
class FortuneApiService {
  FortuneApiService({Duration? timeLimit})
    : timeLimit = timeLimit ?? const Duration(seconds: 3);

  static final _fortuneUrl = Uri.parse('https://dumbapis.com/fortune');
  static final _adviceUrl = Uri.parse('https://api.adviceslip.com/advice');

  /// Per request. A slow API should not keep the cookies from showing.
  final Duration timeLimit;

  /// Two fortunes and two pieces of advice, asked for at the same time.
  /// Whatever fails is left out, so offline the list is empty.
  Future<List<Fortune>> fetchTwoAndTwo() async {
    final answers = await Future.wait([
      _fetch(_fortuneUrl, _readFortune),
      _fetch(_fortuneUrl, _readFortune),
      _fetch(_adviceUrl, _readAdvice),
      _fetch(_adviceUrl, _readAdvice),
    ]);
    return answers.nonNulls.toList();
  }

  Future<Fortune?> _fetch(
    Uri url,
    Fortune Function(Map<String, Object?> json) read,
  ) async {
    final client = HttpClient()..connectionTimeout = timeLimit;
    try {
      final request = await client.getUrl(url).timeout(timeLimit);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(timeLimit);
      if (response.statusCode != HttpStatus.ok) return null;
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeLimit);
      final fortune = read(jsonDecode(body) as Map<String, Object?>);
      return fortune.quote.isEmpty ? null : fortune;
    } on Object catch (error) {
      // No network, a timeout or an answer in another shape: one phrase
      // fewer, never an error on screen.
      debugPrint('[Fortune] $url failed: $error');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// `{"fortune": "..."}`
  static Fortune _readFortune(Map<String, Object?> json) =>
      Fortune(quote: (json['fortune'] as String).trim());

  /// `{"slip": {"id": 76, "advice": "..."}}`
  static Fortune _readAdvice(Map<String, Object?> json) {
    final slip = json['slip'] as Map<String, Object?>;
    return Fortune(
      quote: (slip['advice'] as String).trim(),
      category: 'Advice',
    );
  }
}
