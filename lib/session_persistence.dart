import 'package:supabase/supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionPersistence {
  static const _key = 'sb_session';

  static Future<void> save(Session? session) async {
    if (session == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, session.persistSessionString);
  }

  static Future<void> restore(SupabaseClient supabase) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      final res = await supabase.auth.recoverSession(raw);
      if (res.session == null) {
        await prefs.remove(_key); // clear corrupted or expired
      }
    }
  }

  static Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}
