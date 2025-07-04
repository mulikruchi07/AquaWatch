import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart'; // Corrected import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import 'dart:async'; // Import for StreamSubscription

// Initialize Supabase client
final supabase = SupabaseClient(
  'https://himkdnnczzfzmwmjxlaa.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpbWtkbm5jenpmem13bWp4bGFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyNTg0NjcsImV4cCI6MjA2NjgzNDQ2N30.Rib26sSBExk_22UxcZrssaT0tWNk1mN0ghJtvK4svWw',
);
ValueNotifier<bool> isWifiConnectedNotifier = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter widgets are initialized
  runApp(AquaWatchApp());
}

class AquaWatchApp extends StatefulWidget {
  const AquaWatchApp({super.key});

  @override
  _AquaWatchAppState createState() => _AquaWatchAppState();
}

class _AquaWatchAppState extends State<AquaWatchApp> {
  ThemeMode _themeMode = ThemeMode.system;
  String language = 'English';

  void _changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaWatch',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _themeMode,
      home: InitialScreen(onThemeChanged: _changeTheme),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF4689C8),
      scaffoldBackgroundColor: const Color(0xFFF5F9FF), // Light blue background
      cardColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Color(0xFF1F2937)),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF4689C8)),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF60A5FA),
      scaffoldBackgroundColor: const Color(0xFF1E293B),
      cardColor: const Color(0xFF334155),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF334155),
        foregroundColor: Color(0xFFF1F5F9),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Color(0xFFF1F5F9)),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF60A5FA)),
    );
  }
}

class InitialScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const InitialScreen({super.key, required this.onThemeChanged});

  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final isRegistered = prefs.getBool('isRegistered') ?? false;
      final isTankSetupDone = prefs.getBool('isTankSetupDone') ?? false;
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      Widget nextScreen;

      if (!isRegistered && !isLoggedIn) {
        nextScreen = LoginScreen(onThemeChanged: widget.onThemeChanged);
      } else if (!isTankSetupDone && !isLoggedIn) {
        nextScreen = BluetoothDevicePage(onThemeChanged: widget.onThemeChanged);
      } else {
        nextScreen = MainScreen(onThemeChanged: widget.onThemeChanged);
      }

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => nextScreen));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4689C8), Color(0xFF5FC8D6)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.water_drop,
                  size: 60,
                  color: Color(0xFF4689C8),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'AquaWatch',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
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

class LoginScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const LoginScreen({super.key, required this.onThemeChanged});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final username = _emailController.text.trim(); // it's actually username
        final password = _passwordController.text.trim();

        // Step 1: Fetch email for this username from Supabase 'users' table
        final response = await supabase
            .from('users')
            .select('email')
            .eq('name', username)
            .maybeSingle();

        if (response == null || response['email'] == null) {
          throw Exception('Username not found');
        }

        final email = response['email'];

        // Step 2: Try to log in using email and password
        final loginResponse = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (loginResponse.user == null) {
          throw Exception('Login failed');
        }

        // Optional: mark as logged in
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // Step 3: Navigate to main screen
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MainScreen(onThemeChanged: widget.onThemeChanged),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      } catch (e) {
        // ignore: avoid_print
        print('❌ Login error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Login failed. Check username or password. ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainScreen(onThemeChanged: widget.onThemeChanged),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF1E293B), Color(0xFF334155)]
                : const [Color(0xFFF5F9FF), Color(0xFFE6F0FA)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(isDark),
                  const SizedBox(height: 40), // Reduced from 60
                  _buildLoginForm(isDark),
                  const SizedBox(height: 20), // Reduced from 30
                  _buildSignUpPrompt(isDark),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _testLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF4689C8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Test Login (Skip Auth)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    size: 40,
                    color: Color(0xFF4689C8),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF475569).withOpacity(0.3)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF475569).withOpacity(0.3)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.lock,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF1791C8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignUpPrompt(bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          RegisterScreen(onThemeChanged: widget.onThemeChanged),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            );
                          },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RegisterScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const RegisterScreen({super.key, required this.onThemeChanged});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      setState(() => _isLoading = true);

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final name = _nameController.text.trim();

        // Existing user check (this is good)
        final existingUser = await supabase
            .from('users')
            .select('email')
            .eq('email', email)
            .maybeSingle();

        if (existingUser != null) {
          throw Exception(
            '⚠️ Email already registered in custom users table.',
          ); // More specific message
        }

        // Perform Supabase sign up. This sends the OTP email.
        // The user is NOT fully authenticated until OTP is verified.
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (response.user == null) {
          // If response.user is null, it means the sign-up itself failed (e.g., duplicate email in Supabase auth)
          throw Exception(
            "User creation failed: No user in response. Check if email is already registered in Supabase auth.",
          );
        }

        // IMPORTANT: DO NOT insert into 'users' table here.
        // This should happen ONLY after OTP verification.

        // Navigate to OTP verification page
        // ignore: use_build_context_synchronously
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationPage(
              email: email,
              name: name,
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
        );

        // Show a success message that OTP has been sent
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ OTP sent to $email! Please verify.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print(
          '❌ Registration failed: $e',
        ); // This will print the exact Supabase error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Registration failed: ${e.toString()}',
            ), // Show the error to the user
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _launchTerms() async {
    const url = 'https://example.com/terms';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF1E293B), Color(0xFF334155)]
                : const [Color(0xFFF5F9FF), Color(0xFFE6F0FA)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(isDark),
                  const SizedBox(height: 30),
                  _buildRegisterForm(isDark),
                  const SizedBox(height: 20),
                  _buildSignInPrompt(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    size: 40,
                    color: Color(0xFF4689C8),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create our account',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegisterForm(bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF475569).withOpacity(0.3)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF475569).withOpacity(0.3)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.email,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF475569).withOpacity(0.3)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.lock,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return 'Password must contain uppercase letter';
                      }
                      if (!value.contains(RegExp(r'[a-z]'))) {
                        return 'Password must contain lowercase letter';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Password must contain number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF475569).withOpacity(0.3)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.lock,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value!;
                          });
                        },
                        activeColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                        checkColor: isDark ? Colors.black : Colors.white,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _launchTerms,
                          child: Text(
                            'I agree to the Terms and Conditions',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF1791C8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignInPrompt(bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account? ",
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TankSetupScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const TankSetupScreen({super.key, required this.onThemeChanged});

  @override
  _TankSetupScreenState createState() => _TankSetupScreenState();
}

class _TankSetupScreenState extends State<TankSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _capacityController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _heightController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submitTankDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final double height = double.parse(_heightController.text);
        final double capacity = double.parse(_capacityController.text);
        final user = supabase.auth.currentUser;

        if (user != null) {
          // Fetch the esp_id associated with the current user
          final userResponse = await supabase
              .from('users')
              .select('esp_id')
              .eq('id', user.id)
              .single();

          final String? espId = userResponse['esp_id'];

          if (espId != null) {
            // Check if an entry for this esp_id already exists in esp_data
            final existingEspData = await supabase
                .from('esp_data')
                .select('id')
                .eq('esp_id', espId)
                .maybeSingle();

            if (existingEspData != null) {
              // Update existing entry
              await supabase.from('esp_data').update({
                'tank_height': height,
                'tank_capacity': capacity,
              }).eq('esp_id', espId);
            } else {
              // Insert new entry
              await supabase.from('esp_data').insert({
                'esp_id': espId,
                'tank_height': height,
                'tank_capacity': capacity,
                'tds_value': 0.0, // Default values
                'water_level': 0.0, // Default values
                'created_at': DateTime.now().toIso8601String(),
              });
            }

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isTankSetupDone', true);

            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tank details saved successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            // ignore: use_build_context_synchronously
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    MainScreen(onThemeChanged: widget.onThemeChanged),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          } else {
            throw Exception('ESP ID not found for the current user.');
          }
        } else {
          throw Exception('User not logged in.');
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error saving tank details: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save tank details: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF1E293B), Color(0xFF334155)]
                : const [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                  ], // Fixed this line
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(isDark),
                  const SizedBox(height: 40),
                  _buildTankForm(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0, -0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    size: 40,
                    color: Color(0xFF4689C8),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tank Setup',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure your water tank details',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTankForm(bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildHeightField(isDark),
                    const SizedBox(height: 20),
                    _buildCapacityField(isDark),
                    const SizedBox(height: 30),
                    _buildSubmitButton(isDark),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeightField(bool isDark) {
    return TextFormField(
      controller: _heightController,
      keyboardType: TextInputType.number,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: 'Tank Height (cm)',
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        prefixIcon: Icon(
          Icons.height,
          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF475569).withOpacity(0.3)
            : const Color(0xFFF8FAFC),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter tank height';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildCapacityField(bool isDark) {
    return TextFormField(
      controller: _capacityController,
      keyboardType: TextInputType.number,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: 'Tank Capacity (L)',
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        prefixIcon: Icon(
          Icons.water_drop,
          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF475569).withOpacity(0.3)
            : const Color(0xFFF8FAFC),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter tank capacity';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitTankDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? const Color(0xFF60A5FA)
              : const Color(0xFF4689C8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save & Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const MainScreen({super.key, required this.onThemeChanged});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  ThemeMode currentTheme = ThemeMode.system;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      DashboardScreen(onThemeChanged: widget.onThemeChanged),
      AnalyticsScreen(onThemeChanged: widget.onThemeChanged),
      SettingsScreen(onThemeChanged: widget.onThemeChanged),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            backgroundColor: isDark
                ? const Color(0xFF334155).withOpacity(0.95)
                : const Color(0xFFFFFFFF).withOpacity(0.95),
            selectedItemColor: const Color(0xFF4689C8),
            unselectedItemColor: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF6B7280),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const DashboardScreen({super.key, required this.onThemeChanged});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  ThemeMode currentTheme = ThemeMode.system;
  bool isDarkMode = false;

  bool isWifiConnected = false;
  double _tdsValue = 0.0;
  double _waterLevel = 0.0; // Water level as a percentage (0.0 to 1.0)
  String? _espId;
  double _tankCapacity = 1000.0; // Default tank capacity

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
    _fetchEspIdAndData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchEspIdAndData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final userResponse = await supabase
            .from('users')
            .select('esp_id')
            .eq('id', user.id)
            .single();
        setState(() {
          _espId = userResponse['esp_id'];
        });

        if (_espId != null) {
          final espDataResponse = await supabase
              .from('esp_data')
              .select('tds_value, water_level, tank_capacity')
              .eq('esp_id', _espId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle(); // Use maybeSingle for potentially no data

          if (espDataResponse != null) {
            setState(() {
              _tdsValue =
                  (espDataResponse['tds_value'] as num?)?.toDouble() ?? 0.0;
              _waterLevel =
                  (espDataResponse['water_level'] as num?)?.toDouble() ?? 0.0;
              _tankCapacity =
                  (espDataResponse['tank_capacity'] as num?)?.toDouble() ??
                      1000.0; // Default if null
            });
          }
          _listenToEspData();
        } else {
          // ignore: avoid_print
          print('ESP ID is null for the current user.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ESP ID not found for your account.')),
          );
        }
      } else {
        // For testing purposes without login, simulate an esp_id and data
        setState(() {
          _espId = '001'; // Default ESP ID for testing
          _tdsValue = 150.0;
          _waterLevel = 0.5;
          _tankCapacity = 1000.0;
        });
        _listenToEspData();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching ESP ID or data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
      }
    }
  }

  void _listenToEspData() {
    if (_espId != null) {
      supabase
          .from('esp_data')
          .stream(primaryKey: const ['id'])
          .eq('esp_id', _espId)
          .order('created_at', ascending: false)
          .limit(1)
          .listen((List<Map<String, dynamic>> data) {
            if (data.isNotEmpty) {
              setState(() {
                _tdsValue = (data[0]['tds_value'] as num?)?.toDouble() ?? _tdsValue;
                _waterLevel =
                    (data[0]['water_level'] as num?)?.toDouble() ?? _waterLevel;
                _tankCapacity =
                    (data[0]['tank_capacity'] as num?)?.toDouble() ??
                        _tankCapacity;
              });
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF5F9FF),
                  Color(0xFFE6F0FA),
                ], // Matching login page
              ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context, isDark),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAnimatedCard(
                      TankStatusCard(isDark: isDark, waterLevel: _waterLevel, totalCapacity: _tankCapacity),
                      0,
                    ),
                    const SizedBox(height: 16),
                    _buildAnimatedCard(
                      WaterQualityCard(isDark: isDark, tdsValue: _tdsValue),
                      1,
                    ),
                    const SizedBox(height: 16),
                    _buildAnimatedCard(ValveControlCard(isDark: isDark), 2),
                    const SizedBox(height: 16),
                    _buildAnimatedCard(_buildSystemAlerts(isDark), 3),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF334155).withOpacity(0.95)
            : const Color(0xFFFFFFFF).withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.water_drop, color: Color(0xFF4689C8), size: 28),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF4689C8), Color(0xFF5FC8D6)],
              ).createShader(bounds),
              child: const Text(
                'AquaWatch',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            _buildConnectionStatus(),
            const SizedBox(width: 12),
            _buildThemeToggle(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, bool isDark) {
    return IconButton(
      icon: Icon(
        isDark ? Icons.wb_sunny : Icons.nightlight_round,
        color: const Color(0xFF4689C8),
      ),
      onPressed: () {
        widget.onThemeChanged(isDark ? ThemeMode.light : ThemeMode.dark);
      },
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWifiConnected
              ? const [Color(0xFFDCFCE7), Color(0xFFBBF7D0)]
              : const [Color(0xFFFECACA), Color(0xFFFCA5A5)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: isWifiConnectedNotifier,
            builder: (context, isConnected, _) {
              return Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                size: 14,
                color: isConnected
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              );
            },
          ),
          const SizedBox(width: 4),
          ValueListenableBuilder(
            valueListenable: isWifiConnectedNotifier,
            builder: (context, value, _) {
              return Text(
                value ? "Connected" : "Not Connected",
                style: TextStyle(color: value ? Colors.green : Colors.red),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemAlerts(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        _buildAlertCard(
          'Tank Level: ${_waterLevel < 0.2 ? 'Low' : 'Good'}',
          'Your tank is ${(_waterLevel * 100).toInt()}% full',
          _waterLevel < 0.2 ? Icons.warning : Icons.check_circle,
          _waterLevel < 0.2 ? const Color(0xFFF59E0B) : const Color(0xFF16A34A),
          isDark,
        ),
        const SizedBox(height: 12),
        _buildAlertCard(
          'Water Quality: ${_tdsValue > 200 ? 'Poor' : 'Excellent'}',
          'TDS: ${_tdsValue.toInt()} ppm',
          _tdsValue > 200 ? Icons.warning : Icons.check_circle,
          _tdsValue > 200 ? const Color(0xFFF59E0B) : const Color(0xFF16A34A),
          isDark,
        ),
      ],
    );
  }

  Widget _buildAlertCard(
    String title,
    String message,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF475569).withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(Widget child, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  index * 0.1,
                  0.6 + index * 0.1,
                  curve: Curves.easeOutCubic,
                ),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index * 0.1,
              0.6 + index * 0.1,
              curve: Curves.easeOut,
            ),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class TankStatusCard extends StatefulWidget {
  final bool isDark;
  final double waterLevel; // Water level from 0.0 to 1.0
  final double totalCapacity; // Total tank capacity in liters

  const TankStatusCard({
    super.key,
    required this.isDark,
    required this.waterLevel,
    this.totalCapacity = 1000.0, // Default to 1000L if not provided
  });

  @override
  _TankStatusCardState createState() => _TankStatusCardState();
}

class _TankStatusCardState extends State<TankStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fillAnimation = Tween<double>(begin: 0.0, end: widget.waterLevel).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant TankStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.waterLevel != widget.waterLevel) {
      _fillAnimation =
          Tween<double>(
            begin: _fillAnimation.value,
            end: widget.waterLevel,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          );
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLiters = (widget.waterLevel * widget.totalCapacity).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tank Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: widget.isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: Color(0xFF16A34A)),
                  SizedBox(width: 4),
                  Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 280,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (_, __) => CustomPaint(
                    painter: WaterTankPainter(
                      fillPercentage: _fillAnimation.value,
                      bubbleOffset: _animationController.value,
                      isDarkMode:
                          Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
              ),
              // Percentage text overlay
              Positioned(
                child: Text(
                  '${(widget.waterLevel * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: widget.isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoRow(
          'Current Level:',
          '${currentLiters}L / ${widget.totalCapacity.toInt()}L',
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: widget.isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: widget.isDark
                ? const Color(0xFFF1F5F9)
                : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

class WaterQualityCard extends StatelessWidget {
  final bool isDark;
  final double tdsValue;

  const WaterQualityCard({
    super.key,
    required this.isDark,
    required this.tdsValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Water Quality',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tdsValue > 200 ? 'Poor' : 'Good',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: tdsValue > 200
                          ? Colors.orange
                          : const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildMetric(
          icon: Icons.remove_red_eye,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFDCFCE7),
          label: 'TDS',
          value: '${tdsValue.toInt()} ppm',
          status: tdsValue > 200 ? 'High' : 'Good',
          statusColor: tdsValue > 200 ? Colors.orange : const Color(0xFF16A34A),
          progress:
              tdsValue / 500.0, // Assuming max TDS is 500 for progress bar
        ),
      ],
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String status,
    required Color statusColor,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF475569).withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconBg, iconBg.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(22.5),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4689C8)),
            minHeight: 3,
          ),
        ],
      ),
    );
  }
}

enum ValveMode { auto, manual }

class ValveControlCard extends StatefulWidget {
  final bool isDark;

  const ValveControlCard({super.key, required this.isDark});

  @override
  _ValveControlCardState createState() => _ValveControlCardState();
}

class _ValveControlCardState extends State<ValveControlCard>
    with TickerProviderStateMixin {
  late AnimationController _flowController;
  ValveMode _currentMode = ValveMode.auto;
  bool _isManualValveOpen = false; // State for manual control

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    // Start animation if in auto mode or if manual valve is initially open
    if (_currentMode == ValveMode.auto || _isManualValveOpen) {
      _flowController.repeat();
    }
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  void _toggleManualValve(bool isOn) {
    setState(() {
      _isManualValveOpen = isOn;
      if (isOn) {
        _flowController.repeat();
      } else {
        _flowController.stop();
      }
    });
    // In a real app, send command to ESP32 here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Valve turned ${isOn ? "ON" : "OFF"} manually'),
        backgroundColor: isOn ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Valve Control',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: widget.isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _currentMode == ValveMode.auto
                        ? Icons.smart_toy
                        : Icons.handyman,
                    size: 14,
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _currentMode == ValveMode.auto ? 'Auto Mode' : 'Manual Mode',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              // Mode Toggle
              SegmentedButton<ValveMode>(
                segments: const <ButtonSegment<ValveMode>>[
                  ButtonSegment<ValveMode>(
                    value: ValveMode.auto,
                    label: Text('Auto'),
                    icon: Icon(Icons.auto_mode),
                  ),
                  ButtonSegment<ValveMode>(
                    value: ValveMode.manual,
                    label: Text('Manual'),
                    icon: Icon(Icons.tune),
                  ),
                ],
                selected: <ValveMode>{_currentMode},
                onSelectionChanged: (Set<ValveMode> newSelection) {
                  setState(() {
                    _currentMode = newSelection.first;
                    if (_currentMode == ValveMode.auto) {
                      _flowController.repeat(); // Assume auto mode means open
                    } else {
                      // In manual mode, stop animation if valve is off
                      if (!_isManualValveOpen) {
                        _flowController.stop();
                      } else {
                        _flowController.repeat(); // Keep animating if manually on
                      }
                    }
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: widget.isDark
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF4689C8),
                  selectedForegroundColor: Colors.white,
                  foregroundColor: widget.isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                  side: BorderSide(
                    color: widget.isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFD1D5DB),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                      ),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      size: 30,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  if (_currentMode == ValveMode.auto || _isManualValveOpen)
                    AnimatedBuilder(
                      animation: _flowController,
                      builder: (context, child) {
                        return Positioned(
                          top: 70,
                          child: SizedBox(
                            width: 4,
                            height: 30,
                            child: Column(
                              children: List.generate(3, (index) {
                                final delay = index * 0.3;
                                final animValue =
                                    (_flowController.value + delay) % 1.0;
                                return Expanded(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Transform.translate(
                                      offset: Offset(0, animValue * 30),
                                      child: Opacity(
                                        opacity: 1 - animValue,
                                        child: Container(
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF5FC8D6),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Inlet Valve',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentMode == ValveMode.auto
                    ? 'AUTO'
                    : (_isManualValveOpen ? 'OPEN' : 'CLOSED'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: (_currentMode == ValveMode.auto || _isManualValveOpen)
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 20),

              if (_currentMode == ValveMode.manual)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _toggleManualValve(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isManualValveOpen
                              ? const Color(0xFF16A34A)
                              : (widget.isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFE0E7FF)),
                          foregroundColor: _isManualValveOpen
                              ? Colors.white
                              : (widget.isDark
                                  ? Colors.white70
                                  : const Color(0xFF4689C8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('ON'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _toggleManualValve(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_isManualValveOpen
                              ? const Color(0xFFDC2626)
                              : (widget.isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFE0E7FF)),
                          foregroundColor: !_isManualValveOpen
                              ? Colors.white
                              : (widget.isDark
                                  ? Colors.white70
                                  : const Color(0xFFDC2626)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('OFF'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AnalyticsScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const AnalyticsScreen({super.key, required this.onThemeChanged});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF5F9FF),
                  Color(0xFFE6F0FA),
                ], // Matching login page
              ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildAnalyticsHeader(isDark),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAnimatedCard(_buildUsageChart(isDark), 0),
                    const SizedBox(height: 16),
                    _buildAnimatedCard(_buildStatsGrid(isDark), 1),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF334155).withOpacity(0.95)
            : const Color(0xFFFFFFFF).withOpacity(0.95),
        boxShadow: const [BoxShadow(color: Colors.black)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.analytics, color: Color(0xFF4689C8), size: 28),
            const SizedBox(width: 12),
            Text(
              'Analytics',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _downloadReport,
              icon: const Icon(Icons.download, color: Color(0xFF4689C8)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReport() async {
    try {
      // Show downloading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading report...'),
          backgroundColor: Color(0xFF4689C8),
        ),
      );

      // Simulate PDF download
      const url =
          'https://example.com/report.pdf'; // Replace with your API endpoint
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      // Get directory for download
      final directory = await getDownloadsDirectory();
      final filePath = '${directory?.path}/AquaWatch_Report.pdf';
      final file = File(filePath);

      // Write the file
      await file.writeAsBytes(bytes);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report downloaded successfully'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );

      // Open the file
      OpenFile.open(filePath);
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download report'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Widget _buildUsageChart(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Water Usage Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: CustomPaint(
            painter: ChartPainter(isDark: isDark),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildChartLegend('Current', const Color(0xFF4689C8), isDark),
            _buildChartLegend('Previous', const Color(0xFF94A3B8), isDark),
            _buildChartLegend('Average', const Color(0xFF5FC8D6), isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            value: '2.5h',
            label: 'Last Refill',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up,
            value: '85L',
            label: 'Daily Usage',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF475569).withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4F46E5),
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCard(Widget child, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  index * 0.1,
                  0.6 + index * 0.1,
                  curve: Curves.easeOutCubic,
                ),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index * 0.1,
              0.6 + index * 0.1,
              curve: Curves.easeOut,
            ),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  ThemeMode _selectedTheme = ThemeMode.system;
  bool notificationsEnabled = true;

  String _userName = 'Loading...';
  String _userEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
    _fetchUserData(); // Fetch user data when the screen initializes
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('users')
            .select('name, email')
            .eq('id', user.id)
            .single();

        setState(() {
          _userName = response['name'] ?? 'N/A';
          _userEmail = response['email'] ?? 'N/A';
        });
      } else {
        setState(() {
          _userName = 'Guest';
          _userEmail = 'Not logged in';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _userName = 'Error';
        _userEmail = 'Error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF5F9FF),
                  Color(0xFFE6F0FA),
                ], // Matching login page
              ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSettingsHeader(isDark),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAnimatedCard(_buildProfileSection(isDark), 0),
                    const SizedBox(height: 16),
                    _buildAnimatedCard(_buildAppearanceSection(isDark), 1),
                    const SizedBox(height: 16),
                    _buildAnimatedCard(_buildAboutSection(context, isDark), 2),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF334155).withOpacity(0.95)
            : const Color(0xFFFFFFFF).withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.settings, color: Color(0xFF4689C8), size: 28),
            const SizedBox(width: 12),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const HelpSupportScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
              icon: const Icon(Icons.help_outline, color: Color(0xFF4689C8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF4689C8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsButton('Account Settings', Icons.person_outline, () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const AccountSettingsScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ).then((_) {
            // Refresh user data when returning from Account Settings
            _fetchUserData();
          });
        }, isDark),
        _buildSettingsButton(
          'Privacy & Security',
          Icons.security,
          () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const PrivacySecurityScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          isDark,
        ),
        _buildSettingsButton('Logout', Icons.logout, () {
          _showLogoutConfirmationDialog();
        }, isDark),
      ],
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await supabase.auth.signOut(); // Sign out from Supabase
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        LoginScreen(onThemeChanged: widget.onThemeChanged),
                  ),
                  (route) => false,
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppearanceSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Theme',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildThemeOption(
                context,
                'Light',
                Icons.wb_sunny,
                ThemeMode.light,
                isDark,
              ),
            ),
            const SizedBox(width: 8), // Add spacing between options
            Expanded(
              child: _buildThemeOption(
                context,
                'Dark',
                Icons.nightlight_round,
                ThemeMode.dark,
                isDark,
              ),
            ),
            const SizedBox(width: 8), // Add spacing between options
            Expanded(
              child: _buildThemeOption(
                context,
                'System',
                Icons.settings,
                ThemeMode.system,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    IconData icon,
    ThemeMode mode,
    bool isDark,
  ) {
    final isSelected = _selectedTheme == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = mode;
        });
        widget.onThemeChanged(mode);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFF60A5FA).withOpacity(0.2)
                  : const Color(0xFF4689C8).withOpacity(0.2))
              : (isDark
                  ? const Color(0xFF475569).withOpacity(0.5)
                  : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF4689C8))
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF4689C8))
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF4689C8))
                    : (isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1F2937)),
              ),
              textAlign: TextAlign.center, // Center text for better fit
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsButton(
          'App Version',
          Icons.info_outline,
          () {},
          isDark,
          trailing: Text(
            'v1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
        ),
        _buildSettingsButton('Terms of Service', Icons.description, () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const TermsOfServiceScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }, isDark),
        _buildSettingsButton('Privacy Policy', Icons.privacy_tip, () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const PrivacyPolicyScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }, isDark),
      ],
    );
  }

  Widget _buildAnimatedCard(Widget child, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, _) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  index * 0.1,
                  0.6 + index * 0.1,
                  curve: Curves.easeOutCubic,
                ),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index * 0.1,
              0.6 + index * 0.1,
              curve: Curves.easeOut,
            ),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> showUpdateSuccess() async {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updated successfully'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFF1F5F9)
            : const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSecurityItem(context, 'Change Password', Icons.lock, () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const UpdatePasswordScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }, isDark),
            const Divider(),
            _buildSecurityItem(
              context,
              'Two-Factor Authentication',
              Icons.verified_user,
              () {},
              isDark,
            ),
            const Divider(),
            _buildSecurityItem(
              context,
              'Data Privacy',
              Icons.privacy_tip,
              () {},
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4689C8)),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

Widget _buildSettingsButton(
  String label,
  IconData icon,
  VoidCallback onTap,
  bool isDark, {
  Widget? trailing,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4689C8), size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          trailing ??
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? const Color.fromARGB(255, 27, 48, 77)
                    : const Color(0xFF6B7280),
                size: 20,
              ),
        ],
      ),
    )
    );
  }

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  String _currentUserName = 'Loading...';
  String _currentUserEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserDetails();
  }

  Future<void> _fetchCurrentUserDetails() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('users')
            .select('name, email')
            .eq('id', user.id)
            .single();
        setState(() {
          _currentUserName = response['name'] ?? 'N/A';
          _currentUserEmail = response['email'] ?? 'N/A';
        });
      } else {
        setState(() {
          _currentUserName = 'Guest';
          _currentUserEmail = 'Not logged in';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching current user details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading account details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _currentUserName = 'Error';
        _currentUserEmail = 'Error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFF1F5F9)
            : const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingItem(context, 'Update Password', Icons.lock, () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const UpdatePasswordScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }),
            const Divider(),
            _buildSettingItem(context, 'Change Name', Icons.person, () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ChangeNameScreen(
                    currentName: _currentUserName,
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              ).then((_) => _fetchCurrentUserDetails()); // Refresh after update
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4689C8)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmNewPasswordVisible = false;

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final newPassword = _newPasswordController.text;

        // Note: Supabase's updateUser method for password doesn't require the old password for security reasons
        // It uses the authenticated session. If you need to verify the current password,
        // you'd typically implement a separate backend function or re-authenticate the user.
        // For this example, we'll directly use updateUser.
        await supabase.auth.updateUser(
          UserAttributes(
            password: newPassword,
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error updating password: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update password: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Password'),
        backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFF1F5F9)
            : const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_isCurrentPasswordVisible,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isCurrentPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                    ),
                    onPressed: () {
                      setState(() {
                        _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  // In a real app, you would verify this against the backend
                  // For this example, we're skipping actual current password validation here
                  // as Supabase's updateUser doesn't take it as a parameter.
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_isNewPasswordVisible,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  if (!value.contains(RegExp(r'[A-Z]'))) {
                    return 'Password must contain uppercase letter';
                  }
                  if (!value.contains(RegExp(r'[a-z]'))) {
                    return 'Password must contain lowercase letter';
                  }
                  if (!value.contains(RegExp(r'[0-9]'))) {
                    return 'Password must contain number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmNewPasswordController,
                obscureText: !_isConfirmNewPasswordVisible,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmNewPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1791C8),
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmNewPasswordVisible =
                            !_isConfirmNewPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4689C8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangeNameScreen extends StatefulWidget {
  final String currentName;

  const ChangeNameScreen({super.key, required this.currentName});

  @override
  State<ChangeNameScreen> createState() => _ChangeNameScreenState();
}

class _ChangeNameScreenState extends State<ChangeNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newNameController.dispose();
    super.dispose();
  }

  Future<void> _changeName() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final newName = _newNameController.text.trim();
        final user = supabase.auth.currentUser;

        if (user != null) {
          await supabase.from('users').update({'name': newName}).eq('id', user.id);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Name updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        } else {
          throw Exception('User not logged in.');
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error changing name: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to change name: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Name'),
        backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFF1F5F9)
            : const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: widget.currentName,
                readOnly: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Current Name',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newNameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'New Name',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your new name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changeName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4689C8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Change Name'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFF1F5F9)
            : const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Terms of Service Content\n\n'
          '1. Introduction\n'
          'Welcome to AquaWatch. These Terms of Service govern your use of our application.\n\n'
          '2. User Responsibilities\n'
          'You agree to use the app only for lawful purposes and in accordance with these Terms.\n\n'
          '3. Intellectual Property\n'
          'The app and its original content are owned by AquaWatch and protected by copyright laws.\n\n'
          '4. Limitation of Liability\n'
          'AquaWatch shall not be liable for any indirect, incidental, special, or consequential damages.\n\n'
          '5. Changes to Terms\n'
          'We reserve the right to modify these terms at any time. Your continued use constitutes acceptance.',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFF1F5F9)
            : const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Privacy Policy Content\n\n'
          '1. Information We Collect\n'
          'We collect personal information you provide, such as name, email, and tank data.\n\n'
          '2. How We Use Information\n'
          'Your information is used to provide and improve our services, and communicate with you.\n\n'
          '3. Data Security\n'
          'We implement security measures to protect your data, but no method is 100% secure.\n\n'
          '4. Third-Party Services\n'
          'We may use third-party services that collect information to provide their services.\n\n'
          '5. Changes to This Policy\n'
          'We may update our Privacy Policy. We will notify you of any changes by posting the new policy.',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFF1F5F9)
            : const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHelpItem(context, 'FAQs', Icons.help_outline, () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const FAQScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }),
            const Divider(),
            _buildHelpItem(context, 'Contact Support', Icons.support_agent, () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const ContactSupportScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }),
            const Divider(),
            _buildHelpItem(context, 'User Guide', Icons.book, () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const UserGuideScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4689C8)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFF1F5F9)
            : const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFAQItem(
              'How do I set up my tank?',
              'Go to Tank Setup in the app and enter your tank dimensions and capacity.',
              isDark,
            ),
            const Divider(),
            _buildFAQItem(
              'How often is water quality checked?',
              'Water quality is monitored continuously and updated every 15 minutes.',
              isDark,
            ),
            const Divider(),
            _buildFAQItem(
              'Can I control the valve manually?',
              'Yes, you can switch to manual mode in the Valve Control section.',
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, bool isDark) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support'),
        backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFF1F5F9)
            : const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need Help? Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 20),
            _buildContactMethod(
              Icons.email,
              'Email Us',
              'support@aquawatch.com',
              isDark,
            ),
            const SizedBox(height: 16),
            _buildContactMethod(
              Icons.phone,
              'Call Us',
              '+1 (555) 123-4567',
              isDark,
            ),
            const SizedBox(height: 16),
            _buildContactMethod(
              Icons.chat,
              'Live Chat',
              'Available 9AM-5PM',
              isDark,
            ),
            const SizedBox(height: 32),
            Text(
              'Or send us a message:',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Your Message',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4689C8),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Send Message'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod(
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4689C8), size: 30),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ]
    );
  }
}

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Guide'),
        backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFF1F5F9)
            : const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Getting Started with AquaWatch',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 20),
            _buildGuideSection(
              '1. Setting Up Your Tank',
              'After creating an account, go to Tank Setup and enter your tank dimensions and capacity.',
              isDark,
            ),
            const SizedBox(height: 16),
            _buildGuideSection(
              '2. Monitoring Water Levels',
              'The dashboard shows real-time water levels and quality metrics.',
              isDark,
            ),
            const SizedBox(height: 16),
            _buildGuideSection(
              '3. Valve Control',
              'You can set the valve to automatic or manual mode in the Valve Control section.',
              isDark,
            ),
            const SizedBox(height: 16),
            _buildGuideSection(
              '4. Viewing Analytics',
              'The Analytics tab provides historical data and trends about your water usage.',
              isDark,
            ),
            const SizedBox(height: 16),
            _buildGuideSection(
              '5. Customizing Settings',
              'Go to Settings to adjust preferences, notifications, and account details.',
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection(String title, String content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class ChartPainter extends CustomPainter {
  final bool isDark;

  ChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    const padding = 20.0;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = isDark
          ? const Color(0xFF475569).withOpacity(0.5)
          : const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    for (int i = 1; i < 5; i++) {
      final y = height - (i * (height - padding * 2) / 4) - padding;
      canvas.drawLine(
        Offset(padding, y),
        Offset(width - padding, y),
        gridPaint,
      );
    }

    // Draw x-axis labels
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const textStyle = TextStyle(
      color: Color(
        0xFF6B7280,
      ), // Default for light mode, will be overridden by isDark
      fontSize: 10,
    );
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < days.length; i++) {
      final x = padding + i * (width - padding * 2) / (days.length - 1);
      textPainter.text = TextSpan(
        text: days[i],
        style: textStyle.copyWith(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, height - padding + 5),
      );
    }

    // Draw current data line
    const currentData = [65.0, 80.0, 75.0, 90.0, 85.0, 70.0, 95.0];
    _drawLine(
      canvas,
      currentData,
      const Color(0xFF4689C8),
      width,
      height,
      padding,
    );

    // Draw previous data line
    const previousData = [60.0, 70.0, 65.0, 75.0, 80.0, 65.0, 85.0];
    _drawLine(
      canvas,
      previousData,
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF),
      width,
      height,
      padding,
    );

    // Draw average data line
    const averageData = [62.0, 75.0, 70.0, 82.0, 78.0, 68.0, 90.0];
    _drawLine(
      canvas,
      averageData,
      const Color(0xFF5FC8D6),
      width,
      height,
      padding,
      isDashed: true,
    );
  }

  void _drawLine(
    Canvas canvas,
    List<double> data,
    Color color,
    double width,
    double height,
    double padding, {
    bool isDashed = false,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    const max = 100.0; // Maximum value in the chart

    for (int i = 0; i < data.length; i++) {
      final x = padding + i * (width - padding * 2) / (data.length - 1);
      final y = height - padding - (data[i] / max) * (height - padding * 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (isDashed) {
      final dashPath = Path();
      const dashWidth = 5.0;
      const dashSpace = 3.0;
      double distance = 0.0;
      final pathMetrics = path.computeMetrics();

      for (final pathMetric in pathMetrics) {
        while (distance < pathMetric.length) {
          final start = distance;
          final end = distance + dashWidth;
          if (end <= pathMetric.length) {
            dashPath.addPath(pathMetric.extractPath(start, end), Offset.zero);
          }
          distance = end + dashSpace;
        }
      }

      canvas.drawPath(dashPath, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = padding + i * (width - padding * 2) / (data.length - 1);
      final y = height - padding - (data[i] / max) * (height - padding * 2);

      canvas.drawCircle(Offset(x, y), 3, pointPaint);
      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    const waveHeight = 4.0;
    const waveLength =
        2.0; // Changed to a fixed value for simplicity, adjust as needed

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y =
          size.height / 2 +
          waveHeight *
              math.sin((x / waveLength * 2 * math.pi) + (0.5 * 2 * math.pi));
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BluetoothDevicePage extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  const BluetoothDevicePage({super.key, required this.onThemeChanged});

  @override
  State<BluetoothDevicePage> createState() => _BluetoothDevicePageState();
}

class _BluetoothDevicePageState extends State<BluetoothDevicePage> {
  List<ScanResult> scanResults = [];
  bool _isScanning = false;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    _startScan(); // Directly start scanning
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _isScanningSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _startScan() async {
    // Request permissions without checking status
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Start scanning directly
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          scanResults = results;
        });
      }
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (mounted) {
        setState(() {
          _isScanning = isScanning;
        });
      }
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // ignore: avoid_print
      print('🔗 Connecting to ${device.name}...');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connecting to ${device.name}...')),
      );

      await device.connect();
      // ignore: avoid_print
      print('✔️ Connected to ${device.name}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.name}'),
          backgroundColor: Colors.green,
        ),
      );

      List<BluetoothService> services = await device.discoverServices();

      final serviceUuid = Guid('12345678-1234-5678-1234-56789abcdef0');
      final charUuid = Guid('abcdefab-cdef-1234-5678-1234567890ab');

      BluetoothCharacteristic? targetChar;

      for (var service in services) {
        if (service.uuid == serviceUuid) {
          for (var char in service.characteristics) {
            if (char.uuid == charUuid) {
              targetChar = char;
              break;
            }
          }
        }
      }

      if (targetChar != null) {
        // ignore: avoid_print
        print('🎯 Characteristic found: ${targetChar.uuid}');
        // ignore: use_build_context_synchronously
        await showWifiCredentialsDialog(
          context,
          device,
          targetChar,
          widget.onThemeChanged,
        );
      } else {
        // ignore: avoid_print
        print('❌ Required BLE characteristic not found');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✖️ Required device not found."),
            backgroundColor: Colors.red,
          ),
        );
        await device.disconnect();
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error connecting to device: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Connection error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Exit the app when back is pressed
        SystemNavigator.pop(); // OR: import 'dart:io' and use exit(0);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Device'),
          backgroundColor: const Color(0xFF4689C8),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            if (_isScanning)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Scanning for devices...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueAccent,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ),
              )
            else if (scanResults.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No devices found. Tap "Scan" to retry.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  final device = scanResults[index].device;
                  return ListTile(
                    title: Text(
                      device.name.isNotEmpty ? device.name : 'Unknown Device',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(device.id.toString()),
                    trailing: const Icon(Icons.bluetooth),
                    onTap: () => connectToDevice(device),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isScanning ? null : _startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4689C8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showWifiCredentialsDialog(
  BuildContext context,
  BluetoothDevice device,
  BluetoothCharacteristic characteristic,
  Function(ThemeMode) onThemeChanged,
) async {
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();

  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Enter Wi-Fi Credentials'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ssidController,
            decoration: const InputDecoration(labelText: 'Wi-Fi SSID'),
          ),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Send'),
          onPressed: () async {
            final ssid = ssidController.text.trim();
            final password = passwordController.text.trim();
            final data = "$ssid|$password";

            try {
              await characteristic.write(data.codeUnits, withoutResponse: false);
              // ignore: avoid_print
              print('✅ Sent to ESP32: $data');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sending Wi-Fi credentials...')),
              );

              await characteristic.setNotifyValue(true);
              characteristic.value.listen((value) {
                final response = String.fromCharCodes(value);
                // ignore: avoid_print
                print("📩 Response from ESP32: $response");

                if (response == "WIFI_OK") {
                  isWifiConnectedNotifier.value = true;
                  Navigator.of(context).pop(); // Dismiss dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TankSetupScreen(onThemeChanged: onThemeChanged),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Wi-Fi connected!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (response == "WIFI_FAIL") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("❌ Wi-Fi failed!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            } catch (e) {
              // ignore: avoid_print
              print('Error sending Wi-Fi credentials: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error sending Wi-Fi credentials: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
    ),
  );
}

class WaterTankPainter extends CustomPainter {
  final double fillPercentage;
  final double bubbleOffset;
  final bool isDarkMode;

  WaterTankPainter({
    required this.fillPercentage,
    required this.bubbleOffset,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.9)
          : const Color(0xFF334155).withOpacity(0.9)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, 0.3),
        radius: 0.8,
        colors: [Colors.lightBlueAccent, Colors.blue], // Changed to Colors.blue
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final bubblePaint = Paint()..color = Colors.white.withOpacity(0.3);

    // Tank dimensions
    double topHeight = 40;
    double bottomHeight = 30;
    double wallStartY = topHeight / 2;
    double wallEndY = size.height - bottomHeight / 2;
    double tankHeight = wallEndY - wallStartY;

    // Water fill calculation
    final waterHeight = tankHeight * fillPercentage;
    final waterTopY = wallEndY - waterHeight;

    // Define tank shape (curved top + bottom)
    final topOval = Rect.fromLTWH(0, 5, size.width, 30);

    final bottomOval = Rect.fromLTWH(
      0,
      size.height - bottomHeight,
      size.width,
      bottomHeight,
    );

    Path tankPath = Path()
      ..moveTo(0, wallStartY)
      ..lineTo(0, wallEndY)
      ..arcTo(bottomOval, math.pi, -math.pi, false)
      ..lineTo(size.width, wallStartY)
      ..arcTo(topOval, 0, -math.pi, false)
      ..close();

    // Clip and draw water
    canvas.save();
    canvas.clipPath(tankPath);
    canvas.drawRect(
      Rect.fromLTRB(0, waterTopY, size.width, size.height - 1.5),
      fillPaint,
    );

    // Bubbles inside water
    final bubbleBaseY = wallEndY;
    final maxBubbleRise = waterHeight - 30;

    final bubbles = [
      Offset(size.width * 0.3, bubbleBaseY - (bubbleOffset * maxBubbleRise)),
      Offset(
        size.width * 0.5,
        bubbleBaseY - ((bubbleOffset + 0.3) % 1.0 * maxBubbleRise),
      ),
      Offset(
        size.width * 0.7,
        bubbleBaseY - ((bubbleOffset + 0.6) % 1.0 * maxBubbleRise),
      ),
      Offset(
        size.width * 0.4,
        bubbleBaseY - ((bubbleOffset + 0.8) % 1.0 * maxBubbleRise),
      ),
    ];
    const sizes = [5.0, 4.0, 6.0, 4.5];

    for (int i = 0; i < bubbles.length; i++) {
      if (bubbles[i].dy > waterTopY + 10) {
        canvas.drawCircle(bubbles[i], sizes[i], bubblePaint);
      }
    }

    canvas.restore();

    // Draw tank outline + top rim again
    canvas.drawPath(tankPath, borderPaint);
    canvas.drawOval(topOval, borderPaint); // Top rim
  }

  @override
  bool shouldRepaint(covariant WaterTankPainter oldDelegate) =>
      oldDelegate.fillPercentage != fillPercentage ||
      oldDelegate.bubbleOffset != bubbleOffset;
}

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String name;
  final Function(ThemeMode) onThemeChanged;

  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.name,
    required this.onThemeChanged,
  });

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;

  Future<void> verifyOtp() async {
    final otp = _otpController.text.trim();
    setState(() => _isVerifying = true);

    try {
      final sessionResponse = await supabase.auth.verifyOTP(
        type: OtpType.email,
        token: otp,
        email: widget.email,
      );

      final user = sessionResponse.user; // Use sessionResponse.user

      if (user != null) {
        // Now that OTP is verified, insert into custom users table
        await supabase.from('users').insert({
          'id': user.id,
          'name': widget.name,
          'email': widget.email,
          // esp_id will auto-generate if set as default gen_random_uuid()
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ OTP Verified!")));

        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BluetoothDevicePage(onThemeChanged: widget.onThemeChanged),
          ),
        );
      } else {
        // Handle case where user is null after OTP verification (e.g., invalid OTP)
        throw Exception("OTP verification failed: User is null.");
      }
    } catch (e) {
      // ignore: avoid_print
      print("❌ Error during OTP verification: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Invalid OTP: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Email")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Enter the OTP sent to ${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: "OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF4689C8),
                ),
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
