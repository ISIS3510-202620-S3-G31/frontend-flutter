import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/cookie_model.dart';
import 'package:frontend_flutter/data/repositories/analytics_repository.dart';
import 'package:frontend_flutter/data/repositories/cookie_repository.dart';
import 'package:frontend_flutter/data/services/analytics_service.dart';
import 'package:frontend_flutter/data/services/connectivity_service.dart';
import 'package:frontend_flutter/data/services/microphone_service.dart';
import 'package:frontend_flutter/data/services/remote/analytics_firestore_service.dart';
import 'package:frontend_flutter/data/services/speech_recognition_service.dart';
import 'package:frontend_flutter/ui/tools/cookie_jar/view_model/new_cookie_view_model.dart';

/// The analytics_events documents, in memory.
class FakeEvents implements AnalyticsFirestoreService {
  final events = <Map<String, Object?>>[];

  @override
  Future<String> create(String userId, Map<String, Object?> event) async {
    events.add(event);
    return 'event-${events.length}';
  }
}

class FakeSpeech implements SpeechRecognitionService {
  @override
  Future<bool> initialize({
    void Function(String error)? onError,
    void Function(bool isListening)? onStatus,
  }) async => true;

  @override
  Future<void> listen({
    required void Function(String words, bool isFinal) onWords,
    bool preferOnDevice = false,
  }) async => onWords('I finally graduated', true);

  @override
  Future<void> stop() async {}
}

class FakeMicrophone implements MicrophoneService {
  @override
  Future<MicPermission> requestPermission() async => MicPermission.granted;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class Online implements ConnectivityChecker {
  @override
  Future<bool> isOnline() async => true;
}

/// Saves nothing: only what the view model asks for matters here.
class SavingRepository extends CookieRepository {
  SavingRepository() : super(currentUserId: () => 'ana');

  @override
  Future<String> finalTitleFor(String title) async => title;

  @override
  Future<CreatedCookie> create({
    required String title,
    required String text,
    Uint8List? photo,
  }) async => CreatedCookie(
    CookieModel(id: 'c1', userId: 'ana', title: title, text: text),
    typedTitle: title,
  );
}

void main() {
  late FakeEvents events;
  late AnalyticsService analytics;

  setUp(() {
    events = FakeEvents();
    analytics = AnalyticsService(service: events)..setUserId('ana');
  });

  group('BQ27: errors by screen', () {
    test('an error is logged with its screen, type and app location', () async {
      final stack = StackTrace.fromString(
        '#0 _CookieJarScreenState.build '
        '(package:frontend_flutter/ui/tools/cookie_jar/widgets/cookie_jar_screen.dart:120:7)\n'
        '#1 StatefulElement.build (package:flutter/src/widgets/framework.dart:5:1)',
      );

      await analytics.logAppError(StateError('boom'), stack, kind: 'flutter');

      final event = events.events.single;
      expect(event['name'], 'app_error');
      expect(event['screen_name'], 'unknown');
      expect(event['error_kind'], 'flutter');
      expect(event['error_type'], 'StateError');
      expect(
        event['location'],
        'ui/tools/cookie_jar/widgets/cookie_jar_screen.dart:120',
      );
      expect(event.values, isNot(contains('boom')));
    });

    test('a stack without app frames has no location', () {
      expect(
        AnalyticsService.appFrameOf(
          StackTrace.fromString('#0 main (dart:core/x.dart:1:1)'),
        ),
        isNull,
      );
    });
  });

  group('BQ28: how cookies are made', () {
    NewCookieViewModel viewModel() => NewCookieViewModel(
      repository: SavingRepository(),
      speech: FakeSpeech(),
      microphone: FakeMicrophone(),
      connectivity: Online(),
      analytics: AnalyticsRepository(analytics: analytics),
    );

    test('a typed cookie without a photo', () async {
      final vm = viewModel()
        ..setTitle('Grad')
        ..setText('Typed by hand');
      await vm.save();
      await pumpEventQueue();

      final event = events.events.single;
      expect(event['name'], 'tool_step');
      expect(event['tool_id'], 'cookie_jar');
      expect(event['step_name'], 'cookie_created');
      expect(event['has_photo'], false);
      expect(event['dictated'], false);
      expect(event['platform'], 'flutter');
    });

    test('a dictated cookie is counted as dictated', () async {
      final vm = viewModel();
      await vm.prepareDictation();
      vm.setTitle('Grad');
      await vm.startDictation(at: 0);
      await vm.finishDictation();
      expect(vm.text, 'I finally graduated');

      await vm.save();
      await pumpEventQueue();

      expect(events.events.single['dictated'], true);
    });

    test('a dictation slid away and cancelled does not count', () async {
      final vm = viewModel();
      await vm.prepareDictation();
      vm.setTitle('Grad');
      await vm.startDictation(at: 0);
      await vm.cancelDictation();
      vm.setText('Typed after all');

      await vm.save();
      await pumpEventQueue();

      expect(events.events.single['dictated'], false);
    });
  });
}
