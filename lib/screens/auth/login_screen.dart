import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _focusedInput;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _logoController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _logoAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _logoController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.login(email, password);

    if (!result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'حدث خطأ ما')),
        );
      }
    } else {
      if (mounted) {
        context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: AnimatedBuilder(
            animation: Listenable.merge([_fadeController, _slideController, _logoController]),
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      // Logo Section
                      ScaleTransition(
                        scale: _logoAnimation,
                        child: Column(
                          children: [
                            Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Lettuce',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: colors.text,
                              ),
                            ),
                            Text(
                              'مرحباً بك في عالم الخصوصية',
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 45),
                      // Form
                      CustomInput(
                        placeholder: 'البريد الإلكتروني',
                        icon: Icons.mail_outline,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        isFocused: _focusedInput == 'email',
                        onChanged: (v) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      CustomInput(
                        placeholder: 'كلمة المرور',
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        showPassword: _showPassword,
                        onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                        isFocused: _focusedInput == 'password',
                        onChanged: (v) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('خدمة استعادة كلمة المرور ستتوفر قريباً')),
                            );
                          },
                          child: Text(
                            'نسيت كلمة المرور؟',
                            style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      CustomButton(
                        text: 'تسجيل الدخول',
                        onPressed: _handleLogin,
                        loading: authProvider.loading,
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          Expanded(child: Divider(color: colors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Text('أو', style: TextStyle(color: colors.textSecondary)),
                          ),
                          Expanded(child: Divider(color: colors.border)),
                        ],
                      ),
                      const SizedBox(height: 25),
                      // Google Login Button
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تسجيل الدخول عبر جوجل سيتوفر قريباً')),
                          );
                        },
                        icon: const Icon(Icons.g_mobiledata, size: 30),
                        label: const Text('الدخول عبر جوجل'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ليس لديك حساب؟', style: TextStyle(color: colors.textSecondary)),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: Text(
                              'سجل الآن',
                              style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
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
