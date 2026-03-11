import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:google_fonts/google_fonts.dart';
import '../providers/game_provider.dart';
import '../services/user_preferences.dart';
import '../utils/translations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  void _checkProfile() {
    setState(() {
      _hasProfile = UserPreferences.hasProfile();
    });

    if (!_hasProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/profile');
      });
    }
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    //print("DEBUG: HomeScreen build");
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الثقافة',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (_hasProfile)
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.pushNamed(context, '/profile').then((_) {
                          _checkProfile(); // Refresh when coming back
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 32),
              if (_hasProfile) ...[
                // Profile Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      backgroundImage: AssetImage(
                        UserPreferences.avatarPath ?? 'assets/avatars/1.png',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أهلاً بك،',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            UserPreferences.nickname ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D44),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        UserPreferences.countryCode ?? 'SA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
              Semantics(
                label: 'SINGLE_PLAYER_BTN',
                button: true,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_hasProfile || UserPreferences.nickname == null) {
                      return;
                    }
                    game.setNickname(UserPreferences.nickname!);
                    game.setSinglePlayerMode(true);
                    Navigator.pushNamed(context, '/category');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: Text('SINGLE PLAYER'.tr()),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'MULTIPLAYER_BTN',
                button: true,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_hasProfile || UserPreferences.nickname == null) {
                      return;
                    }
                    game.setNickname(UserPreferences.nickname!);
                    game.setSinglePlayerMode(false);
                    Navigator.pushNamed(context, '/multiplayer_lobby');
                  },
                  child: Text('MULTIPLAYER'.tr()),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'LEADERBOARD_BTN',
                button: true,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/leaderboard');
                    },
                    icon: const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 28,
                    ),
                    label: Text(
                      'Leaderboard'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFC0A040,
                      ).withValues(alpha: 0.2),
                      side: const BorderSide(color: Colors.amber, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
