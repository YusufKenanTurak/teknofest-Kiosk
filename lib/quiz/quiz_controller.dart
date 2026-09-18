import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/quiz_catalog.dart';
import '../domain/engineering_field.dart';
import '../domain/models.dart';
import '../telemetry/quiz_telemetry.dart';
import 'score_engine.dart';

enum QuizPhase { start, question, calculating, result, timeout }

/// In-memory session for a single kiosk visitor.
/// Scoring stays local. Optional [QuizTelemetry] is fire-and-forget.
class QuizController extends ChangeNotifier {
  QuizController({
    this.advanceDelay = const Duration(milliseconds: 520),
    this.calculatingDelay = const Duration(milliseconds: 2600),
    this.idleTimeout = const Duration(seconds: 30),
    this.timeoutDisplayDuration = const Duration(seconds: 4),
    QuizTelemetry? telemetry,
  }) : _telemetry = telemetry ?? const NoopQuizTelemetry() {
    _resetSession();
  }

  final QuizTelemetry _telemetry;

  /// Delay between highlighting a tapped option and moving on.
  /// Also acts as the rapid-tap lock.
  final Duration advanceDelay;

  /// Delay on the "Rotan belirleniyor" interstitial after question 15.
  final Duration calculatingDelay;

  /// Inactivity window after which the session is cleared.
  /// [Duration.zero] disables idle timeout (used by automated tests).
  final Duration idleTimeout;

  /// How long the timeout interstitial stays visible before returning to start.
  final Duration timeoutDisplayDuration;

  QuizPhase _phase = QuizPhase.start;
  int _currentIndex = 0;
  late Map<EngineeringField, int> _scores;
  late List<EngineeringField?> _answers;
  TestResult? _result;
  int? _highlightedOptionIndex;
  bool _acceptingInput = true;
  Timer? _advanceTimer;
  Timer? _calculatingTimer;
  Timer? _idleTimer;
  Timer? _timeoutDisplayTimer;

  QuizPhase get phase => _phase;
  int get currentIndex => _currentIndex;
  bool get acceptingInput => _acceptingInput;
  int? get highlightedOptionIndex => _highlightedOptionIndex;
  TestResult? get result => _result;
  Map<EngineeringField, int> get scores =>
      Map<EngineeringField, int>.unmodifiable(_scores);
  List<EngineeringField?> get answers =>
      List<EngineeringField?>.unmodifiable(_answers);

  int get questionCount => QuizCatalog.questions.length;

  bool get isLastQuestion => _currentIndex >= questionCount - 1;

  int get progressPercent {
    final completed = _phase == QuizPhase.question
        ? _currentIndex + 1
        : questionCount;
    return ((completed * 100) / questionCount).round();
  }

  Question? get currentQuestion {
    if (_phase != QuizPhase.question) {
      return null;
    }
    if (_currentIndex < 0 || _currentIndex >= questionCount) {
      return null;
    }
    return QuizCatalog.questions[_currentIndex];
  }

  FieldResultContent? get resultContent {
    final current = _result;
    if (current == null) {
      return null;
    }
    return QuizCatalog.resultFor(current.field);
  }

  void startTest() {
    if (!_acceptingInput || _phase != QuizPhase.start) {
      return;
    }
    _resetSession();
    _phase = QuizPhase.question;
    _currentIndex = 0;
    _armIdleTimer();
    _telemetry.testStarted();
    notifyListeners();
  }

  void selectOption(int optionIndex) {
    if (!_acceptingInput || _phase != QuizPhase.question) {
      return;
    }
    final question = currentQuestion;
    if (question == null) {
      _recoverToStart();
      return;
    }
    if (optionIndex < 0 || optionIndex >= question.options.length) {
      return;
    }
    if (_answers[_currentIndex] != null) {
      return;
    }

    _acceptingInput = false;
    _highlightedOptionIndex = optionIndex;
    final option = question.options[optionIndex];
    _recordAnswer(option);
    _telemetry.questionAnswered(
      questionNumber: question.number,
      optionCode: option.label,
    );
    _armIdleTimer();
    notifyListeners();

    if (advanceDelay == Duration.zero) {
      _advanceAfterSelection();
      return;
    }

    _advanceTimer?.cancel();
    _advanceTimer = Timer(advanceDelay, _advanceAfterSelection);
  }

  /// Called on any pointer interaction so a walk-away visitor cannot leave
  /// a half-finished test on screen.
  void registerInteraction() {
    if (_phase == QuizPhase.timeout) {
      restart();
      return;
    }
    _armIdleTimer();
  }

  void finish() => restart();

  void restart() {
    if (_phase == QuizPhase.question || _phase == QuizPhase.calculating) {
      _telemetry.testAbandoned();
    }
    _cancelTimers();
    _resetSession();
    _phase = QuizPhase.start;
    notifyListeners();
  }

  /// Clears the session and starts a new test at question 1.
  void replay() {
    _cancelTimers();
    _resetSession();
    _phase = QuizPhase.question;
    _currentIndex = 0;
    _armIdleTimer();
    _telemetry.testStarted();
    notifyListeners();
  }

  void _recordAnswer(AnswerOption option) {
    _answers[_currentIndex] = option.field;
    _scores = ScoreEngine.addPoint(scores: _scores, option: option);
  }

  void _advanceAfterSelection() {
    _highlightedOptionIndex = null;
    if (isLastQuestion) {
      _enterCalculating();
      return;
    }
    _currentIndex += 1;
    _acceptingInput = true;
    _armIdleTimer();
    notifyListeners();
  }

  void _enterCalculating() {
    _phase = QuizPhase.calculating;
    _acceptingInput = false;
    _armIdleTimer();
    notifyListeners();

    if (calculatingDelay == Duration.zero) {
      _showResult();
      return;
    }

    _calculatingTimer?.cancel();
    _calculatingTimer = Timer(calculatingDelay, _showResult);
  }

  void _showResult() {
    final recorded = <EngineeringField>[];
    for (final answer in _answers) {
      if (answer == null) {
        _recoverToStart();
        return;
      }
      recorded.add(answer);
    }
    _result = ScoreEngine.buildResult(answers: recorded);
    _phase = QuizPhase.result;
    _acceptingInput = true;
    _armIdleTimer();
    _telemetry.testCompleted();
    notifyListeners();
  }

  void _onIdleTimeout() {
    if (_phase == QuizPhase.start || _phase == QuizPhase.timeout) {
      return;
    }
    if (_phase == QuizPhase.question || _phase == QuizPhase.calculating) {
      _telemetry.testAbandoned();
    }
    _cancelTimers();
    _resetSession();
    _phase = QuizPhase.timeout;
    _acceptingInput = true;
    notifyListeners();

    if (timeoutDisplayDuration == Duration.zero) {
      restart();
      return;
    }
    _timeoutDisplayTimer = Timer(timeoutDisplayDuration, restart);
  }

  void _armIdleTimer() {
    _idleTimer?.cancel();
    if (idleTimeout == Duration.zero) {
      return;
    }
    if (_phase == QuizPhase.start || _phase == QuizPhase.timeout) {
      return;
    }
    _idleTimer = Timer(idleTimeout, _onIdleTimeout);
  }

  void _recoverToStart() {
    _cancelTimers();
    _resetSession();
    _phase = QuizPhase.start;
    notifyListeners();
  }

  void _resetSession() {
    _cancelTimers();
    _currentIndex = 0;
    _scores = ScoreEngine.emptyScores();
    _answers = List<EngineeringField?>.filled(questionCount, null);
    _result = null;
    _highlightedOptionIndex = null;
    _acceptingInput = true;
  }

  void _cancelTimers() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    _calculatingTimer?.cancel();
    _calculatingTimer = null;
    _idleTimer?.cancel();
    _idleTimer = null;
    _timeoutDisplayTimer?.cancel();
    _timeoutDisplayTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
