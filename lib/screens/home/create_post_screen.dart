import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  final String? mode;
  const CreatePostScreen({super.key, this.mode});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const String _draftKey = 'create_post_draft_text';
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedMedia;
  List<File> _selectedImages = [];
  String _mediaType = 'text'; // 'text', 'image', 'video'
  bool _isLoading = false;
  Timer? _draftTimer;
  
  // Tagging system state
  bool _showSuggestions = false;
  String _mentionQuery = '';
  int _mentionStartIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'multi-image') {
      _mediaType = 'image';
    } else if (widget.mode == 'video') {
      _mediaType = 'video';
    }
    _restoreDraft();
    _contentController.addListener(_scheduleDraftSave);
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftText = prefs.getString(_draftKey);
    if (draftText != null && mounted) {
      setState(() {
        _contentController.text = draftText;
      });
    }
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 450), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      await prefs.remove(_draftKey);
    } else {
      await prefs.setString(_draftKey, text);
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((e) => File(e.path)).toList();
        _selectedMedia = _selectedImages.first;
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
    final hasMultiImages = _selectedImages.isNotEmpty;
    if (_contentController.text.trim().isEmpty && _selectedMedia == null && !hasMultiImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة محتوى أو اختيار وسائط')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final success = hasMultiImages
          ? await postProvider.addPostMultiImage(
              _contentController.text,
              _selectedImages,
              'public',
            )
          : await postProvider.addPost(
              _contentController.text,
              _selectedMedia,
              'public',
            );

      if (mounted) {
        if (success['success'] == true) {
          await _clearDraft();
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

  void _onTextChanged(String text) {
    _scheduleDraftSave();
    
    final selection = _contentController.selection;
    if (selection.baseOffset < 0) return;

    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final lastAt = textBeforeCursor.lastIndexOf('@');

    if (lastAt != -1) {
      // Check if there is a space between @ and cursor
      final textSinceAt = textBeforeCursor.substring(lastAt);
      if (!textSinceAt.contains(' ')) {
        final query = textSinceAt.substring(1); // Remove @
        _mentionStartIndex = lastAt;
        _mentionQuery = query;
        
        if (query.isNotEmpty) {
          setState(() => _showSuggestions = true);
          Provider.of<PostProvider>(context, listen: false).searchUsers(query);
        } else {
          setState(() => _showSuggestions = false);
        }
        return;
      }
    }

    if (_showSuggestions) {
      setState(() => _showSuggestions = false);
    }
  }

  void _selectUser(Map<String, dynamic> user) {
    final String username = user['username'] ?? '';
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    if (_mentionStartIndex == -1) return;

    final beforeMention = text.substring(0, _mentionStartIndex);
    final afterMention = text.substring(selection.baseOffset);
    
    final newText = '$beforeMention@$username $afterMention';
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: beforeMention.length + username.length + 2),
    );

    setState(() {
      _showSuggestions = false;
      _mentionStartIndex = -1;
      _mentionQuery = '';
    });
  }

  Widget _buildSuggestionsList(CustomColors colors) {
    final postProvider = Provider.of<PostProvider>(context);
    final users = postProvider.foundUsers;

    if (users.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: users.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: colors.border.withValues(alpha: 0.3)),
        itemBuilder: (context, index) {
          final user = users[index];
          final avatarUrl = ApiService.getImageUrl(user['photo']);
          
          return ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null ? const Icon(Icons.person, size: 20) : null,
            ),
            title: Text(user['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('@${user['username']}', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            onTap: () => _selectUser(user),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _contentController.removeListener(_scheduleDraftSave);
    _contentController.dispose();
    super.dispose();
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
          IconButton(
            onPressed: () async {
              _contentController.clear();
              await _clearDraft();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف المسودة')),
                );
              }
            },
            icon: const Icon(Icons.delete_outline),
            tooltip: 'حذف المسودة',
          ),
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
                          ? NetworkImage(ApiService.getImageUrl(user!['photo'])!)
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
                          onChanged: _onTextChanged,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'بماذا تفكر؟',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          style: const TextStyle(fontSize: 18),
                        ),
                        if (_showSuggestions) _buildSuggestionsList(colors),
                        if (_selectedMedia != null) ...[
                          const SizedBox(height: 12),
                          if (_selectedImages.isNotEmpty)
                            Container(
                              height: 250,
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) => Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.file(_selectedImages[index], width: 250, height: 250, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _selectedImages.removeAt(index);
                                          if (_selectedImages.isEmpty) {
                                            _selectedMedia = null;
                                            _mediaType = 'text';
                                          } else {
                                            _selectedMedia = _selectedImages[0];
                                          }
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                    // Image count indicator
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                                        child: Text('${index + 1}/${_selectedImages.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
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
                                    onTap: () => setState(() {
                                      _selectedMedia = null;
                                      _selectedImages = [];
                                      _mediaType = 'text';
                                    }),
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
