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

        final allPlayers = room.players.entries.map((e) {
          final data = e.value as Map<String, dynamic>;
          return {
            'name': e.key,
            'score': data['score'] ?? 0,
            'team': data['team'],
          };
        }).toList();

        allPlayers.sort(
          (a, b) => (b['score'] as int).compareTo(a['score'] as int),
        );

        final myName = provider.nickname ?? 'You'.tr();
        final myData = allPlayers.firstWhere(
          (p) => p['name'] == myName,
          orElse: () => {'name': myName, 'score': 0, 'team': null},
        );
        final myScore = myData['score'] as int;
        final myTeam = myData['team'] as int?;

        // Find highest individual score (needed for both modes)
        final topScore = allPlayers.isNotEmpty
            ? allPlayers.first['score'] as int
            : 0;

        String resultText;
        Color resultColor;
        IconData resultIcon;

        if (room.gameMode == 'teams') {
          // --- TEAMS MODE LOGIC ---
          int team1Score = 0;
          int team2Score = 0;

          for (var p in allPlayers) {
            if (p['team'] == 1) {
              team1Score += p['score'] as int;
            } else if (p['team'] == 2) {
              team2Score += p['score'] as int;
            }
          }

          if (team1Score == team2Score) {
            resultText = 'IT\'S A DRAW!'.tr();
            resultColor = Colors.amber;
            resultIcon = Icons.handshake;
          } else {
            final winningTeam = team1Score > team2Score ? 1 : 2;
            if (myTeam == winningTeam) {
              resultText = 'YOUR TEAM WON!'.tr();
              resultColor = Colors.greenAccent;
              resultIcon = Icons.emoji_events;
            } else {
              resultText = 'YOUR TEAM LOST'.tr();
              resultColor = Colors.redAccent;
              resultIcon = Icons.sentiment_dissatisfied;
            }
          }
        } else {
          // --- FREE FOR ALL (FFA) MODE LOGIC ---
          final amIWinner = myScore == topScore && allPlayers.isNotEmpty;
          final isDraw =
              allPlayers.length > 1 &&
              allPlayers[0]['score'] == allPlayers[1]['score'] &&
              topScore == myScore;

          if (isDraw) {
            resultText = 'IT\'S A DRAW!'.tr();
            resultColor = Colors.amber;
            resultIcon = Icons.handshake;
          } else if (amIWinner) {
            resultText = 'YOU WIN!'.tr();
            resultColor = Colors.greenAccent;
            resultIcon = Icons.emoji_events;
          } else {
            resultText = 'YOU LOSE'.tr();
            resultColor = Colors.redAccent;
            resultIcon = Icons.sentiment_dissatisfied;
          }
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
                    Icon(resultIcon, size: 80, color: resultColor),
                    const SizedBox(height: 16),
                    Text(
                      resultText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
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
                    const SizedBox(height: 32),

                    // Score Comparison Box
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
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
                        child: room.gameMode == 'teams'
                            ? _buildTeamsResult(context, allPlayers, myName)
                            : ListView.separated(
                                itemCount: allPlayers.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(color: Colors.white10),
                                itemBuilder: (context, index) {
                                  final pName =
                                      allPlayers[index]['name'] as String;
                                  final pScore =
                                      allPlayers[index]['score'] as int;
                                  final isMe = pName == myName;
                                  final isWinner = pScore == topScore;

                                  return ListTile(
                                    leading: Text(
                                      '#${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    title: Text(
                                      isMe ? '$pName (${"You".tr()})' : pName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: isMe
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isMe
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.secondary
                                            : Colors.white70,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$pScore',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: isWinner
                                                ? Colors.amber
                                                : Colors.white,
                                          ),
                                        ),
                                        if (isWinner)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8.0),
                                            child: Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
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

  Widget _buildTeamsResult(
    BuildContext context,
    List<Map<String, dynamic>> allPlayers,
    String myName,
  ) {
    int team1Score = 0;
    int team2Score = 0;
    final team1Players = <Map<String, dynamic>>[];
    final team2Players = <Map<String, dynamic>>[];

    for (var p in allPlayers) {
      if (p['team'] == 1) {
        team1Score += p['score'] as int;
        team1Players.add(p);
      } else if (p['team'] == 2) {
        team2Score += p['score'] as int;
        team2Players.add(p);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TEAM 1 (RED)
        Expanded(
          child: Column(
            children: [
              Text(
                'Team Red'.tr(),
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                '$team1Score',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: team1Players.length,
                  itemBuilder: (context, index) {
                    final p = team1Players[index];
                    return _buildTeamPlayerTile(context, p, myName);
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),
        Container(width: 1, color: Colors.white24),
        const SizedBox(width: 8),

        // TEAM 2 (BLUE)
        Expanded(
          child: Column(
            children: [
              Text(
                'Team Blue'.tr(),
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                '$team2Score',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: team2Players.length,
                  itemBuilder: (context, index) {
                    final p = team2Players[index];
                    return _buildTeamPlayerTile(context, p, myName);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamPlayerTile(
    BuildContext context,
    Map<String, dynamic> player,
    String myName,
  ) {
    final pName = player['name'] as String;
    final pScore = player['score'] as int;
    final isMe = pName == myName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              isMe ? '$pName (${"You".tr()})' : pName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                color: isMe
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$pScore',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
