import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/translations.dart';

class MultiplayerResultScreen extends StatelessWidget {
  const MultiplayerResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        final room = provider.room;
        if (room == null) {
          return Scaffold(body: Center(child: Text("Missing Room Data".tr())));
        }

        final isPlayer1 = provider.isPlayer1;

        final myScore = isPlayer1 ? room.p1Score : room.p2Score;
        final opponentScore = isPlayer1 ? room.p2Score : room.p1Score;

        final String myName =
            (isPlayer1 ? room.player1 : room.player2) ?? 'You'.tr();
        final String opponentName =
            (isPlayer1 ? room.player2 : room.player1) ?? 'Opponent'.tr();

        String resultText;
        Color resultColor;
        IconData resultIcon;

        if (myScore > opponentScore) {
          resultText = 'YOU WIN!'.tr();
          resultColor = Colors.greenAccent;
          resultIcon = Icons.emoji_events;
        } else if (opponentScore > myScore) {
          resultText = 'YOU LOSE'.tr();
          resultColor = Colors.redAccent;
          resultIcon = Icons.sentiment_dissatisfied;
        } else {
          resultText = 'IT\'S A DRAW!'.tr();
          resultColor = Colors.amber;
          resultIcon = Icons.handshake;
        }

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(resultIcon, size: 100, color: resultColor),
                    const SizedBox(height: 24),
                    Text(
                      resultText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                        shadows: [
                          Shadow(
                            color: resultColor.withValues(alpha: 0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Score Comparison Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // My Score
                          Column(
                            children: [
                              Text(
                                myName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$myScore',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: myScore >= opponentScore
                                      ? Colors.white
                                      : Colors.white54,
                                ),
                              ),
                              if (myScore > opponentScore)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Icon(Icons.star, color: Colors.amber),
                                ),
                            ],
                          ),

                          const Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white30,
                            ),
                          ),

                          // Opponent Score
                          Column(
                            children: [
                              Text(
                                opponentName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$opponentScore',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: opponentScore >= myScore
                                      ? Colors.white
                                      : Colors.white54,
                                ),
                              ),
                              if (opponentScore > myScore)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Icon(Icons.star, color: Colors.amber),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        // Clean up real-time stream and states
                        provider.leaveRoom();
                        // Navigate completely back to the start
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (route) => false,
                        );
                      },
                      child: Text(
                        'RETURN TO HOME'.tr(),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
