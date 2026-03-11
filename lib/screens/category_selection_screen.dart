import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/translations.dart';

class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({super.key});

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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                      final success = await provider.startSinglePlayerGame(
                        apiCategory,
                      );

                      if (provider.errorMessage != null && context.mounted) {
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
                      final success = await provider.createRoom(apiCategory);

                      // If provider set an error, show it
                      if (provider.errorMessage != null && context.mounted) {
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
