import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

void main() {
  runApp(AquaWatchApp());
}

class AquaWatchApp extends StatefulWidget {
  @override
  _AquaWatchAppState createState() => _AquaWatchAppState();
}

class _AquaWatchAppState extends State<AquaWatchApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaWatch',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _themeMode,
      home: InitialSplashScreen(onThemeChanged: _changeTheme),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: MaterialColor(0xFF4689C8, {
        50: Color(0xFFE3F2FD),
        100: Color(0xFFBBDEFB),
        200: Color(0xFF90CAF9),
        300: Color(0xFF64B5F6),
        400: Color(0xFF42A5F5),
        500: Color(0xFF4689C8),
        600: Color(0xFF1E88E5),
        700: Color(0xFF1976D2),
        800: Color(0xFF1565C0),
        900: Color(0xFF0D47A1),
      }),
      scaffoldBackgroundColor: Color(0xFFF5F9FF),
      cardColor: Color(0xFFFFFFFF),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF).withOpacity(0.95),
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: MaterialColor(0xFF60A5FA, {
        50: Color(0xFFEFF6FF),
        100: Color(0xFFDBEAFE),
        200: Color(0xFFBFDBFE),
        300: Color(0xFF93C5FD),
        400: Color(0xFF60A5FA),
        500: Color(0xFF3B82F6),
        600: Color(0xFF2563EB),
        700: Color(0xFF1D4ED8),
        800: Color(0xFF1E40AF),
        900: Color(0xFF1E3A8A),
      }),
      scaffoldBackgroundColor: Color(0xFF1E293B),
      cardColor: Color(0xFF334155),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF334155).withOpacity(0.95),
        foregroundColor: Color(0xFFF1F5F9),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
    );
  }
}

class InitialSplashScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const InitialSplashScreen({Key? key, required this.onThemeChanged})
    : super(key: key);

  @override
  _InitialSplashScreenState createState() => _InitialSplashScreenState();
}

class _InitialSplashScreenState extends State<InitialSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    _logoController.forward();

    await Future.delayed(Duration(seconds: 3));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SplashScreen(onThemeChanged: widget.onThemeChanged),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
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
          child: AnimatedBuilder(
            animation: _logoAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _logoAnimation.value,
                child: Container(
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
              );
            },
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const SplashScreen({Key? key, required this.onThemeChanged})
    : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _dotsController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _dotsController = AnimationController(
      duration: Duration(milliseconds: 1400),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    _logoController.forward();
    await Future.delayed(Duration(milliseconds: 500));
    _dotsController.repeat();

    await Future.delayed(Duration(seconds: 3));

    if (mounted) {
      bool isLoggedIn = await _checkLoginStatus();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => isLoggedIn
              ? MainScreen(onThemeChanged: widget.onThemeChanged)
              : LoginScreen(onThemeChanged: widget.onThemeChanged),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<bool> _checkLoginStatus() async {
    await Future.delayed(Duration(milliseconds: 500));
    return false;
  }

  @override
  void dispose() {
    _logoController.dispose();
    _dotsController.dispose();
    super.dispose();
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
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, -10 * (1 - _logoAnimation.value)),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
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
                    ),
                  );
                },
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
              SizedBox(height: 40),
              AnimatedBuilder(
                animation: _dotsController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            ((_dotsController.value + index * 0.3) % 1.0).clamp(
                              0.3,
                              1.0,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  );
                },
              ),
              SizedBox(height: 40),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) =>
                          LoginScreen(onThemeChanged: widget.onThemeChanged),
                    ),
                  );
                },
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
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
                  SizedBox(height: 40),
                  _buildHeader(),
                  SizedBox(height: 60),
                  _buildLoginForm(),
                  SizedBox(height: 30),
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
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sign in to your AquaWatch account',
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
                    _buildEmailField(),
                    SizedBox(height: 20),
                    _buildPasswordField(),
                    SizedBox(height: 30),
                    _buildLoginButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF475569).withOpacity(0.3)
            : Color(0xFFF8FAFC),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF475569).withOpacity(0.3)
            : Color(0xFFF8FAFC),
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
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
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
                'Sign In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
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
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
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
                    color: Colors.white,
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
              TankSetupScreen(onThemeChanged: widget.onThemeChanged),
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
                  _buildRegisterForm(),
                  SizedBox(height: 30),
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
                      icon: Icon(Icons.arrow_back, color: Colors.white),
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
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Join AquaWatch and start monitoring',
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
                    _buildNameField(),
                    SizedBox(height: 20),
                    _buildEmailField(),
                    SizedBox(height: 20),
                    _buildPasswordField(),
                    SizedBox(height: 20),
                    _buildConfirmPasswordField(),
                    SizedBox(height: 16),
                    _buildTermsCheckbox(),
                    SizedBox(height: 30),
                    _buildRegisterButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Full Name',
        prefixIcon: Icon(Icons.person_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF475569).withOpacity(0.3)
            : Color(0xFFF8FAFC),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your full name';
        }
        if (value.length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF475569).withOpacity(0.3)
            : Color(0xFFF8FAFC),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF475569).withOpacity(0.3)
            : Color(0xFFF8FAFC),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
          return 'Password must contain uppercase, lowercase and number';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        prefixIcon: Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF475569).withOpacity(0.3)
            : Color(0xFFF8FAFC),
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
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value ?? false;
            });
          },
          activeColor: Color(0xFF4689C8),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
              children: [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: Color(0xFF4689C8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: Color(0xFF4689C8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
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
                'Create Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
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
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
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

  const TankSetupScreen({Key? key, required this.onThemeChanged})
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back, color: Colors.white),
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
  ThemeMode _currentTheme = ThemeMode.system;

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
  ThemeMode _currentTheme = ThemeMode.system;

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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Color(0xFF1E293B), Color(0xFF334155)]
              : [Color(0xFF667eea), Color(0xFF764ba2)],
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
                    _buildAnimatedCard(StatsGrid(isDark: isDark), 3),
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
            _buildThemeButton(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
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
          Icon(Icons.wifi, size: 14, color: Color(0xFF16A34A)),
          SizedBox(width: 4),
          Text(
            'Connected',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton(BuildContext context, bool isDark) {
    return PopupMenuButton<ThemeMode>(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? Color(0xFF475569).withOpacity(0.8)
              : Color(0xFFF8FAFC).withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(_getThemeIcon(_currentTheme), color: Color(0xFF4689C8)),
      ),
      onSelected: (ThemeMode mode) {
        setState(() {
          _currentTheme = mode;
        });
        widget.onThemeChanged(mode);
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(Icons.light_mode, size: 20),
              SizedBox(width: 8),
              Text('Light'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(Icons.dark_mode, size: 20),
              SizedBox(width: 8),
              Text('Dark'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(Icons.settings_system_daydream, size: 20),
              SizedBox(width: 8),
              Text('System'),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_system_daydream;
    }
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
          child: FadeTransition(opacity: fadeAnimation, child: child),
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
          child: AnimatedBuilder(
            animation: _fillAnimation,
            builder: (context, child) {
              return Container(
                width: 150,
                height: 200,
                child: Stack(
                  children: [
                    // Tank outline
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF4F46E5), width: 3),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        ),
                        color: widget.isDark
                            ? Color(0xFF334155)
                            : Color(0xFFF8FAFC),
                      ),
                    ),
                    // Water fill
                    Positioned(
                      bottom: 0,
                      left: 3,
                      right: 3,
                      child: Container(
                        height: (200 - 6) * _fillAnimation.value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF5FC8D6), Color(0xFF4689C8)],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                            bottomLeft: Radius.circular(2),
                            bottomRight: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // Water waves
                    Positioned(
                      bottom: (200 - 6) * _fillAnimation.value,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 20,
                        child: CustomPaint(
                          painter: WavePainter(),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                    // Percentage text
                    Center(
                      child: Text(
                        '${(0.75 * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: widget.isDark
                              ? Color(0xFFF1F5F9)
                              : Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
    // Rest of your existing build method remains the same
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
        color: isDark
            ? Color(0xFF475569).withOpacity(0.5)
            : Color(0xFFF8FAFC),
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
                        color: isDark
                            ? Color(0xFF94A3B8)
                            : Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark
                            ? Color(0xFFF1F5F9)
                            : Color(0xFF1F2937),
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
            backgroundColor: isDark
                ? Color(0xFF334155)
                : Color(0xFFE5E7EB),
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

class StatsGrid extends StatelessWidget {
  final bool isDark;

  const StatsGrid({Key? key, required this.isDark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            value: '2.5h',
            label: 'Last Refill',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up,
            value: '85L',
            label: 'Daily Usage',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.thermostat,
            value: '22°C',
            label: 'Temperature',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Color(0xFF1E293B), Color(0xFF334155)]
              : [Color(0xFF667eea), Color(0xFF764ba2)],
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
                    _buildAnimatedCard(StatsGrid(isDark: isDark), 1),
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
    // Simulate PDF report generation and download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading report...'),
        backgroundColor: Color(0xFF4689C8),
      ),
    );
    await Future.delayed(Duration(seconds: 2));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report downloaded successfully'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
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
  bool _notificationsEnabled = true;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
                    _buildAnimatedCard(_buildAboutSection(isDark), 3),
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
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.edit, color: Color(0xFF4689C8)),
            ),
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
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) =>
                  LoginScreen(onThemeChanged: widget.onThemeChanged),
            ),
            (route) => false,
          );
        }, isDark),
      ],
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
        _buildThemeSelector(isDark),
      ],
    );
  }

  Widget _buildThemeSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            _buildThemeOption(
              'Light',
              Icons.light_mode,
              ThemeMode.light,
              isDark,
            ),
            SizedBox(width: 12),
            _buildThemeOption('Dark', Icons.dark_mode, ThemeMode.dark, isDark),
            SizedBox(width: 12),
            _buildThemeOption(
              'System',
              Icons.settings_system_daydream,
              ThemeMode.system,
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    String label,
    IconData icon,
    ThemeMode themeMode,
    bool isDark,
  ) {
    final isSelected = _selectedTheme == themeMode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTheme = themeMode;
          });
          widget.onThemeChanged(themeMode);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Color(0xFF4689C8)
                : (isDark
                      ? Color(0xFF475569).withOpacity(0.5)
                      : Color(0xFFF8FAFC)),
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
                    ? Colors.white
                    : (isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937)),
                size: 24,
              ),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Color(0xFFF1F5F9) : Color(0xFF1F2937)),
                ),
              ),
            ],
          ),
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
          ['English', 'Spanish', 'French', 'German', 'Chinese'],
          (value) {
            setState(() {
              _selectedLanguage = value!;
            });
          },
          isDark,
        ),
      ],
    );
  }

  Widget _buildAboutSection(bool isDark) {
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
        _buildSettingsButton(
          'Terms of Service',
          Icons.description,
          () {},
          isDark,
        ),
        _buildSettingsButton(
          'Privacy Policy',
          Icons.privacy_tip,
          () {},
          isDark,
        ),
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
              // Handle password update
            }),
            Divider(),
            _buildSettingItem(context, 'Change Email', Icons.email, () {
              // Handle email change
            }),
            Divider(),
            _buildSettingItem(context, 'Change Name', Icons.person, () {
              // Handle name change
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
              // Navigate to FAQs
            }),
            Divider(),
            _buildHelpItem(context, 'Contact Support', Icons.support_agent, () {
              // Navigate to contact support
            }),
            Divider(),
            _buildHelpItem(context, 'User Guide', Icons.book, () {
              // Navigate to user guide
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
