import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/check_in_model.dart';
import 'package:frontend_flutter/data/models/tool_feedback_model.dart';
import 'package:frontend_flutter/data/repositories/check_in_repository.dart';
import 'package:frontend_flutter/data/repositories/feedback_repository.dart';
import 'package:frontend_flutter/data/repositories/stats_repository.dart';

/// A feedback read that only answers when the test says so, and remembers
/// whether it was started.
class GatedFeedback implements FeedbackRepository {
  final reply = Completer<List<ToolFeedback>>();
  bool started = false;

  @override
  Future<List<ToolFeedback>> since(DateTime from) {
    started = true;
    return reply.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The same for the check-ins.
class GatedCheckIns implements CheckInRepository {
  final reply = Completer<List<CheckIn>>();
  bool started = false;

  @override
  Future<List<CheckIn>> since(DateTime from) {
    started = true;
    return reply.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final from = DateTime(2026, 10, 1);
  final checkIn = CheckIn(
    emotions: const [Emotion.happiness],
    intensity: 3,
    timestamp: DateTime(2026, 10, 30, 9),
  );

  late GatedFeedback feedback;
  late GatedCheckIns checkIns;
  late StatsRepository repository;

  setUp(() {
    feedback = GatedFeedback();
    checkIns = GatedCheckIns();
    repository = StatsRepository(feedback: feedback, checkIns: checkIns);
  });

  test('starts both reads before either one finishes', () async {
    final data = repository.dataSince(from);

    // Neither read has answered yet, and both are already on their way. With
    // one read after the other, the check-ins would still be waiting here.
    expect(feedback.started, isTrue);
    expect(checkIns.started, isTrue);

    checkIns.reply.complete([checkIn]);
    feedback.reply.complete([]);
    final result = await data;

    expect(result.checkIns, [checkIn]);
    expect(result.sessions, isEmpty);
  });

  test('one failed read still leaves the other one', () async {
    final data = repository.dataSince(from);

    feedback.reply.completeError(Exception('offline'));
    checkIns.reply.complete([checkIn]);
    final result = await data;

    expect(result.checkIns, [checkIn]);
    expect(result.sessions, isEmpty);
  });

  test('a brand-new user still has nothing to show', () async {
    final data = repository.dataSince(from);

    feedback.reply.complete([]);
    checkIns.reply.complete([]);

    expect((await data).isEmpty, isTrue);
  });
}
