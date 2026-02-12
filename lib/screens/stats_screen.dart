import 'package:flutter/material.dart';
import '../services/review_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('統計'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([
          ReviewService().getStats(),
          ReviewService().getFutureReviews(7),
        ]).then((results) => {
          'stats': results[0],
          'future': results[1],
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final data = snapshot.data!;
          final stats = data['stats'] as Map<String, dynamic>;
          final futureReviews = data['future'] as List<int>;
          
          final learned = stats['learned'];
          final due = stats['due'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatCard('学習済みカード', '$learned / 1000', Colors.blue),
              const SizedBox(height: 10),
              _buildStatCard('復習待ち', '$due 枚', Colors.orange),
               const SizedBox(height: 30),
               const Text('今後7日間の復習予定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 20),
               SizedBox(
                 height: 200,
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: List.generate(7, (index) {
                      final count = futureReviews[index];
                      // Normalize height (max 20 approx)
                      final height = (count / 20 * 150).clamp(10.0, 150.0);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('$count'),
                          const SizedBox(height: 5),
                          Container(
                            width: 20,
                            height: height,
                            color: Colors.blue.defaultShade(index * 100 + 200), // Gradient-ish
                          ),
                          const SizedBox(height: 5),
                          Text('+${index+1}日'),
                        ],
                      );
                   }),
                 ),
               ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

extension ColorExtension on MaterialColor {
  Color defaultShade(int index) {
      // Simple helper locally
      return this[index] ?? this;
  }
}
