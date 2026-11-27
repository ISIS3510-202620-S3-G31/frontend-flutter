import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/repositories/cookie_repository.dart';
import 'package:frontend_flutter/data/services/connectivity_service.dart';
import 'package:frontend_flutter/data/services/microphone_service.dart';
import 'package:frontend_flutter/data/services/speech_recognition_service.dart';
import 'package:frontend_flutter/ui/tools/cookie_jar/view_model/new_cookie_view_model.dart';
import 'package:frontend_flutter/ui/tools/cookie_jar/widgets/new_cookie_screen.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Plays the recognizer: the test says words, pauses or fails.
class FakeSpeech implements SpeechRecognitionService {
  int listens = 0;
  int stops = 0;
  void Function(String words, bool isFinal)? _onWords;
  void Function(String error)? _onError;
  void Function(bool listening)? _onStatus;

  @override
  Future<bool> initialize({
    void Function(String error)? onError,
    void Function(bool isListening)? onStatus,
  }) async {
    _onError = onError;
    _onStatus = onStatus;
    return true;
  }

  @override
  Future<void> listen({
    required void Function(String words, bool isFinal) onWords,
    bool preferOnDevice = false,
  }) async {
    listens++;
    _onWords = onWords;
    _onStatus?.call(true);
  }

  @override
  Future<void> stop() async {
    stops++;
    _onStatus?.call(false);
  }

  void say(String words, {bool isFinal = false}) =>
      _onWords?.call(words, isFinal);

  /// The phone stopped by itself after a pause, with its last words.
  void pause(String lastWords) {
    say(lastWords, isFinal: true);
    _onStatus?.call(false);
  }

  void fail(String error) => _onError?.call(error);
}

/// Like the real plugin: a second `initialize` keeps the first listeners.
class OneTimePlugin implements SpeechToText {
  bool _initialized = false;
  SpeechResultListener? _onResult;

  @override
  SpeechErrorListener? errorListener;

  @override
  SpeechStatusListener? statusListener;

  void status(String status) => statusListener?.call(status);

  void result(String words) => _onResult?.call(
    SpeechRecognitionResult([
      SpeechRecognitionWords(words, null, 1),
    ], ResultType.finalResult.value),
  );

  void error(String code) =>
      errorListener?.call(SpeechRecognitionError(code, false));

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #initialize:
        if (!_initialized) {
          errorListener = invocation.namedArguments[#onError];
          statusListener = invocation.namedArguments[#onStatus];
          _initialized = true;
        }
        return Future.value(true);
      case #listen:
        _onResult = invocation.namedArguments[#onResult];
        return Future<void>.value();
      case #stop:
      case #cancel:
        return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class GrantedMicrophone implements MicrophoneService {
  @override
  Future<MicPermission> requestPermission() async => MicPermission.granted;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class Online implements ConnectivityChecker {
  @override
  Future<bool> isOnline() async => true;
}

NewCookieViewModel newCookie(SpeechRecognitionService speech) =>
    NewCookieViewModel(
      repository: CookieRepository(currentUserId: () => 'ana'),
      speech: speech,
      microphone: GrantedMicrophone(),
      connectivity: Online(),
    );

void main() {
  group('hold to dictate', () {
    late FakeSpeech speech;
    late NewCookieViewModel vm;

    setUp(() async {
      speech = FakeSpeech();
      vm = newCookie(speech);
      await vm.prepareDictation();
    });

    test('releasing the mic keeps the words, written at the caret', () async {
      vm.setText('Today was great');
      await vm.startDictation(at: 5);
      expect(vm.isRecording, isTrue);

      speech.say('I graduated');
      await vm.finishDictation();

      expect(vm.isRecording, isFalse);
      expect(vm.text, 'Today I graduated was great');
      expect(speech.stops, 1);
    });

    test('sliding off the mic puts the text back as it was', () async {
      vm.setText('Hi');
      await vm.startDictation(at: 2);
      speech.say('there');
      expect(vm.text, 'Hi there');

      await vm.cancelDictation();
      speech.say('there friend', isFinal: true);

      expect(vm.text, 'Hi');
      expect(vm.textCaret, 2);
    });

    test('a pause while holding keeps listening and adds the next words', () {
      fakeAsync((async) {
        vm.startDictation(at: 0);
        async.flushMicrotasks();

        speech.pause('My first job');
        async.elapse(const Duration(milliseconds: 300));
        expect(speech.listens, 2);

        speech.say('in Bogota', isFinal: true);
        vm.finishDictation();
        async.flushMicrotasks();

        expect(vm.text, 'My first job in Bogota');
      });
    });

    test('silence is not an error: no notice and it keeps listening', () {
      fakeAsync((async) {
        vm.startDictation(at: 0);
        async.flushMicrotasks();

        speech.fail('error_no_match');
        async.elapse(const Duration(milliseconds: 300));

        expect(vm.message, isNull);
        expect(vm.isRecording, isTrue);
        expect(speech.listens, 2);
        vm.finishDictation();
      });
    });

    test('a real failure stops the dictation and says so', () async {
      await vm.startDictation(at: 0);
      speech.fail('error_network');

      expect(vm.isRecording, isFalse);
      expect(vm.message, isNotNull);
    });

    test(
      'a release before the recognizer started never leaves it on',
      () async {
        final start = vm.startDictation(at: 0);
        await vm.finishDictation();
        await start;

        expect(vm.isRecording, isFalse);
        expect(speech.stops, greaterThanOrEqualTo(1));
      },
    );
  });

  test('the second cookie hears the recognizer, not the first one', () async {
    final plugin = OneTimePlugin();

    final first = newCookie(SpeechRecognitionService(speech: plugin));
    await first.prepareDictation();
    first.dispose();

    final second = newCookie(SpeechRecognitionService(speech: plugin));
    await second.prepareDictation();
    await second.startDictation(at: 0);
    plugin.status('listening');
    plugin.result('Second cookie');

    expect(second.isListening, isTrue);
    expect(second.text, 'Second cookie');

    plugin.error('error_network');
    expect(second.message, isNotNull);
  });

  group('the mic button', () {
    late FakeSpeech speech;
    late NewCookieViewModel vm;

    Future<void> pumpScreen(WidgetTester tester) async {
      speech = FakeSpeech();
      vm = newCookie(speech);
      await tester.pumpWidget(
        MaterialApp(home: NewCookieScreen(viewModel: vm)),
      );
      await tester.pump();
    }

    Finder mic() => find.byKey(NewCookieScreen.micKey);

    testWidgets('holding records and releasing keeps the words', (
      tester,
    ) async {
      await pumpScreen(tester);
      final gesture = await tester.startGesture(tester.getCenter(mic()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(vm.isRecording, isTrue);
      expect(find.textContaining('release to finish'), findsOneWidget);

      speech.say('Baked my first cookie');
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(vm.isRecording, isFalse);
      expect(find.text('Baked my first cookie'), findsOneWidget);
    });

    testWidgets('a quick tap explains how to dictate', (tester) async {
      await pumpScreen(tester);
      await tester.tap(mic());
      await tester.pump();

      expect(vm.isRecording, isFalse);
      expect(
        find.text('Hold the mic to dictate, release to finish.'),
        findsOneWidget,
      );
    });

    testWidgets('sliding left cancels what was dictated', (tester) async {
      await pumpScreen(tester);
      final gesture = await tester.startGesture(tester.getCenter(mic()));
      await tester.pump(const Duration(milliseconds: 200));
      speech.say('Oops');
      await tester.pump();

      await gesture.moveBy(const Offset(-120, 0));
      await tester.pump();
      expect(find.text('Release to cancel'), findsOneWidget);

      await gesture.up();
      await tester.pump();

      expect(vm.text, isEmpty);
      expect(find.text('Oops'), findsNothing);
    });
  });

  test('cancelling a dictation never running is a no-op', () async {
    final vm = newCookie(FakeSpeech());
    await vm.cancelDictation();
    await vm.finishDictation();
    expect(vm.isRecording, isFalse);
  });
}
