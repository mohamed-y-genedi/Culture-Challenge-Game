import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/translations.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  final TextEditingController _roomCodeController = TextEditingController();

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  void _createRoom() {
    final game = Provider.of<GameProvider>(context, listen: false);
    game.setSinglePlayerMode(false);
    // Option B: Navigate to Category Screen to pick category before creating the room
    Navigator.pushNamed(context, '/category');
  }

  void _joinRoom() async {
    final game = Provider.of<GameProvider>(context, listen: false);

    if (_roomCodeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a room code'.tr())));
      return;
    }

    game.setSinglePlayerMode(false);

    final success = await game.joinRoom(_roomCodeController.text.toUpperCase());

    if (game.errorMessage != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(game.errorMessage!)));
      return;
    }

    if (success && mounted) {
      Navigator.pushNamed(context, '/lobby');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(game.errorMessage ?? 'Failed to join room'.tr()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('MULTIPLAYER'.tr()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people, size: 80, color: Colors.white70),
              const SizedBox(height: 32),

              // Create Room Section
              Semantics(
                label: 'CREATE_ROOM_BTN',
                button: true,
                child: ElevatedButton(
                  onPressed: game.isLoading ? null : _createRoom,
                  child: Text('CREATE ROOM'.tr()),
                ),
              ),

              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white24)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR'.tr(),
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 32),

              // Join Room Section
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'ROOM_CODE_INPUT',
                      child: TextField(
                        controller: _roomCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'ROOM CODE'.tr(),
                          hintText: 'XA4B2',
                          prefixIcon: const Icon(Icons.vpn_key),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Semantics(
                    label: 'JOIN_ROOM_BTN',
                    button: true,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      onPressed: game.isLoading ? null : _joinRoom,
                      child: game.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('JOIN'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
