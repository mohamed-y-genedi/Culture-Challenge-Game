import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseClientWrapper {
  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || anonKey == null) {
      throw Exception('Supabase environment variables not found. Make sure .env contains SUPABASE_URL and SUPABASE_ANON_KEY');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
