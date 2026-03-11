import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/translations.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  int _maxPlayers = 2;
  String _gameMode = 'ffa';

  final List<String> categories = const [
    'Islamic',
    'History',
    'Science',
    'Technology',
    'Mathematics',
    'Geography',
    'Literature',
    'Famous People',
    'Countries & Capitals',
    'Sports',
    'Riddles',
    'General',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('SELECT CATEGORY'.tr()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (!provider.isSinglePlayer) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Game Mode:'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment<String>(
                            value: 'ffa',
                            label: Text('Individuals'.tr()),
                          ),
                          ButtonSegment<String>(
                            value: 'teams',
                            label: Text('Teams'.tr()),
                          ),
                        ],
                        selected: <String>{_gameMode},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _gameMode = newSelection.first;
                            if (_gameMode == 'teams' && _maxPlayers < 4) {
                              _maxPlayers = 4;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Max Players:'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment<int>(value: 2, label: Text('2')),
                          ButtonSegment<int>(value: 3, label: Text('3')),
                          ButtonSegment<int>(value: 4, label: Text('4')),
                        ],
                        selected: <int>{_maxPlayers},
                        onSelectionChanged: _gameMode == 'teams'
                            ? null
                            : (Set<int> newSelection) {
                                setState(() {
                                  _maxPlayers = newSelection.first;
                                });
                              },
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];

                      // Send the exact English category name to Supabase
                      String apiCategory = category;

                      return _CategoryCard(
                        category: category,
                        enabled: !provider.isLoading,
                        onTap: () async {
                          if (provider.isSinglePlayer) {
                            final success = await provider
                                .startSinglePlayerGame(apiCategory);

                            if (provider.errorMessage != null &&
                                context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(provider.errorMessage!)),
                              );
                              return;
                            }

                            if (success && context.mounted) {
                              Navigator.pushNamed(context, '/game');
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    provider.errorMessage ??
                                        'Failed to start game'.tr(),
                                  ),
                                ),
                              );
                            }
                          } else {
                            final success = await provider.createRoom(
                              apiCategory,
                              maxPlayers: _maxPlayers,
                              gameMode: _gameMode,
                            );

                            // If provider set an error, show it
                            if (provider.errorMessage != null &&
                                context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(provider.errorMessage!)),
                              );
                              return;
                            }

                            if (success && context.mounted) {
                              Navigator.pushNamed(context, '/lobby');
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    provider.errorMessage ??
                                        'Failed to create room'.tr(),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // Global loading overlay while provider.isLoading is true
          if (provider.isLoading)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final VoidCallback onTap;
  final bool enabled;

  const _CategoryCard({
    required this.category,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForCategory(category),
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              category.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Islamic':
        return Icons.mosque;
      case 'History':
        return Icons.history_edu;
      case 'Science':
        return Icons.science;
      case 'Technology':
        return Icons.computer;
      case 'Mathematics':
        return Icons.calculate;
      case 'Geography':
        return Icons.public;
      case 'Literature':
        return Icons.menu_book;
      case 'Famous People':
        return Icons.person;
      case 'Countries & Capitals':
        return Icons.flag;
      case 'Sports':
        return Icons.sports_soccer;
      case 'Riddles':
        return Icons.lightbulb;
      default:
        return Icons.grid_view; // General
    }
  }
}
