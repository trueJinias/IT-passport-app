import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../services/review_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';

enum QuizMode { normal, review }

class QuizState {
  final List<Question> questions;
  final int currentIndex;
  final int score;
  final bool isLoading;
  final int? selectedOptionIndex;
  final bool isAnswered;
  final QuizMode mode;
  final String? errorMessage;
  final Map<int, String>? nextIntervalLabels; // For buttons 1,2,3,4

  QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.isLoading = true,
    this.selectedOptionIndex,
    this.isAnswered = false,
    this.mode = QuizMode.normal,
    this.errorMessage,
    this.nextIntervalLabels,
  });

  QuizState copyWith({
    List<Question>? questions,
    int? currentIndex,
    int? score,
    bool? isLoading,
    int? selectedOptionIndex,
    bool? isAnswered,
    QuizMode? mode,
    String? errorMessage,
    Map<int, String>? nextIntervalLabels,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      isLoading: isLoading ?? this.isLoading,
      selectedOptionIndex: selectedOptionIndex,
      isAnswered: isAnswered ?? this.isAnswered,
      mode: mode ?? this.mode,
      errorMessage: errorMessage,
      nextIntervalLabels: nextIntervalLabels ?? this.nextIntervalLabels,
    );
  }

  bool get isCompleted => !isLoading && questions.isNotEmpty && currentIndex >= questions.length;
  Question get currentQuestion => questions[currentIndex];
}

// Top-level function for compute
List<Question> _parseJson(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((j) => Question.fromJson(j)).toList();
}

class QuizNotifier extends StateNotifier<QuizState> {
  final ReviewService _reviewService = ReviewService();
  List<Question> _allQuestions = [];

  QuizNotifier() : super(QuizState()); 

  // Internal data loader - Uses compute to avoid blocking UI
  Future<void> _loadData() async {
    final String jsonString = await rootBundle.loadString('assets/questions.json');
    // Run JSON parsing in a separate isolate
    _allQuestions = await compute(_parseJson, jsonString);
  }

  Future<void> _ensureLoaded() async {
    if (_allQuestions.isEmpty) {
      await _loadData();
    }
  }

  Future<void> startNormalQuiz() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _ensureLoaded();
      if (!mounted) return;
      
      if (_allQuestions.isEmpty) {
         if (mounted) state = state.copyWith(isLoading: false, errorMessage: '問題データが空です。(JSON Load Error?)');
         return;
      }
      
      final settingsService = SettingsService();
      final limit = await settingsService.getNewCardsPerDay();
      final alreadyDone = await _reviewService.getNewCardsCountToday();
      final remaining = limit - alreadyDone;
      
      if (remaining <= 0) {
        // Quota met, cancel today's notification
        await NotificationService().completeForToday();
        
        if (mounted) {
          state = QuizState(
            questions: [],
            isLoading: false,
            mode: QuizMode.normal,
            errorMessage: '本日の学習ノルマ(${limit}問)を達成済みです。\n(${alreadyDone}問 完了済み)',
          );
        }
        return;
      }
      
      final learnedIds = await _reviewService.getLearnedQuestionIds();
      final newQuestions = _allQuestions.where((q) => !learnedIds.contains(q.id)).toList();
      
      if (newQuestions.isEmpty) {
         if (mounted) {
           state = QuizState(
            questions: [],
            isLoading: false,
            mode: QuizMode.normal,
            errorMessage: 'すべての問題を学習済みです！\n(全${_allQuestions.length}問)',
          );
         }
        return;
      }
      
      final countToTake = remaining < 10 ? remaining : 10;
      final shuffled = listShim(newQuestions)..shuffle();
      final quizQuestions = shuffled.take(countToTake).toList();
      
      if (quizQuestions.isEmpty) {
         if (mounted) state = state.copyWith(isLoading: false, errorMessage: '予期せぬエラー: 出題データ作成失敗');
         return;
      }
      
      if (mounted) {
        state = QuizState(
          questions: quizQuestions,
          isLoading: false,
          mode: QuizMode.normal,
          errorMessage: null,
        );
      }
    } catch (e) {
       print('Quiz Error: $e');
       if (mounted) state = state.copyWith(isLoading: false, errorMessage: 'エラーが発生しました: $e');
    }
  }

  Future<void> startReviewQuiz() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _ensureLoaded();
      if (!mounted) return;
      
      if (_allQuestions.isEmpty) {
         if (mounted) state = state.copyWith(isLoading: false, errorMessage: '問題データがロードされていません。');
         return;
      }

      final dueIds = await _reviewService.getDueQuestionIds();
      
      if (dueIds.isEmpty) {
         if (mounted) {
           state = QuizState(
            questions: [],
            isLoading: false,
            mode: QuizMode.review,
            errorMessage: '現在、復習すべき問題はありません。',
          );
         }
        return;
      }

      final reviewQuestions = _allQuestions.where((q) => dueIds.contains(q.id)).toList();
      
      if (mounted) {
        state = QuizState(
          questions: reviewQuestions,
          isLoading: false,
          mode: QuizMode.review,
          errorMessage: null,
        );
      }
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, errorMessage: '復習モードエラー: $e');
    }
  }

  Future<void> selectOption(int index) async {
    if (state.isAnswered) return;

    final question = state.currentQuestion;
    final isCorrect = index == question.correctIndex;

    // Use actual calculations to show real intervals on buttons
    final calcGood = await _reviewService.calculateNextReview(question.id, 3);
    final calcEasy = await _reviewService.calculateNextReview(question.id, 4);
    int intervalGood = calcGood['interval'] as int;
    int intervalEasy = calcEasy['interval'] as int;
    int delayGood = calcGood['delayMinutes'] as int;
    int delayEasy = calcEasy['delayMinutes'] as int;

    // If card is in learning/relearning phase (graduation):
    // Show the BASE graduation interval: Good="明日"(1日), Easy="3日後"(3日)
    // After "Again" resets step to 0, this ensures correct graduation intervals.
    if (delayGood <= 1440) {
      intervalGood = 1;  // base interval for Good
      delayGood = 1 * 1440;
      intervalEasy = 3;  // base interval for Easy
      delayEasy = 3 * 1440;
    }

    String formatInterval(int days, int minutes) {
      if (minutes < 1440) return '今日';
      if (days == 1) return '明日';
      if (days > 30) return '${(days/30).floor()}ヶ月後';
      return '$days日後';
    }

    final labels = <int, String>{
      1: '今回',   // Again
      2: '今日',   // Hard
      3: formatInterval(intervalGood, delayGood),   // Good
      4: formatInterval(intervalEasy, delayEasy),   // Easy
    };

    if (mounted) {
      state = state.copyWith(
        selectedOptionIndex: index,
        isAnswered: true,
        score: isCorrect ? state.score + 1 : state.score,
        nextIntervalLabels: labels,
      );
    }
  }

  Future<void> rateQuestion(int rating) async {
    final question = state.currentQuestion;
    await _reviewService.saveReview(question.id, rating);
    
    var currentQuestions = List<Question>.from(state.questions);
    
    // If "Again" (1), re-queue the question +10 spots later (or at end)
    if (rating == 1) {
      final insertIndex = (state.currentIndex + 1 + 10).clamp(0, currentQuestions.length);
      // If we are at the end, just appending works, but clamp handles it.
      // We want to insert it so it appears LATER.
      // If insertIndex == length, it appends.
      if (insertIndex >= currentQuestions.length) {
         currentQuestions.add(question);
      } else {
         currentQuestions.insert(insertIndex, question);
      }
      
      // Update state with new list immediately so nextQuestion sees it? 
      // Actually nextQuestion just increments index.
      // We need to update the list in State.
    }
    
    // Proceed to next
    if (state.currentIndex < currentQuestions.length) {
       // We must update the list in state first if we modified it
       state = state.copyWith(questions: currentQuestions);
       
       // Then move index
       nextQuestion();
    }
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
        errorMessage: null,
      );
    }
  }

  void resetQuiz() {
    startNormalQuiz(); // Retry or restart
  }
  
  List<T> listShim<T>(List<T> list) => List<T>.from(list);
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});

final dueQuestionCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final service = ReviewService();
  final dueIds = await service.getDueQuestionIds();
  return dueIds.length;
});

final statsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ReviewService().getStats();
});

final futureReviewsProvider = FutureProvider.autoDispose<List<int>>((ref) async {
  return ReviewService().getFutureReviews(7);
});
