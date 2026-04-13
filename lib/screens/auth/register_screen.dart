import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  
  File? _avatar;
  bool _showPassword = false;
  String? _focusedInput;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _avatarController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _avatarAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _avatarController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _avatarAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _avatarController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _handleChoosePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 500,
      maxHeight: 500,
    );

    if (pickedFile != null) {
      setState(() {
        _avatar = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final phone = _phoneController.text;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمات المرور غير متطابقة')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      profileImage: _avatar,
    );

    if (result['success']) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('نجاح', style: TextStyle(fontWeight: FontWeight.w900)),
            content: const Text('تم إنشاء الحساب بنجاح! يرجى الدخول لحسابك.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
                child: const Text('حسناً', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'حدث خطأ ما')),
        );
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
            left: -100,
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
            right: -50,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AnimatedBuilder(
                animation: Listenable.merge([_fadeController, _slideController, _avatarController]),
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: () => context.pop(),
                                  icon: Icon(Icons.arrow_back_rounded, color: colors.text),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'إنشاء حساب جديد',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: colors.text,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          
                          // Avatar Section
                          ScaleTransition(
                            scale: _avatarAnimation,
                            child: GestureDetector(
                              onTap: _handleChoosePhoto,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.primary.withValues(alpha: 0.2),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        )
                                      ],
                                      border: Border.all(
                                        color: _avatar != null ? colors.primary : colors.border, 
                                        width: 3,
                                      ),
                                      image: _avatar != null
                                          ? DecorationImage(image: FileImage(_avatar!), fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: _avatar == null
                                        ? Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.person_add_rounded, size: 40, color: colors.primary.withValues(alpha: 0.7)),
                                              const SizedBox(height: 4),
                                              Text('صورة', style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.w600)),
                                            ],
                                          )
                                        : null,
                                  ),
                                  if (_avatar != null)
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: colors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: colors.background, width: 4),
                                      ),
                                      child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          
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
                                    onFocusChange: (f) => setState(() => _focusedInput = f ? 'name' : null),
                                    child: CustomInput(
                                      placeholder: 'الاسم الكامل',
                                      icon: Icons.person_rounded,
                                      controller: _nameController,
                                      isFocused: _focusedInput == 'name',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
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
                                    onFocusChange: (f) => setState(() => _focusedInput = f ? 'phone' : null),
                                    child: CustomInput(
                                      placeholder: 'رقم الهاتف',
                                      icon: Icons.phone_rounded,
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      isFocused: _focusedInput == 'phone',
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
                                const SizedBox(height: 16),
                                FocusScope(
                                  child: Focus(
                                    onFocusChange: (f) => setState(() => _focusedInput = f ? 'confirm' : null),
                                    child: CustomInput(
                                      placeholder: 'تأكيد كلمة المرور',
                                      icon: Icons.shield_rounded,
                                      controller: _confirmController,
                                      isPassword: true,
                                      showPassword: _showPassword,
                                      isFocused: _focusedInput == 'confirm',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: 'إنشاء حساب',
                                  onPressed: _handleRegister,
                                  loading: authProvider.loading,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          // Divider and Google
                          Row(
                            children: [
                              Expanded(child: Divider(color: colors.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: Text('أو متابعة عبر', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                              ),
                              Expanded(child: Divider(color: colors.border)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
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
                                    const SnackBar(content: Text('التسجيل عبر جوجل سيتوفر قريباً')),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
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
                          
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('لديك حساب بالفعل؟', style: TextStyle(color: colors.textSecondary, fontSize: 15)),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Text(
                                  'سجل دخول',
                                  style: TextStyle(
                                    color: colors.primary, 
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
