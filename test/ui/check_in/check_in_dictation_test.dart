import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/services/microphone_service.dart';
import 'package:frontend_flutter/ui/check_in/view_model/check_in_view_model.dart';

import 'fakes.dart';

void main() {
  late FakeSpeechRecognitionService speech;

  CheckInViewModel build({
    bool available = true,
    bool online = true,
    MicPermission permission = MicPermission.granted,
  }) {
    speech = FakeSpeechRecognitionService(available: available);
    return CheckInViewModel(
      repository: FakeCheckInRepository(),
      speech: speech,
      microphone: FakeMicrophoneService(permission: permission),
      network: FakeNetworkConnectivityService(online: online),
    );
  }

  test('dictation stays off on a phone without a recognizer', () async {
    final viewModel = build(available: false);

    await viewModel.prepareDictation();
    await viewModel.toggleDictation(at: 0);

    expect(viewModel.canDictate, isFalse);
    expect(viewModel.isListening, isFalse);
    expect(speech.askedForOnDevice, isNull);
  });

  test(
    'each result replaces the words so far instead of adding to them',
    () async {
      final viewModel = build();
      await viewModel.prepareDictation();
      await viewModel.toggleDictation(at: 0);

      speech.say('I');
      speech.say('I am');
      speech.say('I am tired', isFinal: true);

      expect(viewModel.note, 'I am tired');
    },
  );

  test('words land at the caret and leave typed text alone', () async {
    final viewModel = build();
    viewModel.setNote('Today: . Bye');
    await viewModel.prepareDictation();
    // Right after "Today: ".
    await viewModel.toggleDictation(at: 7);

    speech.say('I slept');
    speech.say('I slept well', isFinal: true);

    expect(viewModel.note, 'Today: I slept well. Bye');
    expect(viewModel.noteCaret, 'Today: I slept well'.length);
  });

  test('two dictations in a row do not overwrite the first', () async {
    final viewModel = build();
    await viewModel.prepareDictation();

    await viewModel.toggleDictation(at: 0);
    speech.say('First.', isFinal: true);
    await viewModel.toggleDictation(at: 0);

    await viewModel.toggleDictation(at: viewModel.note.length);
    speech.say(' Second.', isFinal: true);

    expect(viewModel.note, 'First. Second.');
  });

  test('offline it asks for on-device recognition', () async {
    final viewModel = build(online: false);
    await viewModel.prepareDictation();

    await viewModel.toggleDictation(at: 0);

    expect(speech.askedForOnDevice, isTrue);
  });

  test('offline failure tells the user it needs a connection', () async {
    final viewModel = build(online: false);
    await viewModel.prepareDictation();
    await viewModel.toggleDictation(at: 0);

    speech.fail();

    expect(
      viewModel.dictationMessage,
      'Dictation needs an internet connection on this phone.',
    );
    expect(viewModel.isListening, isFalse);
  });

  test('online failure does not blame the connection', () async {
    final viewModel = build();
    await viewModel.prepareDictation();
    await viewModel.toggleDictation(at: 0);

    speech.fail();

    expect(viewModel.dictationMessage, isNot(contains('internet')));
  });

  test('a denied microphone is explained and nothing is started', () async {
    final viewModel = build(permission: MicPermission.denied);
    await viewModel.prepareDictation();

    await viewModel.toggleDictation(at: 0);

    expect(viewModel.dictationMessage, contains('microphone'));
    expect(speech.askedForOnDevice, isNull);
  });

  test('toggling while listening stops the recognizer', () async {
    final viewModel = build();
    await viewModel.prepareDictation();
    await viewModel.toggleDictation(at: 0);

    expect(viewModel.isListening, isTrue);
    await viewModel.toggleDictation(at: 0);

    expect(speech.stopCount, 1);
    expect(viewModel.isListening, isFalse);
  });
}
