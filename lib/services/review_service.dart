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

  Future<void> saveReviewStatus(int questionId, bool isCorrect) async {
    final data = await _loadData();
    final String idStr = questionId.toString();
    
    // Check if it's a new card (no interval yet or interval 0 not strictly new but close enough for MVP logic)
    // Better: check if key exists.
    bool isNew = !data.containsKey(idStr);
    
    Map<String, dynamic> itemData = data[idStr] ?? {
      'interval': 0,
      'nextReview': DateTime.now().millisecondsSinceEpoch,
      'learnedDate': DateTime.now().millisecondsSinceEpoch,
    };

    if (isNew) {
      await _incrementDailyNewCount();
    }

    int interval = itemData['interval'] as int;
    int nextReview;

    if (isCorrect) {
      if (interval == 0) {
        interval = 1;
      } else {
        interval = (interval * 2.5).round(); // SM-2 like expansion
      }
      nextReview = DateTime.now().add(Duration(days: interval)).millisecondsSinceEpoch;
    } else {
      interval = 0; // Reset
      nextReview = DateTime.now().millisecondsSinceEpoch;
    }

    itemData['interval'] = interval;
    itemData['nextReview'] = nextReview;
    itemData['lastReview'] = DateTime.now().millisecondsSinceEpoch;

    data[idStr] = itemData;

    await _saveData(data);
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
