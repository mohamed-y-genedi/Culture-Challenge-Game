import 'package:flutter/material.dart';
import '../services/user_preferences.dart';
import '../utils/translations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  String _selectedAvatar = 'assets/avatars/1.png';
  String _selectedCountry = 'SA'; // Default Saudi Arabia
  String _selectedLanguage = 'ar'; // Default Arabic

  final List<String> _avatars = [
    'assets/avatars/1.png',
    'assets/avatars/2.png',
    'assets/avatars/3.png',
    'assets/avatars/4.png',
    'assets/avatars/5.png',
  ];

  final Map<String, String> _countries = {
    'SA': 'السعودية 🇸🇦',
    'EG': 'مصر 🇪🇬',
    'AE': 'الإمارات 🇦🇪',
    'MA': 'المغرب 🇲🇦',
    'DZ': 'الجزائر 🇩🇿',
    'JO': 'الأردن 🇯🇴',
    'KW': 'الكويت 🇰🇼',
    'QA': 'قطر 🇶🇦',
    'OM': 'عمان 🇴🇲',
    'BH': 'البحرين 🇧🇭',
    'IQ': 'العراق 🇮🇶',
    'SY': 'سوريا 🇸🇾',
    'LB': 'لبنان 🇱🇧',
    'PS': 'فلسطين 🇵🇸',
    'SD': 'السودان 🇸🇩',
    'YE': 'اليمن 🇾🇪',
    'TN': 'تونس 🇹🇳',
    'LY': 'ليبيا 🇱🇾',
  };

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    if (UserPreferences.hasProfile()) {
      setState(() {
        _nicknameController.text = UserPreferences.nickname ?? '';
        _selectedAvatar = UserPreferences.avatarPath ?? _avatars[0];
        _selectedCountry = UserPreferences.countryCode ?? 'SA';
        _selectedLanguage = UserPreferences.language ?? 'ar';
      });
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a nickname'.tr())));
      return;
    }

    await UserPreferences.setNickname(nickname);
    await UserPreferences.setAvatarPath(_selectedAvatar);
    await UserPreferences.setCountryCode(_selectedCountry);
    await UserPreferences.setLanguage(_selectedLanguage);

    if (mounted) {
      // Navigate back to home and remove all previous routes so the game starts fresh from home
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Selection Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D44),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Choose Avatar'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Selected Avatar Preview
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      backgroundImage: AssetImage(_selectedAvatar),
                    ),
                    const SizedBox(height: 16),
                    // Avatar Grid
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _avatars.length,
                        itemBuilder: (context, index) {
                          final avatar = _avatars[index];
                          final isSelected = avatar == _selectedAvatar;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAvatar = avatar;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.secondary
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: AssetImage(avatar),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nickname Input
              TextField(
                controller: _nicknameController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'Nickname'.tr(),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 24),

              // Country Dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D44),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCountry,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D2D44),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCountry = newValue;
                        });
                      }
                    },
                    items: _countries.entries.map<DropdownMenuItem<String>>((
                      entry,
                    ) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value, textAlign: TextAlign.right),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Language Toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D44),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedLanguage == 'ar'
                          ? 'Arabic'.tr()
                          : 'English'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: _selectedLanguage == 'en',
                      onChanged: (bool isEnglish) {
                        setState(() {
                          _selectedLanguage = isEnglish ? 'en' : 'ar';
                        });
                      },
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                    Text(
                      'Language'.tr(),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Save Button
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(
                  'Save'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
