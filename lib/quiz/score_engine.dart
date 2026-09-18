import '../domain/engineering_field.dart';
import '../domain/models.dart';

/// Pure scoring helpers. No UI, no Flutter, no clocks — fully deterministic.
class ScoreEngine {
  const ScoreEngine._();

  /// Awards +1 to the engineering field of [option].
  static Map<EngineeringField, int> addPoint({
    required Map<EngineeringField, int> scores,
    required AnswerOption option,
  }) {
    final next = Map<EngineeringField, int>.from(scores);
    next[option.field] = (next[option.field] ?? 0) + 1;
    return next;
  }

  static Map<EngineeringField, int> emptyScores() {
    return {for (final field in EngineeringField.values) field: 0};
  }

  static Map<EngineeringField, int> tally(List<EngineeringField> answers) {
    final scores = emptyScores();
    for (final answer in answers) {
      scores[answer] = (scores[answer] ?? 0) + 1;
    }
    return scores;
  }

  /// Frequencies + last-from-end tie-break among max-score fields.
  ///
  /// 1. Count each field.
  /// 2. Find the maximum frequency.
  /// 3. If several fields share that maximum, walk [answers] from last to first.
  /// 4. The first max-score field encountered is the winner.
  static EngineeringField calculateResult(List<EngineeringField> answers) {
    if (answers.isEmpty) {
      throw StateError('Cannot calculate a result from an empty answer list.');
    }
    return resolveWinner(scores: tally(answers), answers: answers);
  }

  /// Same as [calculateResult] but accepts official letter codes (B, K, Ç, …).
  static EngineeringField calculateResultFromCodes(List<String> codes) {
    return calculateResult([
      for (final code in codes) EngineeringField.fromCode(code),
    ]);
  }

  static EngineeringField resolveWinner({
    required Map<EngineeringField, int> scores,
    required List<EngineeringField> answers,
  }) {
    var maxScore = -1;
    for (final field in EngineeringField.values) {
      final score = scores[field] ?? 0;
      if (score > maxScore) {
        maxScore = score;
      }
    }

    if (maxScore <= 0) {
      throw StateError('Cannot resolve a winner from empty scores.');
    }

    final tied = <EngineeringField>{
      for (final field in EngineeringField.values)
        if ((scores[field] ?? 0) == maxScore) field,
    };

    if (tied.length == 1) {
      return tied.first;
    }

    for (var i = answers.length - 1; i >= 0; i--) {
      if (tied.contains(answers[i])) {
        return answers[i];
      }
    }

    throw StateError(
      'Cannot resolve a winner; answers do not contain a max-score field.',
    );
  }

  static TestResult buildResult({required List<EngineeringField> answers}) {
    final scores = tally(answers);
    return TestResult(
      field: resolveWinner(scores: scores, answers: answers),
      scores: Map<EngineeringField, int>.unmodifiable(
        Map<EngineeringField, int>.from(scores),
      ),
    );
  }
}
