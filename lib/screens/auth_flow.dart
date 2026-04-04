import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_cards.dart';
import 'dashboard_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .then((doc) {
          if (!mounted) return;
          if (doc.exists && doc.data()?['role'] != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const DashboardShell()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                  builder: (_) => const RoleSelectionScreen()),
            );
          }
        }).catchError((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/auth');
        });
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF2FF), Colors.white],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 25,
                          offset: Offset(0, 12),
                          color: Color(0x221066E8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.currency_exchange,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'TrustNet',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Decentralized P2P Lending',
                    style: TextStyle(fontSize: 16, color: Color(0xFF4F5F75)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_BoardData> _pages = const [
    _BoardData(
      icon: Icons.hub_outlined,
      title: 'Decentralized & Trustless',
      subtitle:
          'No central authority. Connect directly with the community on a public ledger.',
    ),
    _BoardData(
      icon: Icons.verified_user_outlined,
      title: 'Smart Contract Security',
      subtitle:
          'Every loan step is enforced by transparent, immutable protocol rules.',
    ),
    _BoardData(
      icon: Icons.trending_up,
      title: 'Reputation as Collateral',
      subtitle:
          'Build your decentralized identity and trust score through honest P2P behavior.',
    ),
  ];

  void _goNext() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      return;
    }
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/auth'),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _index = value),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 220,
                          width: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(34),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8F1FF), Color(0xFFD6FFE9)],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 24,
                                color: Color(0x1611223A),
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 260),
                            scale: _index == index ? 1 : 0.92,
                            child: Icon(item.icon, size: 96, color: primaryBlue),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF55657D),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 8),
                          height: 8,
                          width: _index == i ? 26 : 8,
                          decoration: BoxDecoration(
                            color: _index == i
                                ? primaryBlue
                                : const Color(0xFFB8C5D8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      elevation: 1,
                    ),
                    onPressed: _goNext,
                    child: Text(
                      _index == _pages.length - 1 ? 'Get Started' : 'Next',
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _BoardData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BoardData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Enter your email address';
    }
    if (!_isValidEmail(text)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _login() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isLoading = true);
    try {
      final cred = await _authService.signInWithEmailOrPhone(
        identifier: _identifierController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user?.uid)
            .get();

        if (!mounted) return;
        if (doc.exists && doc.data()?['role'] != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const DashboardShell()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen()),
          );
        }
      } on FirebaseException catch (e) {
        if (!mounted) return;
        if (e.code == 'permission-denied') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen()),
          );
        } else {
          rethrow;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readableAuthError(e))),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not load your profile.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final cred = await _authService.signInWithGoogle();
      if (!mounted) return;

      if (cred == null) {
        return;
      }

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user?.uid)
            .get();

        if (!mounted) return;
        if (doc.exists && doc.data()?['role'] != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const DashboardShell()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen()),
          );
        }
      } on FirebaseException catch (e) {
        if (!mounted) return;
        if (e.code == 'permission-denied') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen()),
          );
        } else {
          rethrow;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'google-sign-in-cancelled') {
        setState(() => _isLoading = false);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readableAuthError(e))),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not load your profile.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetController = TextEditingController(
      text: _isValidEmail(_identifierController.text)
          ? _identifierController.text.trim()
          : '',
    );
    bool isSending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your registered email. We will send a password reset link that is valid for a short time. If it expires, you can request a new one.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resetController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isSending,
                    decoration: _inputDecoration(
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetController.text.trim();
                          if (!_isValidEmail(email)) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Enter a valid email address.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSending = true);
                          try {
                            await _authService.sendPasswordReset(email);
                            if (!mounted) return;

                            _identifierController.text = email;
                            Navigator.of(this.context).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Reset link sent. Check your inbox and spam folder.',
                                ),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            if (!mounted) return;
                            setDialogState(() => isSending = false);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text(_readableAuthError(e))),
                            );
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send Link'),
                ),
              ],
            );
          },
        );
      },
    );

    resetController.dispose();
  }

  String _readableAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AuthScaffold(
        title: 'Secure Login',
        subtitle:
            'Welcome to Decentralized Lending Platform. Login in seconds and continue safely.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FinanceBadge(
                icon: Icons.lock_rounded,
                text: 'Secure Login',
                color: const Color(0xFFE8F1FF),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _identifierController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateIdentifier,
                decoration: _inputDecoration(
                  label: 'Email Address',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                validator: _validatePassword,
                decoration: _inputDecoration(
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                  ),
                  const Text('Remember Me'),
                  const Spacer(),
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _login,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Continue with Google'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text('New user? Create account'),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  '100% Secure & Transparent',
                  style: TextStyle(
                    color: Color(0xFF5A6A80),
                    fontWeight: FontWeight.w600,
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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _role = 'Borrower';

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Please enter your full name';
    }
    return null;
  }

  String? _validateIdentifier(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Enter your email address';
    }
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    if (!isEmail) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String _strengthLabel(String password) {
    if (password.length < 6) return 'Weak';
    final hasNumber = RegExp(r'\d').hasMatch(password);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    if (password.length >= 8 && hasNumber && hasUpper) return 'Strong';
    return 'Medium';
  }

  Color _strengthColor(String password) {
    final label = _strengthLabel(password);
    if (label == 'Strong') return const Color(0xFF1E8E5A);
    if (label == 'Medium') return const Color(0xFFF39C12);
    return const Color(0xFFC0392B);
  }

  Future<void> _createAccount() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.createAccountWithEmail(
        fullName: _nameController.text,
        identifier: _identifierController.text,
        password: _passwordController.text,
        role: _role.toLowerCase(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created successfully as $_role.')),
      );
      _continueWithSelectedRole();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readableAuthError(e))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signupWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final cred = await _authService.signInWithGoogle(
        role: _role.toLowerCase(),
        fullName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
      );
      if (!mounted) return;
      if (cred == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in with Google successfully.')),
      );
      _continueWithSelectedRole();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'google-sign-in-cancelled') {
        setState(() => _isLoading = false);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readableAuthError(e))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continueWithSelectedRole() {
    if (_role == 'Borrower') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const BorrowerProfileDetailsScreen(),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const DashboardShell(),
      ),
    );
  }

  String _readableAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already in use. Please login instead.';
      case 'weak-password':
        return 'Use a stronger password (at least 6 characters).';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Check your internet and try again.';
      default:
        return e.message ?? 'Signup failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;
    final strength = _strengthLabel(password);

    return Scaffold(
      body: _AuthScaffold(
        title: 'Create your account',
        subtitle:
            'Simple signup for beginners. Start borrowing or lending in under a minute.',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FinanceBadge(
                icon: Icons.verified_user_outlined,
                text: '100% Secure & Transparent',
                color: const Color(0xFFE7F8EF),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                validator: _validateName,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Full Name',
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _identifierController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateIdentifier,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Email Address',
                  icon: Icons.alternate_email_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                validator: _validatePassword,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: password.isEmpty
                            ? 0
                            : (password.length >= 8 ? 1 : password.length / 8),
                        minHeight: 8,
                        color: _strengthColor(password),
                        backgroundColor: const Color(0xFFDCE5F3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    password.isEmpty ? 'Add password' : '$strength password',
                    style: TextStyle(
                      color: password.isEmpty
                          ? const Color(0xFF5A6A80)
                          : _strengthColor(password),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                validator: _validateConfirmPassword,
                decoration: _inputDecoration(
                  label: 'Confirm Password',
                  icon: Icons.lock_reset_outlined,
                  suffix: IconButton(
                    onPressed: () {
                      setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Choose role',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Borrower'),
                      selected: _role == 'Borrower',
                      onSelected: (_) => setState(() => _role = 'Borrower'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Lender'),
                      selected: _role == 'Lender',
                      onSelected: (_) => setState(() => _role = 'Lender'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _createAccount,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signupWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Sign up with Google'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your data is सुरक्षित and secure',
                style: TextStyle(color: Color(0xFF5A6A80)),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Already have an account? Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF2FF), Color(0xFFF8FCFF), Colors.white],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: primaryBlue),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Decentralized Lending Platform',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF4F5F75),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x180E2A57),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _FinanceBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: primaryBlue),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF224166),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF9FBFF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD7E1EF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD7E1EF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: primaryBlue, width: 1.4),
    ),
  );
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _setRoleSafely(
    BuildContext context, {
    required String role,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'role': role}, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (!context.mounted) {
        return;
      }
      if (e.code == 'permission-denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firestore permission denied. Publish rules and try again.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not save your role.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Role')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpace.x3 - 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How do you want to interact with the trustless protocol?',
              style: TextStyle(fontSize: 16, color: mutedInk),
            ),
            const SizedBox(height: 12),
            RoleCard(
              title: 'Borrow Money',
              description: 'Request quick loans with no traditional credit score.',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFFE8F1FF),
              badge: const StatusBadge(label: 'Beginner Friendly', color: primaryBlue),
              onTap: () async {
                await _setRoleSafely(context, role: 'borrower');
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BorrowerProfileDetailsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            RoleCard(
              title: 'Lend Money',
              description: 'Support borrowers and earn by funding verified requests.',
              icon: Icons.volunteer_activism_outlined,
              color: const Color(0xFFE7F8EF),
              badge: const StatusBadge(label: 'Verified Flow', color: trustGreen),
              onTap: () async {
                await _setRoleSafely(context, role: 'lender');
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const DashboardShell(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BorrowerProfileDetailsScreen extends StatefulWidget {
  const BorrowerProfileDetailsScreen({super.key});

  @override
  State<BorrowerProfileDetailsScreen> createState() =>
      _BorrowerProfileDetailsScreenState();
}

class _BorrowerProfileDetailsScreenState extends State<BorrowerProfileDetailsScreen> {
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController();
  final _purposeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  int _generateTrustScore(double income, String purpose) {
    var score = 50;
    if (income >= 40000) {
      score += 18;
    } else if (income >= 20000) {
      score += 12;
    } else if (income >= 10000) {
      score += 8;
    } else {
      score += 4;
    }

    final normalizedPurpose = purpose.toLowerCase();
    if (normalizedPurpose.contains('business') ||
        normalizedPurpose.contains('education') ||
        normalizedPurpose.contains('medical')) {
      score += 10;
    } else {
      score += 6;
    }
    return score.clamp(45, 90);
  }

  void _continue() async {
    final name = _nameController.text.trim();
    final income = double.tryParse(_incomeController.text.trim()) ?? 0;
    final purpose = _purposeController.text.trim();

    if (name.isEmpty || income <= 0 || purpose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all profile fields.')),
      );
      return;
    }

    final trustScore = _generateTrustScore(income, purpose);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'fullName': name,
              'trustScore': trustScore,
              'income': income,
              'purpose': purpose,
              'role': 'borrower',
            }, SetOptions(merge: true));
      }
    } catch (e) {
      // Ignore errors for now or log them
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const DashboardShell(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrower Profile Details')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.x3 - 4),
        children: [
          const StatusBadge(label: 'Step 1 of 1', color: primaryBlue),
          const SizedBox(height: 10),
          const Text(
            'Enter Profile Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Name, income, and purpose help us generate your initial trust score.',
            style: TextStyle(color: Color(0xFF5A6A80)),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              helperText: 'Use your full legal name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monthly income',
              helperText: 'Approximate value works fine',
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _purposeController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Primary loan purpose',
              hintText: 'e.g., Grocery shop inventory',
              helperText: 'Short purpose improves clarity for lenders',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _continue,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 13),
              child: Text('Generate Trust Score & Continue'),
            ),
          )
        ],
      ),
    );
  }
}

class RoleCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget? badge;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _pressed ? 0.98 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: widget.onTap,
          child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: _pressed ? AppShadow.light : AppShadow.medium,
        ),
        child: Row(
          children: [
            Icon(widget.icon, size: 40, color: primaryBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style:
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.description,
                    style: const TextStyle(color: mutedInk),
                  ),
                  if (widget.badge != null) const SizedBox(height: 10),
                  if (widget.badge != null) widget.badge!,
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18)
          ],
        ),
          ),
        ),
      ),
    );
  }
}
