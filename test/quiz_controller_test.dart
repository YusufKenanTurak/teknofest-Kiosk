import 'package:flutter_test/flutter_test.dart';
import 'package:teknofest_kiosk/data/quiz_catalog.dart';
import 'package:teknofest_kiosk/domain/engineering_field.dart';
import 'package:teknofest_kiosk/quiz/quiz_controller.dart';
import 'package:teknofest_kiosk/quiz/score_engine.dart';

void main() {
  QuizController controller() => QuizController(
    advanceDelay: Duration.zero,
    calculatingDelay: Duration.zero,
    idleTimeout: Duration.zero,
    timeoutDisplayDuration: Duration.zero,
  );

  test('start moves to question 1 without leftover scores', () {
    final quiz = controller();
    quiz.startTest();

    expect(quiz.phase, QuizPhase.question);
    expect(quiz.currentIndex, 0);
    expect(quiz.currentQuestion?.number, 1);
    expect(quiz.scores.values.every((value) => value == 0), isTrue);
    expect(quiz.result, isNull);
  });

  test('selecting an option increments the mapped field and advances', () {
    final quiz = controller();
    quiz.startTest();

    final first = QuizCatalog.questions[0].options[1];
    quiz.selectOption(1);

    expect(quiz.scores[first.field], 1);
    expect(quiz.currentIndex, 1);
    expect(quiz.currentQuestion?.number, 2);
    expect(quiz.answers[0], first.field);
  });

  test('rapid taps on the same question only record one answer', () {
    final quiz = QuizController(
      advanceDelay: const Duration(milliseconds: 400),
      calculatingDelay: Duration.zero,
      idleTimeout: Duration.zero,
    );
    quiz.startTest();
    quiz.selectOption(0);
    quiz.selectOption(1);
    quiz.selectOption(2);

    expect(quiz.answers[0], QuizCatalog.questions[0].options[0].field);
    expect(quiz.currentIndex, 0);
    expect(quiz.phase, QuizPhase.question);
    quiz.dispose();
  });

  test(
    'completing 15 questions produces a result and freezes further answers',
    () {
      final quiz = controller();
      quiz.startTest();

      for (var i = 0; i < 15; i++) {
        quiz.selectOption(0);
      }

      expect(quiz.phase, QuizPhase.result);
      expect(quiz.result, isNotNull);
      expect(quiz.result!.field, EngineeringField.civil);
      expect(quiz.scores.values.reduce((a, b) => a + b), 15);

      quiz.selectOption(0);
      expect(quiz.phase, QuizPhase.result);
      expect(quiz.currentIndex, 14);
    },
  );

  test('replay clears scores, answers, result and starts question 1', () {
    final quiz = controller();
    quiz.startTest();
    for (var i = 0; i < 15; i++) {
      quiz.selectOption(2);
    }

    expect(quiz.phase, QuizPhase.result);
    expect(quiz.result, isNotNull);
    final previousField = quiz.result!.field;

    quiz.replay();

    expect(quiz.phase, QuizPhase.question);
    expect(quiz.currentIndex, 0);
    expect(quiz.currentQuestion?.number, 1);
    expect(quiz.result, isNull);
    expect(quiz.highlightedOptionIndex, isNull);
    expect(quiz.answers.every((answer) => answer == null), isTrue);
    expect(quiz.scores.values.every((value) => value == 0), isTrue);

    for (var i = 0; i < 15; i++) {
      quiz.selectOption(1);
    }

    expect(quiz.result, isNotNull);
    expect(quiz.result!.field, isNot(previousField));
    expect(quiz.result!.field, EngineeringField.industrial);
  });

  test('restart clears scores, answers, result and returns to start', () {
    final quiz = controller();
    quiz.startTest();
    for (var i = 0; i < 15; i++) {
      quiz.selectOption(2);
    }

    expect(quiz.phase, QuizPhase.result);
    expect(quiz.result, isNotNull);
    final previousField = quiz.result!.field;

    quiz.restart();

    expect(quiz.phase, QuizPhase.start);
    expect(quiz.currentIndex, 0);
    expect(quiz.result, isNull);
    expect(quiz.highlightedOptionIndex, isNull);
    expect(quiz.answers.every((answer) => answer == null), isTrue);
    expect(quiz.scores.values.every((value) => value == 0), isTrue);

    quiz.startTest();
    for (var i = 0; i < 15; i++) {
      quiz.selectOption(1);
    }

    expect(quiz.result, isNotNull);
    expect(quiz.result!.field, isNot(previousField));
    expect(quiz.result!.field, EngineeringField.industrial);
  });

  test('repeated restarts do not leak previous scores', () {
    final quiz = controller();

    for (var round = 0; round < 50; round++) {
      quiz.startTest();
      for (var i = 0; i < 15; i++) {
        quiz.selectOption(round.isEven ? 0 : 3);
      }
      expect(quiz.scores.values.reduce((a, b) => a + b), 15);
      quiz.restart();
      expect(quiz.scores, ScoreEngine.emptyScores());
      expect(quiz.result, isNull);
    }
  });

  test('invalid option index is ignored', () {
    final quiz = controller();
    quiz.startTest();
    quiz.selectOption(-1);
    quiz.selectOption(4);

    expect(quiz.currentIndex, 0);
    expect(quiz.answers[0], isNull);
    expect(quiz.scores.values.every((value) => value == 0), isTrue);
  });

  test('last question uses calculating phase before result', () {
    final quiz = QuizController(
      advanceDelay: Duration.zero,
      calculatingDelay: const Duration(milliseconds: 250),
      idleTimeout: Duration.zero,
    );
    quiz.startTest();
    for (var i = 0; i < 15; i++) {
      quiz.selectOption(0);
    }

    expect(quiz.phase, QuizPhase.calculating);
    expect(quiz.result, isNull);
    quiz.dispose();
  });

  testWidgets(
    'idle timeout keeps answers and shows continue prompt before start',
    (tester) async {
      final quiz = QuizController(
        advanceDelay: Duration.zero,
        calculatingDelay: Duration.zero,
        idleTimeout: const Duration(milliseconds: 40),
        timeoutDisplayDuration: const Duration(milliseconds: 40),
      );
      addTearDown(quiz.dispose);
      quiz.startTest();
      quiz.selectOption(0);
      expect(quiz.phase, QuizPhase.question);
      expect(quiz.currentIndex, 1);
      final keptAnswer = quiz.answers[0];

      await tester.pump(const Duration(milliseconds: 40));
      expect(quiz.phase, QuizPhase.timeout);
      expect(quiz.currentIndex, 1);
      expect(quiz.answers[0], keptAnswer);
      expect(quiz.scores.values.any((value) => value > 0), isTrue);
      expect(quiz.continueRemainingSeconds, 1);
      expect(quiz.continueRemainingSeconds, isNonNegative);

      await tester.pump(const Duration(milliseconds: 40));
      expect(quiz.phase, QuizPhase.start);
      expect(quiz.scores.values.every((value) => value == 0), isTrue);
      expect(quiz.answers.every((answer) => answer == null), isTrue);
      expect(quiz.result, isNull);
      expect(quiz.continueRemainingSeconds, 0);
    },
  );

  testWidgets(
    'continue prompt ticks down each second and never goes negative',
    (tester) async {
      final quiz = QuizController(
        advanceDelay: Duration.zero,
        calculatingDelay: Duration.zero,
        idleTimeout: const Duration(milliseconds: 20),
        timeoutDisplayDuration: const Duration(seconds: 3),
      );
      addTearDown(quiz.dispose);
      quiz.startTest();

      await tester.pump(const Duration(milliseconds: 20));
      expect(quiz.phase, QuizPhase.timeout);
      expect(quiz.continueRemainingSeconds, 3);

      await tester.pump(const Duration(seconds: 1));
      expect(quiz.continueRemainingSeconds, 2);
      expect(quiz.phase, QuizPhase.timeout);

      await tester.pump(const Duration(seconds: 1));
      expect(quiz.continueRemainingSeconds, 1);

      await tester.pump(const Duration(seconds: 1));
      expect(quiz.continueRemainingSeconds, 0);
      expect(quiz.phase, QuizPhase.start);

      await tester.pump(const Duration(seconds: 2));
      expect(quiz.continueRemainingSeconds, 0);
      expect(quiz.phase, QuizPhase.start);
    },
  );

  testWidgets('continue resumes the same unanswered question and scores', (
    tester,
  ) async {
    final quiz = QuizController(
      advanceDelay: Duration.zero,
      calculatingDelay: Duration.zero,
      idleTimeout: const Duration(milliseconds: 40),
      timeoutDisplayDuration: const Duration(seconds: 15),
    );
    addTearDown(quiz.dispose);
    quiz.startTest();
    quiz.selectOption(0);
    quiz.selectOption(1);
    expect(quiz.currentIndex, 2);
    final answers = List<EngineeringField?>.from(quiz.answers);
    final scores = Map<EngineeringField, int>.from(quiz.scores);

    await tester.pump(const Duration(milliseconds: 40));
    expect(quiz.phase, QuizPhase.timeout);
    expect(quiz.continueRemainingSeconds, QuizController.continuePromptSeconds);

    quiz.continueTest();
    expect(quiz.phase, QuizPhase.question);
    expect(quiz.currentIndex, 2);
    expect(quiz.currentQuestion?.number, 3);
    expect(quiz.answers, answers);
    expect(quiz.scores, scores);
    expect(quiz.continueRemainingSeconds, 0);

    quiz.restart();
  });

  testWidgets('continue at one second does not also navigate home', (
    tester,
  ) async {
    final quiz = QuizController(
      advanceDelay: Duration.zero,
      calculatingDelay: Duration.zero,
      idleTimeout: const Duration(milliseconds: 20),
      timeoutDisplayDuration: const Duration(seconds: 2),
    );
    addTearDown(quiz.dispose);
    quiz.startTest();
    quiz.selectOption(0);
    expect(quiz.currentIndex, 1);

    await tester.pump(const Duration(milliseconds: 20));
    expect(quiz.phase, QuizPhase.timeout);
    expect(quiz.continueRemainingSeconds, 2);

    await tester.pump(const Duration(seconds: 1));
    expect(quiz.continueRemainingSeconds, 1);

    quiz.continueTest();
    quiz.continueTest();

    expect(quiz.phase, QuizPhase.question);
    expect(quiz.currentIndex, 1);
    expect(quiz.answers[0], isNotNull);

    await tester.pump(const Duration(milliseconds: 10));
    expect(quiz.phase, QuizPhase.question);
    expect(quiz.currentIndex, 1);
    expect(quiz.continueRemainingSeconds, 0);

    quiz.restart();
  });

  testWidgets('expired continue prompt wins over a late continue tap', (
    tester,
  ) async {
    final quiz = QuizController(
      advanceDelay: Duration.zero,
      calculatingDelay: Duration.zero,
      idleTimeout: const Duration(milliseconds: 20),
      timeoutDisplayDuration: const Duration(seconds: 2),
    );
    addTearDown(quiz.dispose);
    quiz.startTest();
    quiz.selectOption(0);

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(seconds: 1));
    expect(quiz.continueRemainingSeconds, 1);

    await tester.pump(const Duration(seconds: 1));
    expect(quiz.phase, QuizPhase.start);
    expect(quiz.answers.every((answer) => answer == null), isTrue);

    quiz.continueTest();
    expect(quiz.phase, QuizPhase.start);
    expect(quiz.currentIndex, 0);
  });

  testWidgets('home from continue prompt clears session for the next test', (
    tester,
  ) async {
    final quiz = QuizController(
      advanceDelay: Duration.zero,
      calculatingDelay: Duration.zero,
      idleTimeout: const Duration(milliseconds: 20),
      timeoutDisplayDuration: const Duration(seconds: 15),
    );
    addTearDown(quiz.dispose);
    quiz.startTest();
    quiz.selectOption(0);

    await tester.pump(const Duration(milliseconds: 20));
    expect(quiz.phase, QuizPhase.timeout);

    quiz.restart();
    expect(quiz.phase, QuizPhase.start);
    expect(quiz.answers.every((answer) => answer == null), isTrue);
    expect(quiz.scores.values.every((value) => value == 0), isTrue);
    expect(quiz.result, isNull);
    expect(quiz.continueRemainingSeconds, 0);

    quiz.startTest();
    expect(quiz.phase, QuizPhase.question);
    expect(quiz.currentIndex, 0);
    expect(quiz.currentQuestion?.number, 1);
    expect(quiz.answers.every((answer) => answer == null), isTrue);

    quiz.restart();
  });

  test('finish clears state the same way restart does', () {
    final quiz = controller();
    quiz.startTest();
    for (var i = 0; i < 15; i++) {
      quiz.selectOption(0);
    }
    expect(quiz.phase, QuizPhase.result);

    quiz.finish();
    expect(quiz.phase, QuizPhase.start);
    expect(quiz.result, isNull);
    expect(quiz.scores.values.every((value) => value == 0), isTrue);
  });
}
