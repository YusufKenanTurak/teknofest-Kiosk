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
  static const int idleTimeoutSeconds = 30;
  static const int continuePromptSeconds = 15;

  static const Duration defaultIdleTimeout = Duration(
    seconds: idleTimeoutSeconds,
  );
  static const Duration defaultContinuePrompt = Duration(
    seconds: continuePromptSeconds,
  );

  QuizController({
    this.advanceDelay = const Duration(milliseconds: 520),
    this.calculatingDelay = const Duration(milliseconds: 2600),
    this.idleTimeout = defaultIdleTimeout,
    this.timeoutDisplayDuration = defaultContinuePrompt,
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

  /// Inactivity window that opens the continue prompt, not home.
  /// [Duration.zero] disables idle timeout (used by automated tests).
  final Duration idleTimeout;

  /// Continue-prompt countdown after idle timeout.
  /// [Duration.zero] skips the prompt and returns to start (tests).
  final Duration timeoutDisplayDuration;

  QuizPhase _phase = QuizPhase.start;
  QuizPhase? _phaseBeforeTimeout;
  int _currentIndex = 0;
  late Map<EngineeringField, int> _scores;
  late List<EngineeringField?> _answers;
  TestResult? _result;
  int? _highlightedOptionIndex;
  bool _acceptingInput = true;
  bool _timeoutTransitionLocked = false;
  int _continueRemainingSeconds = 0;
  Timer? _advanceTimer;
  Timer? _calculatingTimer;
  Timer? _idleTimer;
  Timer? _continueTimer;

  QuizPhase get phase => _phase;
  int get currentIndex => _currentIndex;
  bool get acceptingInput => _acceptingInput;
  int? get highlightedOptionIndex => _highlightedOptionIndex;
  TestResult? get result => _result;
  int get continueRemainingSeconds => _continueRemainingSeconds;
  bool get canActOnContinuePrompt =>
      _phase == QuizPhase.timeout && !_timeoutTransitionLocked;
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
    if (_phase == QuizPhase.start || _phase == QuizPhase.timeout) {
      return;
    }
    _armIdleTimer();
  }

  /// Resume the paused test from the continue prompt. Same question and answers.
  void continueTest() {
    if (!_beginTimeoutTransition()) {
      return;
    }
    final resume = _phaseBeforeTimeout ?? QuizPhase.question;
    _phaseBeforeTimeout = null;
    _continueRemainingSeconds = 0;
    _timeoutTransitionLocked = false;
    _resumeAfterContinue(resume);
  }

  void finish() => restart();

  void restart() {
    if (_phase == QuizPhase.timeout) {
      _goHomeFromTimeout();
      return;
    }
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
    if (_timeoutTransitionLocked) {
      return;
    }
    _idleTimer?.cancel();
    _idleTimer = null;
    _advanceTimer?.cancel();
    _advanceTimer = null;
    _calculatingTimer?.cancel();
    _calculatingTimer = null;
    _phaseBeforeTimeout = _phase;
    _phase = QuizPhase.timeout;
    _acceptingInput = true;
    _timeoutTransitionLocked = false;
    _startContinuePrompt();
  }

  void _startContinuePrompt() {
    _continueTimer?.cancel();
    _continueTimer = null;
    if (timeoutDisplayDuration == Duration.zero) {
      _goHomeFromTimeout();
      return;
    }

    final wholeSeconds = timeoutDisplayDuration.inSeconds;
    if (wholeSeconds <= 0) {
      _continueRemainingSeconds = 1;
      notifyListeners();
      _continueTimer = Timer(timeoutDisplayDuration, _onContinueExpired);
      return;
    }

    _continueRemainingSeconds = wholeSeconds;
    notifyListeners();
    _continueTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeoutTransitionLocked || _phase != QuizPhase.timeout) {
        timer.cancel();
        return;
      }
      final next = _continueRemainingSeconds - 1;
      _continueRemainingSeconds = next < 0 ? 0 : next;
      notifyListeners();
      if (_continueRemainingSeconds <= 0) {
        timer.cancel();
        _onContinueExpired();
      }
    });
  }

  void _onContinueExpired() {
    _goHomeFromTimeout();
  }

  bool _beginTimeoutTransition() {
    if (_phase != QuizPhase.timeout) {
      return false;
    }
    if (_timeoutTransitionLocked) {
      return false;
    }
    _timeoutTransitionLocked = true;
    _continueTimer?.cancel();
    _continueTimer = null;
    return true;
  }

  void _goHomeFromTimeout() {
    if (!_beginTimeoutTransition()) {
      return;
    }
    final origin = _phaseBeforeTimeout ?? QuizPhase.timeout;
    if (origin == QuizPhase.question || origin == QuizPhase.calculating) {
      _telemetry.testAbandoned();
    }
    _phaseBeforeTimeout = null;
    _continueRemainingSeconds = 0;
    _resetSession();
    _phase = QuizPhase.start;
    _timeoutTransitionLocked = false;
    notifyListeners();
  }

  void _resumeAfterContinue(QuizPhase resume) {
    switch (resume) {
      case QuizPhase.question:
        _phase = QuizPhase.question;
        if (_currentIndex >= 0 &&
            _currentIndex < _answers.length &&
            _answers[_currentIndex] != null) {
          _advanceAfterSelection();
          return;
        }
        _acceptingInput = true;
        _highlightedOptionIndex = null;
        _armIdleTimer();
        notifyListeners();
      case QuizPhase.calculating:
        _enterCalculating();
      case QuizPhase.result:
        _phase = QuizPhase.result;
        _acceptingInput = true;
        _armIdleTimer();
        notifyListeners();
      case QuizPhase.start:
      case QuizPhase.timeout:
        _resetSession();
        _phase = QuizPhase.start;
        notifyListeners();
    }
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
    _phaseBeforeTimeout = null;
    _continueRemainingSeconds = 0;
    _timeoutTransitionLocked = false;
  }

  void _cancelTimers() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    _calculatingTimer?.cancel();
    _calculatingTimer = null;
    _idleTimer?.cancel();
    _idleTimer = null;
    _continueTimer?.cancel();
    _continueTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
