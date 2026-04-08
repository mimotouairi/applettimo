import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  XFile? _selectedPhoto;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?['name'] ?? '');
    _bioController = TextEditingController(text: user?['bio'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedPhoto = image;
      });
    }
  }

  Future<void> _handleSave() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم المستخدم')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl = authProvider.user?['photo'];

      // Upload new photo if selected
      if (_selectedPhoto != null) {
        final uploadResult = await ApiService.upload('upload_media', File(_selectedPhoto!.path));
        if (uploadResult['success']) {
          photoUrl = uploadResult['data']['url'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل رفع الصورة، سيتم التحديث بدون تغيير الصورة')),
          );
        }
      }

      final result = await authProvider.updateProfile({
        'name': name,
        'bio': _bioController.text.trim(),
        'photo': photoUrl,
      });

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'فشل التحديث')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ غير متوقع')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => context.pop(),
        ),
        title: Text('تعديل الملف الشخصي', style: TextStyle(color: colors.text, fontWeight: FontWeight.w900)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('حفظ', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Section
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(44),
                            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _selectedPhoto != null
                              ? Image.file(File(_selectedPhoto!.path), fit: BoxFit.cover)
                              : (user?['photo'] != null
                                  ? Image.network(ApiService.getImageUrl(user!['photo'])!, fit: BoxFit.cover)
                                  : Icon(Icons.person, size: 60, color: colors.primary)),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _pickImage,
                    child: Text('تغيير صورة الملف الشخصي', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Name Input
            _buildInputGroup(label: 'الاسم', controller: _nameController, hint: 'أدخل اسمك', colors: colors),
            const SizedBox(height: 24),
            // Bio Input
            _buildInputGroup(label: 'نبذة تعريفية', controller: _bioController, hint: 'أخبر المجتمع عن نفسك...', colors: colors, maxLines: 4),
            const SizedBox(height: 24),
            // Read-only Email
            _buildInputGroup(
              label: 'البريد الإلكتروني',
              controller: TextEditingController(text: user?['email']),
              hint: '',
              colors: colors,
              enabled: false,
              description: 'لا يمكن تغيير البريد الإلكتروني المسجل.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputGroup({
    required String label,
    required TextEditingController controller,
    required String hint,
    required dynamic colors,
    int maxLines = 1,
    bool enabled = true,
    String? description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.text, fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          style: TextStyle(color: colors.text, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
            filled: true,
            fillColor: enabled ? colors.surface : colors.textSecondary.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }
}
