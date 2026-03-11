import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
//import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
    _checkAppVersion();
  }

  Future<void> _checkAppVersion() async {
    // Wait for animation to mostly finish
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final SupabaseService service = SupabaseService();
      final settings = await service.getAppSettings();
      final packageInfo = await PackageInfo.fromPlatform();

      if (settings != null) {
        final String latestVersion = settings['latest_version'] ?? '1.0.0';
        final String updateUrl = settings['update_url'] ?? '';
        final bool isMandatory = settings['is_mandatory'] ?? false;
        final String currentVersion = packageInfo.version;

        if (_isVersionOlder(currentVersion, latestVersion) && isMandatory) {
          _showUpdateDialog(updateUrl);
          return; // Stop navigation
        }
      }
    } catch (e) {
      debugPrint('Error checking app version: $e');
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  bool _isVersionOlder(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < currentParts.length && i < latestParts.length; i++) {
      if (currentParts[i] < latestParts[i]) return true;
      if (currentParts[i] > latestParts[i]) return false;
    }
    return latestParts.length > currentParts.length;
  }

  void _showUpdateDialog(String updateUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text(
              'تحديث جديد متاح! 🚀',
              textAlign: TextAlign.right,
            ),
            content: const Text(
              'لقد أطلقنا نسخة جديدة ومحسنة من اللعبة. يرجى التحديث للاستمرار في اللعب.',
              textAlign: TextAlign.right,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final Uri url = Uri.parse(updateUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    debugPrint('Could not launch $updateUrl');
                  }
                },
                child: const Text('تحديث الآن'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.quiz,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'CULTURE\nCHALLENGE',
                textAlign: TextAlign.center,
                style: /*GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                )*/ TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
