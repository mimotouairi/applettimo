import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  List<Post> _savedPosts = [];
  List<Post> _videoPosts = [];
  List<Map<String, dynamic>> _suggestedUsers = [];
  List<Map<String, dynamic>> _foundUsers = [];
  bool _loading = false;
  String? _error;
  AuthProvider _authProvider;
  final Set<String> _viewTrackedPostIds = <String>{};

  PostProvider(this._authProvider) {
    _authProvider.addListener(_onAuthChanged);
    if (_authProvider.isAuthenticated) {
      fetchPosts();
      fetchSavedPosts();
    }
  }

  void _onAuthChanged() {
    if (_authProvider.isAuthenticated && _posts.isEmpty && !_loading) {
      fetchPosts();
      fetchSavedPosts();
    }
  }

  void updateAuth(AuthProvider auth) {
    if (_authProvider == auth) return;
    _authProvider.removeListener(_onAuthChanged);
    _authProvider = auth;
    _authProvider.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  List<Post> get posts => _posts;
  List<Post> get savedPosts => _savedPosts;
  List<Post> get videoPosts => _videoPosts;
  List<Map<String, dynamic>> get suggestedUsers => _suggestedUsers;
  List<Map<String, dynamic>> get foundUsers => _foundUsers;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchPosts({bool isRefresh = true}) async {
    if (!_authProvider.isAuthenticated) return;

    if (isRefresh) {
      _loading = true;
      notifyListeners();
    }

    final offset = isRefresh ? 0 : _posts.length;
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.get(
        'get_posts?user_id=$userId&limit=20&offset=$offset',
      );

      if (result['success']) {
        // Fetch saved posts IDs for comparison
        final savedResult = await ApiService.get(
          'get_saved_posts?user_id=$userId',
        );
        final List<String> savedIds = savedResult['success']
            ? (savedResult['data'] as List)
                  .map((p) => p['id'].toString())
                  .toList()
            : [];

        final List<Post> newPosts = (result['data'] as List).map((json) {
          return Post.fromJson(
            json,
            isSaved: savedIds.contains(json['id'].toString()),
          );
        }).toList();

        if (isRefresh) {
          _posts = newPosts;
        } else {
          // Avoid duplicates
          final existingIds = _posts.map((p) => p.id).toSet();
          _posts.addAll(newPosts.where((p) => !existingIds.contains(p.id)));
        }
        _error = null;
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'فشل في تحميل المنشورات';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePosts() async {
    if (!_authProvider.isAuthenticated || _loading) return;

    _loading = true;
    notifyListeners();

    final offset = _posts.length;
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.get(
        'get_posts?user_id=$userId&limit=20&offset=$offset',
      );

      if (result['success']) {
        // Fetch saved posts IDs for comparison
        final savedResult = await ApiService.get(
          'get_saved_posts?user_id=$userId',
        );
        final List<String> savedIds = savedResult['success']
            ? (savedResult['data'] as List)
                  .map((p) => p['id'].toString())
                  .toList()
            : [];

        final List<Post> newPosts = (result['data'] as List).map((json) {
          return Post.fromJson(
            json,
            isSaved: savedIds.contains(json['id'].toString()),
          );
        }).toList();

        // Avoid duplicates
        final existingIds = _posts.map((p) => p.id).toSet();
        _posts.addAll(newPosts.where((p) => !existingIds.contains(p.id)));
        _error = null;
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'فشل في تحميل المزيد من المنشورات';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchVideos({bool isRefresh = true}) async {
    if (!_authProvider.isAuthenticated) return;

    if (isRefresh) {
      _loading = true;
      notifyListeners();
    }

    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.get('get_videos?user_id=$userId');

      if (result['success']) {
        final List<Post> newVideos = (result['data'] as List).map((json) {
          return Post.fromJson(json);
        }).toList();

        if (isRefresh) {
          _videoPosts = newVideos;
        } else {
          _videoPosts.addAll(newVideos);
        }
        _error = null;
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'فشل في تحميل الفيديوهات';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSavedPosts() async {
    if (!_authProvider.isAuthenticated) return;
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.get(
        'get_saved_posts?user_id=$userId',
      );
      if (result['success']) {
        _savedPosts = (result['data'] as List)
            .map((json) => Post.fromJson(json, isSaved: true))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching saved posts: $e');
    }
  }

  Future<Map<String, dynamic>> likePost(String postId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final userId = _authProvider.user!['id'];

    try {
      // Optimistic update
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        final newIsLiked = !post.isLiked;
        _posts[index] = Post(
          id: post.id,
          userId: post.userId,
          userName: post.userName,
          userPhoto: post.userPhoto,
          content: post.content,
          mediaUrl: post.mediaUrl,
          mediaType: post.mediaType,
          likes: newIsLiked ? post.likes + 1 : post.likes - 1,
          commentsCount: post.commentsCount,
          viewsCount: post.viewsCount,
          engagementScore: post.engagementScore,
          createdAt: post.createdAt,
          time: post.time,
          isLiked: newIsLiked,
          isSaved: post.isSaved,
        );
        notifyListeners();
      }

      final result = await ApiService.post('toggle_like', {
        'user_id': userId,
        'post_id': postId,
      });
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل التفاعل'};
    }
  }

  Future<Map<String, dynamic>> toggleSavePost(String postId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false};
    }
    final userId = _authProvider.user!['id'];

    try {
      // Optimistic update
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        _posts[index] = Post(
          id: post.id,
          userId: post.userId,
          userName: post.userName,
          userPhoto: post.userPhoto,
          content: post.content,
          mediaUrl: post.mediaUrl,
          mediaType: post.mediaType,
          likes: post.likes,
          commentsCount: post.commentsCount,
          viewsCount: post.viewsCount,
          engagementScore: post.engagementScore,
          createdAt: post.createdAt,
          time: post.time,
          isLiked: post.isLiked,
          isSaved: !post.isSaved,
        );
        notifyListeners();
      }

      final result = await ApiService.post('toggle_save', {
        'user_id': userId,
        'post_id': postId,
      });
      if (result['success']) {
        fetchSavedPosts();
      }
      return result;
    } catch (e) {
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> deletePost(String postId) async {
    if (!_authProvider.isAuthenticated)
      return {'success': false, 'message': 'يجب تسجيل الدخول أولاً'};
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.post('delete_post', {
        'user_id': userId,
        'post_id': postId,
      });

      if (result['success']) {
        _posts.removeWhere((p) => p.id == postId);
        _videoPosts.removeWhere((p) => p.id == postId);
        _savedPosts.removeWhere((p) => p.id == postId);
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'فشل حذف المنشور'};
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final result = await ApiService.get('get_user_stats?user_id=$userId');
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل في جلب الإحصائيات'};
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String profileId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false};
    }
    final currentUserId = _authProvider.user!['id'];

    try {
      final result = await ApiService.get(
        'get_user_profile?profile_id=$profileId&current_user_id=$currentUserId',
      );
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل في جلب ملف الشخصي'};
    }
  }

  Future<Map<String, dynamic>> toggleFollow(String profileId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false};
    }
    final currentUserId = _authProvider.user!['id'];

    try {
      final result = await ApiService.post('toggle_follow', {
        'user_id': currentUserId,
        'profile_id': profileId,
      });
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل في تنفيذ العملية'};
    }
  }

  Future<void> fetchSuggestions() async {
    if (!_authProvider.isAuthenticated) return;
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.get(
        'get_suggested_users?current_user_id=$userId',
      );
      if (result['success']) {
        _suggestedUsers = List<Map<String, dynamic>>.from(result['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  Future<void> searchUsers(String query) async {
    if (!_authProvider.isAuthenticated || query.isEmpty) return;
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.get(
        'search_users?q=$query&current_user_id=$userId',
      );
      if (result['success']) {
        _foundUsers = List<Map<String, dynamic>>.from(result['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
    }
  }

  Future<Map<String, dynamic>> fetchComments(String postId) async {
    try {
      final userId = _authProvider.user?['id'];
      final result = await ApiService.get(
        'get_comments?post_id=$postId${userId != null ? '&user_id=$userId' : ''}',
      );
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل في جلب التعليقات'};
    }
  }

  Future<Map<String, dynamic>> fetchPostById(String postId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final existing = _posts.cast<Post?>().firstWhere(
      (p) => p?.id == postId,
      orElse: () => null,
    );
    if (existing != null) {
      return {'success': true, 'data': existing};
    }
    try {
      final userId = _authProvider.user!['id'];
      final result = await ApiService.get('get_post?user_id=$userId&post_id=$postId');
      if (result['success']) {
        final post = Post.fromJson(result['data']);
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index == -1) {
          _posts.insert(0, post);
        } else {
          _posts[index] = post;
        }
        notifyListeners();
        return {'success': true, 'data': post};
      }
      return {'success': false, 'error': result['message'] ?? 'تعذر جلب المنشور'};
    } catch (e) {
      return {'success': false, 'error': 'تعذر جلب المنشور'};
    }
  }

  Future<Map<String, dynamic>> addComment(String postId, String comment) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.post('add_comment', {
        'post_id': postId,
        'user_id': userId,
        'comment': comment,
      });

      if (result['success']) {
        // Update local comment count for the post
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = Post(
            id: post.id,
            userId: post.userId,
            userName: post.userName,
            userPhoto: post.userPhoto,
            content: post.content,
            mediaUrl: post.mediaUrl,
            mediaType: post.mediaType,
            likes: post.likes,
            commentsCount: post.commentsCount + 1,
            viewsCount: post.viewsCount,
            engagementScore: post.engagementScore,
            createdAt: post.createdAt,
            time: post.time,
            isLiked: post.isLiked,
            isSaved: post.isSaved,
          );
          notifyListeners();
        }
      }
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل إضافة التعليق'};
    }
  }

  Future<Map<String, dynamic>> addReply(
    String postId,
    String parentCommentId,
    String comment,
  ) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final userId = _authProvider.user!['id'];
    try {
      return await ApiService.post('add_comment', {
        'post_id': postId,
        'user_id': userId,
        'comment': comment,
        'parent_id': parentCommentId,
      });
    } catch (e) {
      return {'success': false, 'error': 'فشل إضافة الرد'};
    }
  }

  Future<Map<String, dynamic>> toggleCommentLike(String commentId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final userId = _authProvider.user!['id'];
    try {
      return await ApiService.post('toggle_comment_like', {
        'comment_id': commentId,
        'user_id': userId,
      });
    } catch (e) {
      return {'success': false, 'error': 'فشل التفاعل مع التعليق'};
    }
  }

  Future<Map<String, dynamic>> addPost(
    String content,
    File? media,
    String privacy,
  ) async {
    if (!_authProvider.isAuthenticated)
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.post('create_post', {
        'user_id': userId,
        'content': content,
        'privacy': privacy,
        'media_type': media != null
            ? (RegExp(r'\.(mp4|mov|avi|mkv|3gp|flv|webm)$', caseSensitive: false).hasMatch(media.path) ? 'video' : 'image')
            : 'text',
      }, file: media);

      if (result['success']) {
        // Add the new post to the top of the feed
        final newPost = Post.fromJson(result['data']);
        _posts.insert(0, newPost);
        notifyListeners();
        return {'success': true};
      } else {
        return {'success': false, 'error': result['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'فشل نشر المنشور'};
    }
  }

  Future<Map<String, dynamic>> addPostMultiImage(
    String content,
    List<File> images,
    String privacy,
  ) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.postMultipart('create_post_multi', {
        'user_id': userId,
        'content': content,
        'privacy': privacy,
        'media_type': 'image',
      }, files: images);

      if (result['success']) {
        final newPost = Post.fromJson(result['data']);
        _posts.insert(0, newPost);
        notifyListeners();
        return {'success': true};
      }
      return {'success': false, 'error': result['message'] ?? 'فشل نشر المنشور'};
    } catch (e) {
      return {'success': false, 'error': 'فشل نشر المنشور'};
    }
  }

  Future<Map<String, dynamic>> repostPost(String postId) async {
    if (!_authProvider.isAuthenticated) {
      return {'success': false, 'error': 'يجب تسجيل الدخول'};
    }
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.post('repost_post', {
        'user_id': userId,
        'post_id': postId,
      });

      if (result['success']) {
        await fetchPosts(); // Refresh feed to show repost
        return {'success': true};
      } else {
        return {'success': false, 'error': result['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'فشل إعادة نشر المنشور'};
    }
  }

  Future<void> markPostViewed(String postId) async {
    if (!_authProvider.isAuthenticated || _viewTrackedPostIds.contains(postId)) {
      return;
    }

    _viewTrackedPostIds.add(postId);
    final userId = _authProvider.user!['id'];

    try {
      final result = await ApiService.post('mark_view', {
        'user_id': userId,
        'post_id': postId,
      });

      if (result['success']) {
        final viewsCount = int.tryParse(result['views_count'].toString()) ?? 0;
        final postIndex = _posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final post = _posts[postIndex];
          _posts[postIndex] = Post(
            id: post.id,
            userId: post.userId,
            userName: post.userName,
            userPhoto: post.userPhoto,
            content: post.content,
            mediaUrl: post.mediaUrl,
            mediaType: post.mediaType,
            likes: post.likes,
            commentsCount: post.commentsCount,
            viewsCount: viewsCount,
            engagementScore: post.engagementScore,
            createdAt: post.createdAt,
            time: post.time,
            isLiked: post.isLiked,
            isSaved: post.isSaved,
            musicTitle: post.musicTitle,
            filterType: post.filterType,
            repostId: post.repostId,
          );
          notifyListeners();
        }
      } else {
        _viewTrackedPostIds.remove(postId);
      }
    } catch (_) {
      _viewTrackedPostIds.remove(postId);
    }
  }
}
