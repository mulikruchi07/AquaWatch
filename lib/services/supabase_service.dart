import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient client;

  Future<void> initialize() async {
  try {
    await dotenv.load();

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || anonKey == null) {
      throw Exception('Supabase URL or Anon Key not found in .env file');
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
    client = Supabase.instance.client;

    print('✅ Supabase initialized');
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
  }
}

}