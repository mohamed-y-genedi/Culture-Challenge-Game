import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/translations.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context, listen: false);

    // For single player mode
    if (provider.isSinglePlayer) {
      final score = provider.singlePlayerScore;
      // Each question is worth 10 points based on the logic we wrote
      final correctAnswers = score ~/ 10;
      final totalQuestions = provider.currentQuestions.length;
      final isSuccess = correctAnswers >= (totalQuestions / 2);

      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  isSuccess ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 100,
                  color: isSuccess
                      ? Colors.amber
                      : Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 32),
                Text(
                  isSuccess ? 'Congratulations!'.tr() : 'Good Try!'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Score'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  '$correctAnswers / $totalQuestions',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    provider.leaveRoom(); // Clean up state
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  child: Text('Play Again'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Fallback or handle multiplayer end game
    // You can build out the multiplayer result logic here as needed
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Multiplayer Game Finished'.tr()),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                provider.leaveRoom();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              child: Text('Return to Home'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
