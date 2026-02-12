import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_provider.dart';
import '../widgets/ad_banner.dart';
import 'result_screen.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);
    final quizNotifier = ref.read(quizProvider.notifier);

    // Navigate to ResultScreen if completed
    // Note: In a real app, use a listener or proper navigation handling
    if (quizState.isCompleted) {
      // Use Future.microtask to avoid build phase navigation errors
      Future.microtask(() => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResultScreen()),
      ));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (quizState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = quizState.currentQuestion;

    return Scaffold(
      appBar: AppBar(
        title: Text('問題 ${quizState.currentIndex + 1} / ${quizState.questions.length}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    question.question,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(question.options.length, (index) {
                    final isSelected = quizState.selectedOptionIndex == index;
                    final isCorrect = index == question.correctIndex;
                    final isAnswered = quizState.isAnswered;

                    Color? buttonColor;
                    if (isAnswered) {
                      if (isSelected) {
                        buttonColor = isCorrect ? Colors.green.shade100 : Colors.red.shade100;
                      } else if (isCorrect && isSelected) {
                        // Highlight correct answer if wrong one was selected? 
                        // Requirement says "Immediate feedback".
                        // Usually we show correct answer if user answered wrong.
                        buttonColor = Colors.green.shade100;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: OutlinedButton(
                        onPressed: isAnswered ? null : () => quizNotifier.selectOption(index),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: buttonColor,
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.centerLeft,
                          side: BorderSide(
                            color: isAnswered && (isSelected || (isCorrect && isAnswered)) 
                                ? (isCorrect ? Colors.green : Colors.red) 
                                : Colors.grey,
                          ),
                        ),
                        child: Text(
                          question.options[index],
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    );
                  }),
                  if (quizState.isAnswered) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quizState.selectedOptionIndex == question.correctIndex ? '正解！' : '不正解...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: quizState.selectedOptionIndex == question.correctIndex
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '【解説】',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(question.explanation),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: quizNotifier.nextQuestion,
                      child: Text(
                        quizState.currentIndex == quizState.questions.length - 1
                            ? '結果を見る'
                            : '次へ',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const AdBanner(),
        ],
      ),
    );
  }
}
