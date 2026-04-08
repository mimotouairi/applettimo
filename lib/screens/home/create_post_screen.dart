import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedMedia;
  String _mediaType = 'text'; // 'text', 'image', 'video'
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedMedia = File(image.path);
        _mediaType = 'image';
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedMedia = File(video.path);
        _mediaType = 'video';
      });
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة محتوى أو اختيار وسائط')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      // Change createPost to addPost to match the actual provider implementation
      final success = await postProvider.addPost(
        _contentController.text,
        _selectedMedia,
        'public', // Default privacy
      );

      if (mounted) {
        if (success['success'] == true) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم نشر المنشور بنجاح')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success['error'] ?? 'فشل نشر المنشور')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('إنشاء منشور', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('نشر', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: user?['photo'] != null 
                          ? NetworkImage(user!['photo']) 
                          : null,
                        child: user?['photo'] == null ? const Icon(Icons.person) : null,
                      ),
                      Container(
                        width: 2,
                        height: 150,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [colors.primary.withValues(alpha: 0.5), Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?['name'] ?? 'مستخدم',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextField(
                          controller: _contentController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'بماذا تفكر؟',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          style: const TextStyle(fontSize: 18),
                        ),
                        if (_selectedMedia != null) ...[
                          const SizedBox(height: 12),
                          Stack(
                            children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: _mediaType == 'image'
                              ? Image.file(_selectedMedia!, fit: BoxFit.contain)
                              : Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.black87,
                                  child: const Center(
                                    child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                                  ),
                                ),
                          ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() { _selectedMedia = null; _mediaType = 'text'; }),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            const Text('إضافة إلى منشورك', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.image_rounded, color: Colors.green[400]),
              onPressed: _pickImage,
            ),
            IconButton(
              icon: Icon(Icons.videocam_rounded, color: colors.error),
              onPressed: _pickVideo,
            ),
            IconButton(
              icon: Icon(Icons.location_on_rounded, color: Colors.blue[400]),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.emoji_emotions_outlined, color: Colors.orange[400]),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
