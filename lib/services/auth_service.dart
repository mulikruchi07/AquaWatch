import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // 1. Check if email already exists
      final emailCheck = await _supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (emailCheck != null) {
        return "Email already exists. Please use a different email.";
      }

      // 2. Try signup
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
        emailRedirectTo: 'https://your-app.com/login', // Custom URL
      );

      final user = response.user;

      if (user == null) return "Signup failed.";

      // 3. Insert into users table
      await _supabase.from('users').insert({
        'id': user.id,
        'email': email,
        'username': username,
        'created_at': DateTime.now().toIso8601String(),
      });

      return "Verification mail sent. Please verify your email to login.";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Unexpected error occurred.';
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Unexpected error occurred';
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}