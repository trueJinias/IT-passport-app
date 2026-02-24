import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:it_passport_app/services/review_service.dart';

void main() {
  group('ReviewService Tests', () {
    late ReviewService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = ReviewService();
    });

    test('Initial stats should be zero', () async {
      final stats = await service.getStats();
      expect(stats['learned'], 0);
      expect(stats['due'], 0);
    });

    test('Saving review status updates stats', () async {
      // Review question 1 correctly
      await service.saveReviewStatus(1, true);

      final stats = await service.getStats();
      expect(stats['learned'], 1);
      
      // Since interval > 0 for correct answer, it shouldn't be due immediately (unless logic changed)
      // Let's check logic: if correct, interval=1 -> nextReview = now + 1 day
      // So due should be 0
      expect(stats['due'], 0);
    });

    test('Incorrect answer resets interval and makes it due immediately', () async {
      // Review question 2 incorrectly
      await service.saveReviewStatus(2, false);

      final stats = await service.getStats();
      expect(stats['learned'], 1);
      // Incorrect -> interval 0 -> nextReview = now
      // So due should be 1
      expect(stats['due'], 1);
    });

    test('resetAll clears all data', () async {
      // Add some data
      await service.saveReviewStatus(1, true);
      await service.saveReviewStatus(2, false);
      
      var stats = await service.getStats();
      expect(stats['learned'], 2);

      // Reset
      await service.resetAll();

      // Check stats
      stats = await service.getStats();
      expect(stats['learned'], 0);
      expect(stats['due'], 0);
    });
  });
}
