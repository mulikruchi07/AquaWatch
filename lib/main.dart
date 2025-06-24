import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:math';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

ValueNotifier<bool> isWifiConnectedNotifier = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isRegistered = prefs.getBool('isRegistered') ?? false;
  final isTankSetupDone = prefs.getBool('isTankSetupDone') ?? false;

  runApp(MyApp(
    isRegistered: isRegistered,
    isTankSetupDone: isTankSetupDone,
  ));
}

class MyApp extends StatelessWidget {
  final bool isRegistered;
  final bool isTankSetupDone;

  const MyApp({
    Key? key,
    required this.isRegistered,
    required this.isTankSetupDone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: !isRegistered
          ? InitialScreen(onThemeChanged: (mode) {}) // temp handler
          : !isTankSetupDone
              ? BluetoothDevicePage(onThemeChanged: (mode) {})
              : MainScreen(onThemeChanged: (mode) {}),
    );
  }
}

class AquaWatchApp extends StatefulWidget {
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
      primaryColor: Color(0xFF4689C8),
      scaffoldBackgroundColor: Color(0xFFF5F9FF), // Light blue background
      cardColor: Color(0xFFFFFFFF),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textTheme: TextTheme(titleLarge: TextStyle(color: Color(0xFF1F2937))),
      iconTheme: IconThemeData(color: Color(0xFF4689C8)),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF60A5FA),
      scaffoldBackgroundColor: Color(0xFF1E293B),
      cardColor: Color(0xFF334155),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF334155),
        foregroundColor: Color(0xFFF1F5F9),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      textTheme: TextTheme(titleLarge: TextStyle(color: Color(0xFFF1F5F9))),
      iconTheme: IconThemeData(color: Color(0xFF60A5FA)),
    );
  }
}

class InitialScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const InitialScreen({Key? key, required this.onThemeChanged})
    : super(key: key);

  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              LoginScreen(onThemeChanged: widget.onThemeChanged),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.water_drop,
                  size: 60,
                  color: Color(0xFF4689C8),
                ),
              ),
              SizedBox(height: 20),
              Text(
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

  const LoginScreen({Key? key, required this.onThemeChanged}) : super(key: key);

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
      duration: Duration(milliseconds: 1000),
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

      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MainScreen(onThemeChanged: widget.onThemeChanged),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F9FF), Color(0xFFE6F0FA)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(height: 40),
                  _buildHeader(),
                  SizedBox(height: 40), // Reduced from 60
                  _buildLoginForm(),
                  SizedBox(height: 20), // Reduced from 30
                  _buildSignUpPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideAnimation =
            Tween<Offset>(begin: Offset(0, -0.5), end: Offset.zero).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.0, 0.6, curve: Curves.easeOutCubic),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.0, 0.6, curve: Curves.easeOut),
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
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.water_drop,
                    size: 40,
                    color: Color(0xFF4689C8),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Login to your account',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // In _buildLoginForm(), replace with this corrected version:
  Widget _buildLoginForm() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideAnimation =
            Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.3, 1.0, curve: Curves.easeOutCubic),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.3, 1.0, curve: Curves.easeOut),
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
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(Icons.person, color: Color(0xFF1791C8)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(Icons.lock, color: Color(0xFF1791C8)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Color(0xFF1791C8),
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
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: Color(0xFF1791C8)),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1791C8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
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

  Widget _buildSignUpPrompt() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.8, 1.0, curve: Curves.easeOut),
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(color: Color(0xFF6B7280)),
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
                                begin: Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            );
                          },
                      transitionDuration: Duration(milliseconds: 300),
                    ),
                  );
                },
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Color(0xFF1791C8),
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

  const RegisterScreen({Key? key, required this.onThemeChanged})
    : super(key: key);

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
      duration: Duration(milliseconds: 1000),
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
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              OtpVerificationPage(email: _emailController.text, onThemeChanged: widget.onThemeChanged),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 300),
        ),
      );
    } else if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _launchTerms() async {
    const url = 'https://example.com/terms';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F9FF), Color(0xFFE6F0FA)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  _buildHeader(),
                  SizedBox(height: 30),
                  _buildRegisterForm(),
                  SizedBox(height: 20),
                  _buildSignInPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideAnimation =
            Tween<Offset>(begin: Offset(0, -0.5), end: Offset.zero).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.0, 0.6, curve: Curves.easeOutCubic),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.0, 0.6, curve: Curves.easeOut),
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
                      icon: Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                    ),
                    Spacer(),
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
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.water_drop,
                    size: 40,
                    color: Color(0xFF4689C8),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create our account',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // In _buildRegisterForm(), replace with this corrected version:
  Widget _buildRegisterForm() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideAnimation =
            Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.3, 1.0, curve: Curves.easeOutCubic),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.3, 1.0, curve: Curves.easeOut),
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
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(Icons.person, color: Color(0xFF1791C8)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(Icons.email, color: Color(0xFF1791C8)),
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
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(Icons.lock, color: Color(0xFF1791C8)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Color(0xFF1791C8),
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
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Icon(Icons.lock, color: Color(0xFF1791C8)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Color(0xFF1791C8),
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
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value!;
                          });
                        },
                        activeColor: Color(0xFF1791C8),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _launchTerms,
                          child: Text(
                            'I agree to the Terms and Conditions',
                            style: TextStyle(
                              color: Color(0xFF1791C8),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1791C8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
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

  Widget _buildSignInPrompt() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.8, 1.0, curve: Curves.easeOut),
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account? ",
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: Color(0xFF1791C8),
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

  const TankSetupScreen({Key? key, required this.onThemeChanged,})
    : super(key: key);

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
      duration: Duration(milliseconds: 1000),
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
      await Future.delayed(Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isTankSetupDone', true);
      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MainScreen(onThemeChanged: widget.onThemeChanged),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
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
                ? [Color(0xFF1E293B), Color(0xFF334155)]
                : [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  _buildHeader(),
                  SizedBox(height: 40),
                  _buildTankForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideAnimation =
            Tween<Offset>(begin: Offset(0, -0.5), end: Offset.zero).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.0, 0.6, curve: Curves.easeOutCubic),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.0, 0.6, curve: Curves.easeOut),
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
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.water_drop,
                    size: 40,
                    color: Color(0xFF4689C8),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Tank Setup',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Configure your water tank details',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTankForm() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final slideAnimation =
            Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.3, 1.0, curve: Curves.easeOutCubic),
              ),
            );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildHeightField(),
                    SizedBox(height: 20),
                    _buildCapacityField(),
                    SizedBox(height: 30),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeightField() {
    return TextFormField(
      controller: _heightController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Tank Height (cm)',
        prefixIcon: Icon(Icons.height),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF475569).withOpacity(0.3)
            : Color(0xFFF8FAFC),
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

  Widget _buildCapacityField() {
    return TextFormField(
      controller: _capacityController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Tank Capacity (L)',
        prefixIcon: Icon(Icons.water_drop),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF475569).withOpacity(0.3)
            : Color(0xFFF8FAFC),
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitTankDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4689C8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Save & Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const MainScreen({Key? key, required this.onThemeChanged}) : super(key: key);

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
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                ? Color(0xFF334155).withOpacity(0.95)
                : Color(0xFFFFFFFF).withOpacity(0.95),
            selectedItemColor: Color(0xFF4689C8),
            unselectedItemColor: isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
            items: [
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

  const DashboardScreen({Key? key, required this.onThemeChanged})
    : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  ThemeMode currentTheme = ThemeMode.system;
  bool isDarkMode = false;

  bool isWifiConnected = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
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
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
              )
            : LinearGradient(
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
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAnimatedCard(TankStatusCard(isDark: isDark), 0),
                    SizedBox(height: 16),
                    _buildAnimatedCard(WaterQualityCard(isDark: isDark), 1),
                    SizedBox(height: 16),
                    _buildAnimatedCard(ValveControlCard(isDark: isDark), 2),
                    SizedBox(height: 16),
                    _buildAnimatedCard(_buildSystemAlerts(), 3),
                    SizedBox(height: 100),
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
            ? Color(0xFF334155).withOpacity(0.95)
            : Color(0xFFFFFFFF).withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.water_drop, color: Color(0xFF4689C8), size: 28),
            SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Color(0xFF4689C8), Color(0xFF5FC8D6)],
              ).createShader(bounds),
              child: Text(
                'AquaWatch',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Spacer(),
            _buildConnectionStatus(),
            SizedBox(width: 12),
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
        color: Color(0xFF4689C8),
      ),
      onPressed: () {
        widget.onThemeChanged(isDark ? ThemeMode.light : ThemeMode.dark);
      },
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWifiConnected
              ? [Color(0xFFDCFCE7), Color(0xFFBBF7D0)]
              : [Color(0xFFFECACA), Color(0xFFFCA5A5)],
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
                color: isConnected ? Color(0xFF16A34A) : Color(0xFFDC2626),
              );
            },
          ),
          SizedBox(width: 4),
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

  Widget _buildSystemAlerts() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 16),
        _buildAlertCard(
          'Tank Level: Good',
          'Your tank is 75% full',
          Icons.check_circle,
          Color(0xFF16A34A),
          isDark,
        ),
        SizedBox(height: 12),
        _buildAlertCard(
          'Water Quality: Excellent',
          'All parameters within normal range',
          Icons.check_circle,
          Color(0xFF16A34A),
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF475569).withOpacity(0.5) : Color(0xFFF8FAFC),
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
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
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
            Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(
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
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
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

  const TankStatusCard({Key? key, required this.isDark}) : super(key: key);

  @override
  _TankStatusCardState createState() => _TankStatusCardState();
}

class _TankStatusCardState extends State<TankStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fillAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _fillAnimation = Tween<double>(begin: 0.0, end: 0.75).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
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
                color: widget.isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
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
        SizedBox(height: 24),
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
                      isDarkMode: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
              ),
              // Percentage text overlay
              Positioned(
                child: Text(
                  '${(_fillAnimation.value * 100).toInt()}%',
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

        SizedBox(height: 24),
        _buildInfoRow('Current Level:', '750L / 1000L'),
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
            color: widget.isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: widget.isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

class WaterQualityCard extends StatelessWidget {
  final bool isDark;

  const WaterQualityCard({Key? key, required this.isDark}) : super(key: key);

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
                color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                  SizedBox(width: 4),
                  Text(
                    'Good',
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
        SizedBox(height: 20),
        _buildMetric(
          icon: Icons.remove_red_eye,
          iconColor: Color(0xFF16A34A),
          iconBg: Color(0xFFDCFCE7),
          label: 'TDS',
          value: '150 ppm',
          status: 'Good',
          statusColor: Color(0xFF16A34A),
          progress: 0.3,
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF475569).withOpacity(0.5) : Color(0xFFF8FAFC),
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
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? Color(0xFF334155) : Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4689C8)),
            minHeight: 3,
          ),
        ],
      ),
    );
  }
}

class ValveControlCard extends StatefulWidget {
  final bool isDark;

  const ValveControlCard({Key? key, required this.isDark}) : super(key: key);

  @override
  _ValveControlCardState createState() => _ValveControlCardState();
}

class _ValveControlCardState extends State<ValveControlCard>
    with TickerProviderStateMixin {
  late AnimationController _flowController;
  bool isValveOpen = true;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    if (isValveOpen) {
      _flowController.repeat();
    }
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
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
                color: widget.isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.smart_toy, size: 14, color: Color(0xFF16A34A)),
                  SizedBox(width: 4),
                  Text(
                    'Auto Mode',
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
        SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                      ),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Icon(
                      Icons.water_drop,
                      size: 30,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  if (isValveOpen)
                    AnimatedBuilder(
                      animation: _flowController,
                      builder: (context, child) {
                        return Positioned(
                          top: 70,
                          child: Container(
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
                                            color: Color(0xFF5FC8D6),
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
              SizedBox(height: 16),
              Text(
                'Inlet Valve',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 4),
              Text(
                isValveOpen ? 'OPEN' : 'CLOSED',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isValveOpen ? Color(0xFF16A34A) : Color(0xFFDC2626),
                ),
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

  const AnalyticsScreen({Key? key, required this.onThemeChanged})
    : super(key: key);

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
      duration: Duration(milliseconds: 1000),
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
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
              )
            : LinearGradient(
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
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAnimatedCard(_buildUsageChart(isDark), 0),
                    SizedBox(height: 16),
                    _buildAnimatedCard(_buildStatsGrid(isDark), 1),
                    SizedBox(height: 100),
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
            ? Color(0xFF334155).withOpacity(0.95)
            : Color(0xFFFFFFFF).withOpacity(0.95),
        boxShadow: [BoxShadow(color: Colors.black)],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.analytics, color: Color(0xFF4689C8), size: 28),
            SizedBox(width: 12),
            Text(
              'Analytics',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
              ),
            ),
            Spacer(),
            IconButton(
              onPressed: _downloadReport,
              icon: Icon(Icons.download, color: Color(0xFF4689C8)),
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
        SnackBar(
          content: Text('Downloading report...'),
          backgroundColor: Color(0xFF4689C8),
        ),
      );

      // Simulate PDF download
      final url =
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
        SnackBar(
          content: Text('Report downloaded successfully'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );

      // Open the file
      OpenFile.open(filePath);
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
            color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 20),
        Container(
          height: 200,
          child: CustomPaint(
            painter: ChartPainter(isDark: isDark),
            size: Size.infinite,
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildChartLegend('Current', Color(0xFF4689C8), isDark),
            _buildChartLegend('Previous', Color(0xFF94A3B8), isDark),
            _buildChartLegend('Average', Color(0xFF5FC8D6), isDark),
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
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up,
            value: '85L',
            label: 'Daily Usage',
            isDark: isDark,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.thermostat,
            value: '22°C',
            label: 'Temperature',
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF475569).withOpacity(0.5) : Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Color(0xFF4F46E5), size: 18),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
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
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
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
            Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(
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
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
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

  const SettingsScreen({Key? key, required this.onThemeChanged})
    : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  ThemeMode _selectedTheme = ThemeMode.system;
  bool notificationsEnabled = true;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateLanguagePreference(String language) async {
    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language updated to $language'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update language'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
              )
            : LinearGradient(
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
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAnimatedCard(_buildProfileSection(isDark), 0),
                    SizedBox(height: 16),
                    _buildAnimatedCard(_buildAppearanceSection(isDark), 1),
                    SizedBox(height: 16),
                    _buildAnimatedCard(_buildPreferencesSection(isDark), 2),
                    SizedBox(height: 16),
                    _buildAnimatedCard(_buildAboutSection(context, isDark), 3),
                    SizedBox(height: 100),
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
            ? Color(0xFF334155).withOpacity(0.95)
            : Color(0xFFFFFFFF).withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.settings, color: Color(0xFF4689C8), size: 28),
            SizedBox(width: 12),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
              ),
            ),
            Spacer(),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpSupportScreen()),
                );
              },
              icon: Icon(Icons.help_outline, color: Color(0xFF4689C8)),
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
            color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(0xFF4689C8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  'JD',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Doe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'john.doe@example.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            Spacer(),
          ],
        ),
        SizedBox(height: 16),
        _buildSettingsButton('Account Settings', Icons.person_outline, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AccountSettingsScreen()),
          );
        }, isDark),
        _buildSettingsButton(
          'Privacy & Security',
          Icons.security,
          () {},
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
          title: Text('Logout Confirmation'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        LoginScreen(onThemeChanged: widget.onThemeChanged),
                  ),
                  (route) => false,
                );
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
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
            color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Theme',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildThemeOption(
              context,
              'Light',
              Icons.wb_sunny,
              ThemeMode.light,
              isDark,
            ),
            _buildThemeOption(
              context,
              'Dark',
              Icons.nightlight_round,
              ThemeMode.dark,
              isDark,
            ),
            _buildThemeOption(
              context,
              'System',
              Icons.settings,
              ThemeMode.system,
              isDark,
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
        width: 100,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF4689C8).withOpacity(0.2)
              : isDark
              ? Color(0xFF475569).withOpacity(0.5)
              : Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF4689C8) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Color(0xFF4689C8)
                  : (isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280)),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Color(0xFF4689C8)
                    : (isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferences',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 16),
        _buildDropdownSetting(
          'Language',
          _selectedLanguage,
          ['English', 'Hindi', 'Marathi'],
          (value) {
            setState(() {
              _selectedLanguage = value!;
            });
            // Call API to update language preference
            _updateLanguagePreference(value!);
          },
          isDark,
        ),
      ],
    );
  }

  Widget _buildAnimatedCard(Widget child, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, _) {
        final slideAnimation =
            Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(
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
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
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
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> _showUpdateSuccess() async {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated successfully'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy & Security'),
        backgroundColor: isDark ? Color(0xFF334155) : Colors.white,
        foregroundColor: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSecurityItem(context, 'Change Password', Icons.lock, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdatePasswordScreen()),
              );
            }, isDark),
            Divider(),
            _buildSecurityItem(
              context,
              'Two-Factor Authentication',
              Icons.verified_user,
              () {},
              isDark,
            ),
            Divider(),
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
      leading: Icon(icon, color: Color(0xFF4689C8)),
      title: Text(
        title,
        style: TextStyle(color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937)),
      ),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
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
          color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
        ),
      ),
      SizedBox(height: 16),
      _buildSettingsButton(
        'App Version',
        Icons.info_outline,
        () {},
        isDark,
        trailing: Text(
          'v1.0.0',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
          ),
        ),
      ),
      _buildSettingsButton('Terms of Service', Icons.description, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TermsOfServiceScreen()),
        );
      }, isDark),
      _buildSettingsButton('Privacy Policy', Icons.privacy_tip, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
        );
      }, isDark),
    ],
  );
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
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF4689C8), size: 20),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
            ),
          ),
          Spacer(),
          trailing ??
              Icon(
                Icons.chevron_right,
                color: isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
                size: 20,
              ),
        ],
      ),
    ),
  );
}

Widget _buildDropdownSetting(
  String label,
  String value,
  List<String> options,
  ValueChanged<String?> onChanged,
  bool isDark,
) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
          ),
        ),
        Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Color(0xFF475569).withOpacity(0.5)
                : Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            underline: SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: Color(0xFF4689C8)),
            dropdownColor: isDark ? Color(0xFF334155) : Colors.white,
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

class AccountSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Account Settings'),
        backgroundColor: isDark ? Color(0xFF334155) : Colors.white,
        foregroundColor: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingItem(context, 'Update Password', Icons.lock, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdatePasswordScreen()),
              );
            }),
            Divider(),
            _buildSettingItem(context, 'Change Email', Icons.email, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangeEmailScreen()),
              );
            }),
            Divider(),
            _buildSettingItem(context, 'Change Name', Icons.person, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangeNameScreen()),
              );
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
      leading: Icon(icon, color: Color(0xFF4689C8)),
      title: Text(title),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class UpdatePasswordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Update Password'),
        backgroundColor: isDark ? Color(0xFF334155) : Colors.white,
        foregroundColor: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: Text('Update Password'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4689C8),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangeEmailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Change Email'),
        backgroundColor: isDark ? Color(0xFF334155) : Colors.white,
        foregroundColor: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Current Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'New Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: Text('Change Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4689C8),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangeNameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Change Name'),
        backgroundColor: isDark ? Color(0xFF334155) : Colors.white,
        foregroundColor: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Current Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'New Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: Text('Change Name'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4689C8),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Terms of Service'),
        backgroundColor: isDark ? Color(0xFF334155) : Colors.white,
        foregroundColor: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
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
            color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
        backgroundColor: isDark ? Color(0xFF334155) : Colors.white,
        foregroundColor: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
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
            color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
        backgroundColor: isDark ? Color(0xFF334155) : Colors.white,
        foregroundColor: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHelpItem(context, 'FAQs', Icons.help_outline, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FAQScreen()),
              );
            }),
            Divider(),
            _buildHelpItem(context, 'Contact Support', Icons.support_agent, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactSupportScreen()),
              );
            }),
            Divider(),
            _buildHelpItem(context, 'User Guide', Icons.book, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserGuideScreen()),
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
      leading: Icon(icon, color: Color(0xFF4689C8)),
      title: Text(title),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class FAQScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('FAQs'),
        backgroundColor: isDark ? Color(0xFF334155) : Colors.white,
        foregroundColor: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFAQItem(
              'How do I set up my tank?',
              'Go to Tank Setup in the app and enter your tank dimensions and capacity.',
              isDark,
            ),
            Divider(),
            _buildFAQItem(
              'How often is water quality checked?',
              'Water quality is monitored continuously and updated every 15 minutes.',
              isDark,
            ),
            Divider(),
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
          color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            answer,
            style: TextStyle(
              color: isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}

class ContactSupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Support'),
        backgroundColor: isDark ? Color(0xFF334155) : Colors.white,
        foregroundColor: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need Help? Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 20),
            _buildContactMethod(
              Icons.email,
              'Email Us',
              'support@aquawatch.com',
              isDark,
            ),
            SizedBox(height: 16),
            _buildContactMethod(
              Icons.phone,
              'Call Us',
              '+1 (555) 123-4567',
              isDark,
            ),
            SizedBox(height: 16),
            _buildContactMethod(
              Icons.chat,
              'Live Chat',
              'Available 9AM-5PM',
              isDark,
            ),
            SizedBox(height: 32),
            Text(
              'Or send us a message:',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Your Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: Text('Send Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4689C8),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
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
        Icon(icon, color: Color(0xFF4689C8), size: 30),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class UserGuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('User Guide'),
        backgroundColor: isDark ? Color(0xFF334155) : Colors.white,
        foregroundColor: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Getting Started with AquaWatch',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 20),
            _buildGuideSection(
              '1. Setting Up Your Tank',
              'After creating an account, go to Tank Setup and enter your tank dimensions and capacity.',
              isDark,
            ),
            SizedBox(height: 16),
            _buildGuideSection(
              '2. Monitoring Water Levels',
              'The dashboard shows real-time water levels and quality metrics.',
              isDark,
            ),
            SizedBox(height: 16),
            _buildGuideSection(
              '3. Valve Control',
              'You can set the valve to automatic or manual mode in the Valve Control section.',
              isDark,
            ),
            SizedBox(height: 16),
            _buildGuideSection(
              '4. Viewing Analytics',
              'The Analytics tab provides historical data and trends about your water usage.',
              isDark,
            ),
            SizedBox(height: 16),
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
            color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
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
    final padding = 20.0;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = isDark ? Color(0xFF475569).withOpacity(0.5) : Color(0xFFE5E7EB)
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
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final textStyle = TextStyle(
      color: isDark ? Color(0xFF94A3B8) : Color(0xFF6B7280),
      fontSize: 10,
    );
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < days.length; i++) {
      final x = padding + i * (width - padding * 2) / (days.length - 1);
      textPainter.text = TextSpan(text: days[i], style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, height - padding + 5),
      );
    }

    // Draw current data line
    final currentData = [65.0, 80.0, 75.0, 90.0, 85.0, 70.0, 95.0];
    _drawLine(canvas, currentData, Color(0xFF4689C8), width, height, padding);

    // Draw previous data line
    final previousData = [60.0, 70.0, 65.0, 75.0, 80.0, 65.0, 85.0];
    _drawLine(
      canvas,
      previousData,
      isDark ? Color(0xFF94A3B8) : Color(0xFF9CA3AF),
      width,
      height,
      padding,
    );

    // Draw average data line
    final averageData = [62.0, 75.0, 70.0, 82.0, 78.0, 68.0, 90.0];
    _drawLine(
      canvas,
      averageData,
      Color(0xFF5FC8D6),
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
    final max = 100.0; // Maximum value in the chart

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
      final dashWidth = 5.0;
      final dashSpace = 3.0;
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
    final waveHeight = 4.0;
    final waveLength = size.width / 2;

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

  @override
  void initState() {
    super.initState();
    requestPermissionsAndScan();
  }

  Future<void> requestPermissionsAndScan() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      print('🔗 Connecting to ${device.name}...');
      await device.connect();
      print('✔️ Connected to ${device.name}');

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
        print('🎯 Characteristic found: ${targetChar.uuid}');
        await showWifiCredentialsDialog(context, device, targetChar, widget.onThemeChanged);
      } else {
        print('❌ Required BLE characteristic not found');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✖️ Required device not found."),
            backgroundColor: Colors.red,
          ),
        );
        await device.disconnect();
      }
    } catch (e) {
      print('❌ Error: $e');
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
      body: scanResults.isEmpty
          ? const Center(child: Text('🔍 Scanning for devices...'))
          : ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final device = scanResults[index].device;
                return ListTile(
                  title: Text(
                    device.name.isNotEmpty ? device.name : 'Unknown Device',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(device.id.toString()),
                  trailing: const Icon(Icons.bluetooth),
                  onTap: () => connectToDevice(device),
                );
              },
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
      title: Text('Enter Wi-Fi Credentials'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ssidController,
            decoration: InputDecoration(labelText: 'Wi-Fi SSID'),
          ),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Send'),
          onPressed: () async {
            final ssid = ssidController.text.trim();
            final password = passwordController.text.trim();
            final data = "$ssid|$password";

            await characteristic.write(data.codeUnits, withoutResponse: false);
            print('✅ Sent to ESP32: $data');

            await characteristic.setNotifyValue(true);
            characteristic.value.listen((value) {
              final response = String.fromCharCodes(value);
              print("📩 Response from ESP32: $response");

              if (response == "WIFI_OK") {
                isWifiConnectedNotifier.value = true;
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TankSetupScreen(onThemeChanged: onThemeChanged),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("✅ Wi-Fi connected!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (response == "WIFI_FAIL") {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("❌ Wi-Fi failed!"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
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

  WaterTankPainter({required this.fillPercentage, required this.bubbleOffset, required this.isDarkMode,});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = isDarkMode
      ? Colors.white.withOpacity(0.9)
      : const Color(0xFF334155).withOpacity(0.9)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.3),
        radius: 0.8,
        colors: [Colors.lightBlueAccent, Colors.blue.shade300],
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
      ..arcTo(bottomOval, pi, -pi, false)
      ..lineTo(size.width, wallStartY)
      ..arcTo(topOval, 0, -pi, false)
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
    final sizes = [5.0, 4.0, 6.0, 4.5];

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
  final String email; // if you want to pass email for verification
  final Function(ThemeMode) onThemeChanged;
  const OtpVerificationPage({super.key, required this.email, required this.onThemeChanged,});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;

  Future<void> verifyOtp() async {
    setState(() => _isVerifying = true);

    final enteredOtp = _otpController.text.trim();

    // Simulated OTP check — replace this with actual API call
    await Future.delayed(const Duration(seconds: 1));

    if (enteredOtp == "123456") {

      final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isRegistered', true);

      // ✅ OTP matched, go to Bluetooth page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BluetoothDevicePage(onThemeChanged: widget.onThemeChanged)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Invalid OTP"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isVerifying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
        backgroundColor: const Color(0xFF4689C8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter the 6-digit OTP sent to your email",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: "OTP",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4689C8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Verify",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
