import 'package:flutter_test/flutter_test.dart';
import 'package:teknofest_kiosk/data/quiz_catalog.dart';
import 'package:teknofest_kiosk/domain/engineering_field.dart';
import 'package:teknofest_kiosk/quiz/score_engine.dart';

void main() {
  setUpAll(QuizCatalog.validate);

  List<EngineeringField> answersFromOptionIndex(int optionIndex) {
    return [
      for (final question in QuizCatalog.questions)
        question.options[optionIndex].field,
    ];
  }

  test('each option awards +1 to its mapped engineering field', () {
    for (final question in QuizCatalog.questions) {
      for (final option in question.options) {
        final scores = ScoreEngine.addPoint(
          scores: ScoreEngine.emptyScores(),
          option: option,
        );
        expect(scores[option.field], 1);
        for (final field in EngineeringField.values) {
          if (field != option.field) {
            expect(scores[field], 0);
          }
        }
      }
    }
  });

  test('fifteen questions are scored independently and summed', () {
    var scores = ScoreEngine.emptyScores();
    expect(QuizCatalog.questions, hasLength(15));

    for (final question in QuizCatalog.questions) {
      scores = ScoreEngine.addPoint(
        scores: scores,
        option: question.options[0],
      );
    }

    var total = 0;
    for (final value in scores.values) {
      total += value;
    }
    expect(total, 15);
  });

  test('senaryo 1: unique max score wins', () {
    expect(
      ScoreEngine.calculateResultFromCodes(const [
        'B',
        'E',
        'M',
        'E',
        'Ç',
        'B',
        'E',
        'İ',
        'M',
        'E',
        'K',
        'Ç',
        'B',
        'İ',
        'E',
      ]),
      EngineeringField.electrical,
    );
  });

  test('senaryo 2: tie broken by last matching answer E', () {
    expect(
      ScoreEngine.calculateResultFromCodes(const [
        'B',
        'E',
        'B',
        'E',
        'B',
        'E',
        'B',
        'E',
        'M',
        'M',
        'M',
      ]),
      EngineeringField.electrical,
    );
  });

  test('senaryo 3: B=4 E=4 last tied code B wins', () {
    expect(
      ScoreEngine.calculateResultFromCodes(const [
        'B',
        'E',
        'B',
        'E',
        'B',
        'E',
        'E',
        'B',
      ]),
      EngineeringField.computer,
    );
  });

  test('senaryo 3b: calculateResult(["B","E","B","E"]) → E', () {
    expect(
      ScoreEngine.calculateResultFromCodes(const ['B', 'E', 'B', 'E']),
      EngineeringField.electrical,
    );
  });

  test('calculateResult(["E","B","E","M","E"]) → E', () {
    expect(
      ScoreEngine.calculateResultFromCodes(const ['E', 'B', 'E', 'M', 'E']),
      EngineeringField.electrical,
    );
  });

  test('tie-break is deterministic across repeated calls', () {
    const codes = ['K', 'B', 'K', 'B', 'K', 'B', 'B', 'K'];
    final first = ScoreEngine.calculateResultFromCodes(codes);
    final second = ScoreEngine.calculateResultFromCodes(codes);
    expect(first, EngineeringField.chemistry);
    expect(second, first);
  });

  test('always answering A yields İnşaat as the unique winner', () {
    final answers = answersFromOptionIndex(0);
    final scores = ScoreEngine.tally(answers);
    expect(scores[EngineeringField.civil], 4);
    expect(ScoreEngine.calculateResult(answers), EngineeringField.civil);
  });

  test('always answering B yields Endüstri as the unique winner', () {
    final answers = answersFromOptionIndex(1);
    final scores = ScoreEngine.tally(answers);
    expect(scores[EngineeringField.industrial], 4);
    expect(ScoreEngine.calculateResult(answers), EngineeringField.industrial);
  });

  test('always answering C ties Çevre and Elektrik; last tied code is E', () {
    final answers = answersFromOptionIndex(2);
    final scores = ScoreEngine.tally(answers);
    expect(scores[EngineeringField.environment], 4);
    expect(scores[EngineeringField.electrical], 4);
    expect(ScoreEngine.calculateResult(answers), EngineeringField.electrical);
  });

  test('always answering D yields Makine as the unique winner', () {
    final answers = answersFromOptionIndex(3);
    final scores = ScoreEngine.tally(answers);
    expect(scores[EngineeringField.mechanical], 5);
    expect(ScoreEngine.calculateResult(answers), EngineeringField.mechanical);
  });

  test('empty answers throw instead of producing a blank result', () {
    expect(() => ScoreEngine.calculateResult(const []), throwsStateError);
    expect(() => ScoreEngine.buildResult(answers: const []), throwsStateError);
  });

  test('unknown scoring code is rejected', () {
    expect(
      () => ScoreEngine.calculateResultFromCodes(const ['X']),
      throwsFormatException,
    );
  });
}
