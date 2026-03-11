import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? get nickname => _prefs.getString('profile_nickname');
  static Future<void> setNickname(String value) async => _prefs.setString('profile_nickname', value);

  static String? get avatarPath => _prefs.getString('profile_avatar');
  static Future<void> setAvatarPath(String value) async => _prefs.setString('profile_avatar', value);

  static String? get countryCode => _prefs.getString('profile_country');
  static Future<void> setCountryCode(String value) async => _prefs.setString('profile_country', value);

  static String? get language => _prefs.getString('profile_language');
  static Future<void> setLanguage(String value) async => _prefs.setString('profile_language', value);

  static bool hasProfile() {
    return _prefs.getString('profile_nickname') != null &&
           _prefs.getString('profile_nickname')!.isNotEmpty;
  }

  static Future<void> clearProfile() async {
    await _prefs.remove('profile_nickname');
    await _prefs.remove('profile_avatar');
    await _prefs.remove('profile_country');
    await _prefs.remove('profile_language');
  }
}
