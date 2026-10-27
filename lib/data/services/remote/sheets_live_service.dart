import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/check_in_model.dart';
import '../../models/tool_feedback_model.dart';
import '../auth_service.dart';

/// Mirrors every new emotion entry into the Google Sheet behind the Looker
/// Studio report (BQ #12), so the dashboard does not wait for the batch export.
///
/// Best-effort on purpose: Firestore stays the source of truth and `export.js`
/// rebuilds the sheet from it, so a failed push only costs freshness.
class SheetsLiveService {
  SheetsLiveService({
    HttpClient? httpClient,
    AuthService? auth,
    String? url,
    String? secret,
  }) : _client = httpClient ?? HttpClient(),
       _auth = auth ?? AuthService(),
       _url = url ?? _urlFromEnvironment,
       _secret = secret ?? _secretFromEnvironment;

  static const _urlFromEnvironment = String.fromEnvironment('SHEETS_URL');
  static const _secretFromEnvironment = String.fromEnvironment('SHEETS_SECRET');
  static const _timeout = Duration(seconds: 6);

  final HttpClient _client;
  final AuthService _auth;
  final String _url;
  final String _secret;

  int? _age;
  bool _ageLoaded = false;

  Future<void> pushCheckIn(String userId, CheckIn checkIn) => _send({
    'source': 'check_in',
    'uid': userId,
    'timestamp': checkIn.timestamp.toUtc().toIso8601String(),
    'emotions': [for (final emotion in checkIn.emotions) emotion.name],
    'intensity': checkIn.intensity,
  });

  /// The feedback mood is an emotion the user reported too, just after a tool,
  /// so it travels in the same shape as a check-in. Matches `export.js`.
  Future<void> pushFeedback(String userId, ToolFeedback feedback) => _send({
    'source': 'tool_feedback',
    'uid': userId,
    'timestamp': feedback.startedAt.toUtc().toIso8601String(),
    'emotions': [feedback.mood.name],
    'intensity': feedback.rating,
  });

  Future<void> _send(Map<String, Object?> body) async {
    if (_url.isEmpty || _secret.isEmpty) {
      debugPrint(
        '[SheetsLive] Skipped: run with --dart-define=SHEETS_URL=... '
        '--dart-define=SHEETS_SECRET=...',
      );
      return;
    }
    try {
      await _post({
        ...body,
        'secret': _secret,
        'age': ?await _userAge(),
      }).timeout(_timeout);
    } on Exception catch (error) {
      // The entry is already in Firestore, so the next export recovers it.
      debugPrint('[SheetsLive] Push failed, the sheet stays behind: $error');
    }
  }

  Future<void> _post(Map<String, Object?> body) async {
    final request = await _client.postUrl(Uri.parse(_url));
    // Apps Script answers 302 towards the result page, and following that
    // redirect resends the POST without a length. The script already ran.
    request.followRedirects = false;
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode != HttpStatus.ok &&
        response.statusCode != HttpStatus.found) {
      throw HttpException('The sheet refused the row (${response.statusCode})');
    }
  }

  /// Read once per session. A failed read is retried on the next push, so a
  /// user who was offline does not lose their age bracket for good.
  Future<int?> _userAge() async {
    if (_ageLoaded) return _age;
    try {
      final profile = await _auth.getCurrentUserProfile().timeout(
        const Duration(seconds: 5),
      );
      _age = profile?.age;
      _ageLoaded = true;
    } on Exception catch (error) {
      debugPrint('[SheetsLive] Could not read the profile age: $error');
    }
    return _age;
  }
}
