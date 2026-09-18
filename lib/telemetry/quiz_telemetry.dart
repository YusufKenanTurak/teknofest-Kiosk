/// Optional persistence hook. The quiz always scores locally; implementations
/// must never throw into the UI path.
abstract class QuizTelemetry {
  const QuizTelemetry();

  void testStarted();

  void questionAnswered({
    required int questionNumber,
    required String optionCode,
  });

  void testCompleted();

  void testAbandoned();
}

class NoopQuizTelemetry implements QuizTelemetry {
  const NoopQuizTelemetry();

  @override
  void testStarted() {}

  @override
  void questionAnswered({
    required int questionNumber,
    required String optionCode,
  }) {}

  @override
  void testCompleted() {}

  @override
  void testAbandoned() {}
}

/// Test double that records calls without performing I/O.
class RecordingQuizTelemetry implements QuizTelemetry {
  final List<String> events = <String>[];

  @override
  void testStarted() => events.add('started');

  @override
  void questionAnswered({
    required int questionNumber,
    required String optionCode,
  }) {
    events.add('answered:$questionNumber:$optionCode');
  }

  @override
  void testCompleted() => events.add('completed');

  @override
  void testAbandoned() => events.add('abandoned');
}
