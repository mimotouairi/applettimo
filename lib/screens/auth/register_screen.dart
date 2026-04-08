import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
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

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _avatarController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
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
            title: const Text('نجاح'),
            content: const Text('تم إنشاء الحساب بنجاح! يرجى تفعيل بريدك الإلكتروني.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
                child: const Text('حسناً'),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
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
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: Icon(Icons.arrow_back, color: colors.text),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'إنشاء حساب جديد',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: colors.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Image.asset(
                        'assets/images/logo.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 35),
                      // Avatar Section
                      ScaleTransition(
                        scale: _avatarAnimation,
                        child: GestureDetector(
                          onTap: _handleChoosePhoto,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: themeProvider.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colors.border, width: 2),
                                  image: _avatar != null
                                      ? DecorationImage(image: FileImage(_avatar!), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: _avatar == null
                                    ? Icon(Icons.person_outline, size: 45, color: colors.textSecondary)
                                    : null,
                              ),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'أضف لمستك الخاصة بوضع صورة',
                        style: TextStyle(fontSize: 13, color: colors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 35),
                      // Form
                      CustomInput(
                        placeholder: 'الاسم الكامل',
                        icon: Icons.person_outline,
                        controller: _nameController,
                        isFocused: _focusedInput == 'name',
                        onChanged: (v) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
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
                        placeholder: 'رقم الهاتف',
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        isFocused: _focusedInput == 'phone',
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
                      const SizedBox(height: 14),
                      CustomInput(
                        placeholder: 'تأكيد كلمة المرور',
                        icon: Icons.shield_outlined,
                        controller: _confirmController,
                        isPassword: true,
                        showPassword: _showPassword,
                        isFocused: _focusedInput == 'confirm',
                        onChanged: (v) => setState(() {}),
                      ),
                      const SizedBox(height: 25),
                      CustomButton(
                        text: 'إنشاء حساب جديد',
                        onPressed: _handleRegister,
                        loading: authProvider.loading,
                      ),
                      const SizedBox(height: 25),
                      // Divider and Google
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
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('خدمة التسجيل عبر جوجل ستتوفر قريباً')),
                          );
                        },
                        icon: const Icon(Icons.g_mobiledata, size: 30),
                        label: const Text('التسجيل عبر جوجل'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('لديك حساب بالفعل؟', style: TextStyle(color: colors.textSecondary)),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: Text(
                              'سجل دخول',
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
