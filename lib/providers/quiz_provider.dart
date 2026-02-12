import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../services/review_service.dart';
import '../services/settings_service.dart';

enum QuizMode { normal, review }

class QuizState {
  final List<Question> questions;
  final int currentIndex;
  final int score;
  final bool isLoading;
  final int? selectedOptionIndex;
  final bool isAnswered;
  final QuizMode mode;

  QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.isLoading = true,
    this.selectedOptionIndex,
    this.isAnswered = false,
    this.mode = QuizMode.normal,
  });

  QuizState copyWith({
    List<Question>? questions,
    int? currentIndex,
    int? score,
    bool? isLoading,
    int? selectedOptionIndex,
    bool? isAnswered,
    QuizMode? mode,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      isLoading: isLoading ?? this.isLoading,
      selectedOptionIndex: selectedOptionIndex,
      isAnswered: isAnswered ?? this.isAnswered,
      mode: mode ?? this.mode,
    );
  }

  bool get isCompleted => !isLoading && questions.isNotEmpty && currentIndex >= questions.length;
  Question get currentQuestion => questions[currentIndex];
}

class QuizNotifier extends StateNotifier<QuizState> {
  final ReviewService _reviewService = ReviewService();
  List<Question> _allQuestions = [];

  QuizNotifier() : super(QuizState()) {
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    try {
      state = state.copyWith(isLoading: true);
      // Removed artificial delay for performance with large dataset
      final String jsonString = await rootBundle.loadString('assets/questions.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _allQuestions = jsonList.map((j) => Question.fromJson(j)).toList();

      // Default to normal mode (all questions)
      // For MVP, maybe limit to first 10 if not in review mode to keep it snappy?
      // Or shuffle. Let's just take first 10 for normal mode.
      startNormalQuiz(); 
    } catch (e) {
      print('Error loading questions: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> startNormalQuiz() async {
    // Logic:
    // 1. Get daily limit from Settings.
    // 2. Check how many new cards already done today.
    // 3. Calculate remaining allowance.
    // 4. Filter _allQuestions to find "New" cards (not in learned list).
    // 5. Take min(remaining, 10) for this session.
    
    state = state.copyWith(isLoading: true);
    
    final settingsService = SettingsService();
    final limit = await settingsService.getNewCardsPerDay();
    final alreadyDone = await _reviewService.getNewCardsCountToday();
    final remaining = limit - alreadyDone;
    
    if (remaining <= 0) {
      // No new cards allowed today
      // For MVP, maybe show a dialog or just show 0 questions?
      // Or maybe allow review of already learned cards in normal mode? 
      // Let's just show an empty state or fallback to review mode?
      // For now, let's just show 0 and let UI handle "No more new cards today".
      state = QuizState(
        questions: [],
        isLoading: false,
        mode: QuizMode.normal,
      );
      return;
    }
    
    final learnedIds = await _reviewService.getLearnedQuestionIds();
    final newQuestions = _allQuestions.where((q) => !learnedIds.contains(q.id)).toList();
    
    // Shuffle and take
    final countToTake = remaining < 10 ? remaining : 10;
    final shuffled = listShim(newQuestions)..shuffle();
    final quizQuestions = shuffled.take(countToTake).toList();
    
    state = QuizState(
      questions: quizQuestions,
      isLoading: false,
      mode: QuizMode.normal,
    );
  }

  Future<void> startReviewQuiz() async {
    state = state.copyWith(isLoading: true);
    final dueIds = await _reviewService.getDueQuestionIds();
    
    final reviewQuestions = _allQuestions.where((q) => dueIds.contains(q.id)).toList();
    
    // If no questions due, maybe show a message?
    // For now, if empty, we just handle it in UI or show empty list.
    
    state = QuizState(
      questions: reviewQuestions,
      isLoading: false,
      mode: QuizMode.review,
    );
  }

  Future<void> selectOption(int index) async {
    if (state.isAnswered) return;

    final question = state.currentQuestion;
    final isCorrect = index == question.correctIndex;

    // Save review status
    await _reviewService.saveReviewStatus(question.id, isCorrect);

    state = state.copyWith(
      selectedOptionIndex: index,
      isAnswered: true,
      score: isCorrect ? state.score + 1 : state.score,
    );
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length) {
      state = QuizState(
        questions: state.questions,
        currentIndex: state.currentIndex + 1,
        score: state.score,
        isLoading: false,
        selectedOptionIndex: null,
        isAnswered: false,
        mode: state.mode,
      );
    }
  }

  void resetQuiz() {
    // Default to start normal quiz again
    startNormalQuiz();
  }
  
  // Helper to clone list for shuffling
  List<T> listShim<T>(List<T> list) => List<T>.from(list);
}

final quizProvider = StateNotifierProvider.autoDispose<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});

final dueQuestionCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final service = ReviewService();
  final dueIds = await service.getDueQuestionIds();
  return dueIds.length;
});
