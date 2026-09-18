import 'package:flutter_test/flutter_test.dart';
import 'package:teknofest_kiosk/quiz/quiz_controller.dart';
import 'package:teknofest_kiosk/telemetry/quiz_telemetry.dart';

void main() {
  QuizController controller(QuizTelemetry telemetry) => QuizController(
    advanceDelay: Duration.zero,
    calculatingDelay: Duration.zero,
    idleTimeout: Duration.zero,
    timeoutDisplayDuration: Duration.zero,
    telemetry: telemetry,
  );

  test('start, answers and complete emit telemetry without changing scoring', () {
    final telemetry = RecordingQuizTelemetry();
    final quiz = controller(telemetry);
    quiz.startTest();
    for (var i = 0; i < 15; i++) {
      quiz.selectOption(0);
    }
    expect(telemetry.events.first, 'started');
    expect(telemetry.events.last, 'completed');
    expect(telemetry.events.where((e) => e.startsWith('answered:')).length, 15);
    expect(quiz.phase, QuizPhase.result);
    quiz.dispose();
  });

  test('restart during a question marks the session abandoned', () {
    final telemetry = RecordingQuizTelemetry();
    final quiz = controller(telemetry);
    quiz.startTest();
    quiz.selectOption(0);
    quiz.restart();
    expect(telemetry.events.contains('abandoned'), isTrue);
    expect(quiz.phase, QuizPhase.start);
    quiz.dispose();
  });
}
