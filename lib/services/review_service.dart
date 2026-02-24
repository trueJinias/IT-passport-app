import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static const String _keyReviewData = 'review_data';
  static const String _keyDailyStats = 'daily_stats'; // { "2024-01-01": { "new": 5, "review": 10 } }

  Future<Map<String, dynamic>> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyReviewData);
    if (jsonString == null) return {};
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  Future<void> _saveData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReviewData, json.encode(data));
  }

  // Record that a "new" card was learned today
  Future<void> _incrementDailyNewCount() async {
    final prefs = await SharedPreferences.getInstance();
    final String nowKey = _getTodayKey();
    
    String? statsString = prefs.getString(_keyDailyStats);
    Map<String, dynamic> stats = statsString != null ? json.decode(statsString) : {};
    
    Map<String, dynamic> todayStats = stats[nowKey] != null ? Map<String, dynamic>.from(stats[nowKey]) : {'new': 0, 'review': 0};
    todayStats['new'] = (todayStats['new'] as int) + 1;
    
    stats[nowKey] = todayStats;
    await prefs.setString(_keyDailyStats, json.encode(stats));
  }
  
  // Create a helper to check how many new cards done today
  Future<int> getNewCardsCountToday() async {
    final prefs = await SharedPreferences.getInstance();
    final String nowKey = _getTodayKey();
    
    String? statsString = prefs.getString(_keyDailyStats);
    if (statsString == null) return 0;
    
    Map<String, dynamic> stats = json.decode(statsString);
    if (stats[nowKey] == null) return 0;
    
    return stats[nowKey]['new'] ?? 0;
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  // Calculate next review details without saving (for UI display)
  // Rating: 1=Again, 2=Hard, 3=Good, 4=Easy
  Future<Map<String, dynamic>> calculateNextReview(int questionId, int rating) async {
    final data = await _loadData();
    final String idStr = questionId.toString();
    
    Map<String, dynamic> itemData = data[idStr] ?? {
      'interval': 0, // 0 means learning/relearning steps
      'step': 0, // current learning step index (used as review count after graduation)
      'baseInterval': 1,
      'ease': 2.5,
    };
    
    int interval = itemData['interval'] as int? ?? 0;
    int step = itemData['step'] as int? ?? 0;
    int? savedBase = itemData['baseInterval'] as int?;
    
    // Heuristic for legacy data
    if (interval > 0 && step == 0) {
      step = 1;
    }
    
    int baseInterval = savedBase ?? 1;
    if (savedBase == null && interval > 0) {
       // Estimate base for legacy data
       baseInterval = (interval == 3 || interval % 3 == 0 || interval % 8 == 0) ? 3 : 1;
    }

    double ease = itemData['ease'] as double? ?? 2.5;
    int delayMinutes = 0;

    if (rating == 1) { // Again
      interval = 0; 
      baseInterval = 1;
      step = 0;
      delayMinutes = 1; 
      ease = (ease - 0.2).clamp(1.3, 5.0);
    } else if (rating == 2) { // Hard
       if (interval == 0) {
         // Graduating from Learning via Hard
         baseInterval = 1;
         interval = 1;
         step = 1;
         delayMinutes = 1;
       } else {
         // Review phase: Hard means review again very soon (today)
         // We keep the card at its current level but schedule it for now.
         delayMinutes = 1; 
       }
       ease = (ease - 0.15).clamp(1.3, 5.0);
    } else if (rating == 3 || rating == 4) { // Good or Easy
       if (interval == 0) {
         // 初回学習時: 正解=1日、簡単=3日
         baseInterval = (rating == 3) ? 1 : 3;
         interval = baseInterval;
         step = 1;
         delayMinutes = interval * 1440; // 1日 or 3日
       } else {
         // 復習時: n × base × 2.5
         int effectiveBase = (rating == 4) ? 3 : 1;
         interval = ((step + 1) * effectiveBase * 2.5).round();
         if (interval < 1) interval = 1;

         if (rating == 4) baseInterval = 3; else baseInterval = 1;

         step += 1;
         delayMinutes = interval * 1440;
       }
       if (rating == 4) ease += 0.15;
    }
    
    if (ease > 5.0) ease = 5.0; 
    
    // Calculate new timestamp
    int nextReview = DateTime.now().add(Duration(minutes: delayMinutes)).millisecondsSinceEpoch;
    
    return {
       'nextReview': nextReview,
       'interval': interval,
       'step': step,
       'ease': ease,
       'delayMinutes': delayMinutes, // Track delay for UI mapping
       'encodedData': {
         'interval': interval,
         'step': step,
         'baseInterval': baseInterval,
         'ease': ease,
         'nextReview': nextReview,
         'lastReview': DateTime.now().millisecondsSinceEpoch,
       }
    };
  }

  // Save the review data based on selected rating
  Future<void> saveReview(int questionId, int rating) async {
    final data = await _loadData();
    final String idStr = questionId.toString();
    bool isNew = !data.containsKey(idStr);
    
    if (isNew) {
      await _incrementDailyNewCount();
    }
    
    final calculation = await calculateNextReview(questionId, rating);
    data[idStr] = calculation['encodedData'];
    
    await _saveData(data);
  }

  // Legacy support cleanup or keep if needed, but we typically replace it
  Future<void> saveReviewStatus(int questionId, bool isCorrect) async {
     // Default mapping: Correct -> Good (3), Incorrect -> Again (1)
     await saveReview(questionId, isCorrect ? 3 : 1);
  }

  Future<List<int>> getDueQuestionIds() async {
    final data = await _loadData();
    final now = DateTime.now().millisecondsSinceEpoch;
    final List<int> dueIds = [];

    data.forEach((key, value) {
      final nextReview = value['nextReview'] as int;
      if (nextReview <= now) {
        dueIds.add(int.parse(key));
      }
    });

    return dueIds;
  }
  
  // Get IDs of questions that have been learned (present in review_data)
  Future<List<int>> getLearnedQuestionIds() async {
    final data = await _loadData();
    return data.keys.map((k) => int.parse(k)).toList();
  }
  
  // Stats helpers
  Future<Map<String, dynamic>> getStats() async {
      final data = await _loadData();
      int learned = data.length;
      int due = 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      data.forEach((k, v) {
          if ((v['nextReview'] as int) <= now) due++;
      });
      
      return {
          'learned': learned,
          'due': due,
      };
  }

  Future<List<int>> getFutureReviews(int days) async {
    final data = await _loadData();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final msPerDay = 24 * 60 * 60 * 1000;
    
    List<int> counts = List.filled(days, 0);
    
    data.forEach((k, v) {
      final nextReview = v['nextReview'] as int;
      if (nextReview >= todayStart) {
        final diff = nextReview - todayStart;
        final dayIndex = (diff / msPerDay).floor();
        if (dayIndex >= 0 && dayIndex < days) {
          counts[dayIndex]++;
        }
      }
    });
    
    return counts;
  }

  Future<void> resetAll() async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.remove(_keyReviewData);
     await prefs.remove(_keyDailyStats);
  }
}
