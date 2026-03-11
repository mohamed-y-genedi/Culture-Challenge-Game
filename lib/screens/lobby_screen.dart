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
                            Expanded(
                              child: ListView(
                                children: [
                                  if (provider.room?.player1 != null)
                                    _PlayerChip(
                                      name: provider.room!.player1!,
                                      label: 'Player 1'.tr(),
                                    ),
                                  if (provider.room?.player2 != null)
                                    _PlayerChip(
                                      name: provider.room!.player2!,
                                      label: 'Player 2'.tr(),
                                    ),
                                ],
                              ),
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
                      child: Text(
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
}

class _PlayerChip extends StatelessWidget {
  final String name;
  final String label;

  const _PlayerChip({required this.name, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: Colors.white24,
          child: Text(name[0].toUpperCase()),
        ),
        label: Text('$label: $name'),
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: Colors.white24),
      ),
    );
  }
}
