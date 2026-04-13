import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
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

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _logoAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
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
    final colors = Theme.of(context).extension<CustomColors>()!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Background Glow Effect
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.secondary.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_fadeController, _slideController, _logoController]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            // Logo Section
                            ScaleTransition(
                              scale: _logoAnimation,
                              child: Column(
                                children: [
                                  // Simplified beautiful icon instead of asset if it's missing, or keep asset inside a container
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: colors.primaryGradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.primary.withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        )
                                      ],
                                    ),
                                    child: const Icon(Icons.blur_on_rounded, size: 50, color: Colors.white),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Lettuce',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.0,
                                      foreground: Paint()
                                        ..shader = LinearGradient(
                                          colors: colors.primaryGradient,
                                        ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'استكشف وتواصل مع مجتمعك',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 50),
                            
                            // Glassmorphism Form container
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: colors.surface.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  FocusScope(
                                    child: Focus(
                                      onFocusChange: (f) => setState(() => _focusedInput = f ? 'email' : null),
                                      child: CustomInput(
                                        placeholder: 'البريد الإلكتروني',
                                        icon: Icons.mail_rounded,
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        isFocused: _focusedInput == 'email',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FocusScope(
                                    child: Focus(
                                      onFocusChange: (f) => setState(() => _focusedInput = f ? 'pwd' : null),
                                      child: CustomInput(
                                        placeholder: 'كلمة المرور',
                                        icon: Icons.lock_rounded,
                                        controller: _passwordController,
                                        isPassword: true,
                                        showPassword: _showPassword,
                                        onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                                        isFocused: _focusedInput == 'pwd',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft, // Left aligned for arabic / or right depends on direction
                                    child: TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('خدمة استعادة كلمة المرور ستتوفر قريباً')),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: colors.primary,
                                      ),
                                      child: const Text(
                                        'نسيت كلمة المرور؟',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  CustomButton(
                                    text: 'تسجيل الدخول',
                                    onPressed: _handleLogin,
                                    loading: authProvider.loading,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            Row(
                              children: [
                                Expanded(child: Divider(color: colors.border)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  child: Text('أو متابعة باستخدام', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                                ),
                                Expanded(child: Divider(color: colors.border)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Google Login Button Premium
                            Container(
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تسجيل الدخول عبر جوجل سيتوفر قريباً')),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Fake Google Icon colors
                                        const Icon(Icons.g_mobiledata_rounded, size: 30, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Text(
                                          'جوجل',
                                          style: TextStyle(
                                            color: colors.text,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            // Footer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('ليس لديك حساب؟', style: TextStyle(color: colors.textSecondary, fontSize: 15)),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => context.push('/register'),
                                  child: Text(
                                    'سجل الآن',
                                    style: TextStyle(
                                      color: colors.primary, 
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
