import 'engineering_field.dart';

class AnswerOption {
  const AnswerOption({
    required this.label,
    required this.text,
    required this.field,
  });

  /// Visible choice letter: A, B, C or D.
  final String label;

  /// Exact option sentence from the approved content.
  final String text;

  /// Engineering field that receives +1 when this option is selected.
  final EngineeringField field;

  /// Scoring code. Never shown in the UI.
  String get code => field.code;
}

class Question {
  const Question({
    required this.number,
    required this.prompt,
    required this.options,
  });

  /// 1-based question number.
  final int number;

  /// Exact question prompt from the approved content.
  final String prompt;

  /// Always four options, in A/B/C/D order.
  final List<AnswerOption> options;

  String get heading => 'SORU $number';
}

class FieldResultContent {
  const FieldResultContent({
    required this.field,
    required this.emoji,
    required this.title,
    required this.description,
    required this.slogan,
  });

  final EngineeringField field;

  /// Exact emoji from the approved result heading.
  final String emoji;

  /// Engineering field title without the emoji prefix.
  final String title;

  /// Result body copy, excluding the slogan line.
  final String description;

  /// Result slogan line.
  final String slogan;
}

class TestResult {
  const TestResult({required this.field, required this.scores});

  final EngineeringField field;
  final Map<EngineeringField, int> scores;
}
