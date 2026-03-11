import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
//import 'package:google_fonts/google_fonts.dart';
import '../providers/game_provider.dart';
import '../utils/translations.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        // Auto-navigate if game starts
        if (provider.room?.status == 'playing') {
          // Use addPostFrameCallback to avoid build-time navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/game');
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('LOBBY'.tr()),
            centerTitle: true,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                provider.leaveRoom();
                Navigator.pop(context);
              },
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'ROOM CODE'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: provider.roomCode ?? ''),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied to clipboard!'.tr())),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        provider.roomCode ?? '...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '(Tap to copy)'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white30, fontSize: 12),
                  ),
                  const SizedBox(height: 24),

                  // Players list
                  Expanded(
                    child: Card(
                      color: Colors.transparent,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Players'.tr(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (provider.room != null)
                              Expanded(
                                child: provider.room!.gameMode == 'teams'
                                    ? _buildTeamsView(provider, context)
                                    : _buildFFAView(provider, context),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Host controls or waiting message
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: provider.isHost
                          ? Semantics(
                              label: 'START_GAME_BTN',
                              button: true,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                    vertical: 16,
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                onPressed:
                                    (provider.room != null &&
                                        provider.room!.players.length ==
                                            provider.room!.maxPlayers)
                                    ? () async {
                                        final success = await provider
                                            .startGame();
                                        if (!success && context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                provider.errorMessage ??
                                                    'Failed to start game'.tr(),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                                child: Text(
                                  'START GAME',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              'Waiting for players to join...'.tr(),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFFAView(GameProvider provider, BuildContext context) {
    return ListView.builder(
      itemCount: provider.room!.maxPlayers,
      itemBuilder: (context, index) {
        final playersList = provider.room!.players.keys.toList();
        if (index < playersList.length) {
          // Occupied slot
          final playerName = playersList[index];
          final isMe = playerName == provider.nickname;
          return _PlayerChip(
            name: playerName,
            label: isMe ? 'You'.tr() : 'Player ${index + 1}'.tr(),
            isMe: isMe,
            isHost: playerName == provider.room!.hostNickname,
          );
        } else {
          // Empty slot
          return _PlayerChip(
            name: 'Empty Slot'.tr(),
            label: 'Waiting for player...'.tr(),
            isEmpty: true,
          );
        }
      },
    );
  }

  Widget _buildTeamsView(GameProvider provider, BuildContext context) {
    final Map<String, dynamic> playersData = provider.room!.players;

    // Group occupying players by team
    final team1Players = <String>[];
    final team2Players = <String>[];

    playersData.forEach((name, data) {
      if (data['team'] == 1) {
        team1Players.add(name);
      } else if (data['team'] == 2) {
        team2Players.add(name);
      }
    });

    final int slotsPerTeam = (provider.room!.maxPlayers / 2).ceil();

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
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: slotsPerTeam,
                  itemBuilder: (context, index) {
                    if (index < team1Players.length) {
                      final playerName = team1Players[index];
                      final isMe = playerName == provider.nickname;
                      return _PlayerChip(
                        name: playerName,
                        label: isMe ? 'You'.tr() : 'Player'.tr(),
                        isMe: isMe,
                        isHost: playerName == provider.room!.hostNickname,
                        teamColor: Colors.redAccent.withValues(alpha: 0.2),
                      );
                    } else {
                      return _PlayerChip(
                        name: 'Empty'.tr(),
                        label: 'Waiting...'.tr(),
                        isEmpty: true,
                        teamColor: Colors.redAccent.withValues(alpha: 0.05),
                      );
                    }
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
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: slotsPerTeam,
                  itemBuilder: (context, index) {
                    if (index < team2Players.length) {
                      final playerName = team2Players[index];
                      final isMe = playerName == provider.nickname;
                      return _PlayerChip(
                        name: playerName,
                        label: isMe ? 'You'.tr() : 'Player'.tr(),
                        isMe: isMe,
                        isHost: playerName == provider.room!.hostNickname,
                        teamColor: Colors.blueAccent.withValues(alpha: 0.2),
                      );
                    } else {
                      return _PlayerChip(
                        name: 'Empty'.tr(),
                        label: 'Waiting...'.tr(),
                        isEmpty: true,
                        teamColor: Colors.blueAccent.withValues(alpha: 0.05),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final String name;
  final String label;
  final bool isEmpty;
  final bool isMe;
  final bool isHost;
  final Color? teamColor;

  const _PlayerChip({
    required this.name,
    required this.label,
    this.isEmpty = false,
    this.isMe = false,
    this.isHost = false,
    this.teamColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Chip(
        avatar: isEmpty
            ? const CircleAvatar(
                backgroundColor: Colors.white12,
                child: Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.white54,
                ),
              )
            : CircleAvatar(
                backgroundColor: isMe
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.white24,
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEmpty ? label : '$label: $name',
              style: TextStyle(
                color: isEmpty ? Colors.white54 : Colors.white,
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isHost && !isEmpty) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.workspace_premium,
                color: Colors.amber,
                size: 20,
              ),
            ],
          ],
        ),
        backgroundColor: Colors.transparent,
        side: BorderSide(color: isEmpty ? Colors.white10 : Colors.white24),
      ),
    );
  }
}
