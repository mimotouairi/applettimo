import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class ApiService {
  // 📝 رابط السيرفر المرفوع على Render
  static const String hostIp = 'let-backend.onrender.com'; 

  static String get baseUrl => 'https://$hostIp/api';
  static String get baseMediaUrl => 'https://$hostIp';

  static String? getImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    if (url.startsWith('http')) {
      return url;
    }

    // Handles relative paths from the new server
    final cleanPath = url.startsWith('/') ? url.substring(1) : url;
    return '$baseMediaUrl/$cleanPath';
  }

  static String _mapEndpoint(String fullEndpoint) {
    String endpointPart = fullEndpoint;
    String queryString = '';

    if (fullEndpoint.contains('?')) {
      final parts = fullEndpoint.split('?');
      endpointPart = parts[0];
      queryString = '?${parts[1]}';
    }

    // Clean .php extensions if they exist
    String mapped = endpointPart.replaceAll('.php', '');
    
    // Check for each controller category mapping for NestJS
    if (mapped == 'login' || mapped == 'register' || mapped == 'update_profile' || mapped == 'update_profile_v2' || mapped == 'switch_account') {
      mapped = 'auth/$mapped';
    } else if (['get_posts', 'get_post', 'create_post', 'create_post_multi', 'toggle_like', 'delete_post', 'toggle_save', 'get_saved_posts', 'get_videos', 'repost_post', 'mark_view'].contains(mapped)) {
      mapped = 'posts/$mapped';
    } else if (['get_user_profile', 'toggle_follow', 'search_users', 'get_suggested_users', 'get_user_stats', 'get_notifications', 'mark_notification_read', 'mark_all_notifications_read'].contains(mapped)) {
      mapped = 'users/$mapped';
    } else if (['get_stories', 'add_story', 'toggle_story_like', 'mark_story_viewed'].contains(mapped)) {
      mapped = 'stories/$mapped';
    } else if (['get_conversations', 'get_messages', 'send_message'].contains(mapped)) {
      mapped = 'chat/$mapped';
    } else if (['get_comments', 'add_comment', 'toggle_comment_like'].contains(mapped)) {
      mapped = 'comments/$mapped';
    }

    return '$mapped$queryString';
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, {File? file, String fileField = 'media'}) async {
    try {
      final mappedEndpoint = _mapEndpoint(endpoint);
      final url = Uri.parse('$baseUrl/$mappedEndpoint');
      
      if (kDebugMode) {
        print('📡 API POST: $url');
        print('📦 Payload: ${jsonEncode(data)}');
      }

      if (file != null) {
        final request = http.MultipartRequest('POST', url);
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        final fileExtension = path.extension(file.path).toLowerCase();
        final mimeType = _getMimeType(fileExtension);
        request.files.add(
          await http.MultipartFile.fromPath(
            fileField,
            file.path,
            contentType: MediaType.parse(mimeType),
          ),
        );

        // Increased timeout for file uploads to 5 minutes
        final streamedResponse = await request.send().timeout(const Duration(seconds: 300));
        final response = await http.Response.fromStream(streamedResponse);
        return _handleResponse(response, endpoint);
      } else {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(data),
        ).timeout(const Duration(seconds: 60));
        return _handleResponse(response, endpoint);
      }
    } catch (e) {
      if (kDebugMode) print('❌ API POST Error: $e');
      return {'success': false, 'message': 'فشل الاتصال بالخادم: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, dynamic> data, {
    List<File> files = const [],
    String fileField = 'media',
  }) async {
    try {
      final mappedEndpoint = _mapEndpoint(endpoint);
      final url = Uri.parse('$baseUrl/$mappedEndpoint');
      if (kDebugMode) print('📡 API POST (Multi): $url');

      final request = http.MultipartRequest('POST', url);
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      for (final file in files) {
        final fileExtension = path.extension(file.path).toLowerCase();
        final mimeType = _getMimeType(fileExtension);
        request.files.add(
          await http.MultipartFile.fromPath(
            fileField,
            file.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      // Increased timeout for file uploads to 5 minutes
      final streamedResponse = await request.send().timeout(const Duration(seconds: 300));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, endpoint);
    } catch (e) {
      if (kDebugMode) print('❌ API POST (Multi) Error: $e');
      return {'success': false, 'message': 'فشل الاتصال بالخادم: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final mappedEndpoint = _mapEndpoint(endpoint);
      final url = Uri.parse('$baseUrl/$mappedEndpoint');
      if (kDebugMode) print('📡 API GET: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 60));
      return _handleResponse(response, endpoint);
    } catch (e) {
      if (kDebugMode) print('❌ API GET Error: $e');
      return {'success': false, 'message': 'فشل الاتصال بالخادم: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> upload(String endpoint, File file, {String fieldName = 'media'}) async {
    try {
      final mappedEndpoint = _mapEndpoint(endpoint);
      final url = Uri.parse('$baseUrl/$mappedEndpoint');
      if (kDebugMode) print('📡 API UPLOAD: $url');

      final request = http.MultipartRequest('POST', url);
      
      final fileExtension = path.extension(file.path).toLowerCase();
      final mimeType = _getMimeType(fileExtension);

      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Increased timeout to 5 minutes for direct uploads
      final streamedResponse = await request.send().timeout(const Duration(seconds: 300));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response, endpoint);
    } catch (e) {
      if (kDebugMode) print('❌ API UPLOAD Error: $e');
      return {'success': false, 'message': 'فشل رفع الملف: ${e.toString()}'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response, String endpoint) {
    if (kDebugMode) {
      print('📥 Response from $endpoint: [${response.statusCode}]');
      print('📄 Body: ${response.body}');
    }
    final responseBody = response.body;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(responseBody);
      } catch (e) {
        if (kDebugMode) print('❌ JSON Decode Error: $e');
        return {'success': false, 'message': 'خطأ في تحليل البيانات من السيرفر'};
      }
    } else {
      return {
        'success': false,
        'message': 'خطأ من السيرفر (${response.statusCode})',
        'statusCode': response.statusCode
      };
    }
  }

  static String _getMimeType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.mkv':
        return 'video/x-matroska';
      case '.webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }
}
