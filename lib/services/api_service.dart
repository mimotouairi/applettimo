import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class ApiService {
  // 📝 ادخل عنوان الـ IP الخاص بجهاز الكمبيوتر هنا (مثلاً 192.168.1.5)
  // يمكنك معرفته من خلال كتابة 'ipconfig' في الـ Terminal الخاص بالكمبيوتر
  static const String hostIp = '192.168.100.9'; 

  static String get baseUrl {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'http://$hostIp:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  static String get baseMediaUrl {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'http://$hostIp:3000';
    } else {
      return 'http://localhost:3000';
    }
  }

  static String? getImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    if (url.startsWith('http')) {
      // If the URL already contains the wrong hostIp format, fix it
      if (url.contains('$hostIp-3000')) {
        return url.replaceFirst('$hostIp-3000', '$hostIp:3000');
      }
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
    if (mapped == 'login' || mapped == 'register') {
      mapped = 'auth/$mapped';
    } else if (['get_posts', 'create_post', 'toggle_like', 'delete_post', 'toggle_save', 'get_saved_posts', 'get_videos', 'repost_post'].contains(mapped)) {
      mapped = 'posts/$mapped';
    } else if (['get_user_profile', 'toggle_follow', 'search_users', 'get_suggested_users', 'get_user_stats'].contains(mapped)) {
      mapped = 'users/$mapped';
    } else if (['get_stories', 'add_story', 'toggle_story_like', 'mark_story_viewed'].contains(mapped)) {
      mapped = 'stories/$mapped';
    } else if (['get_conversations', 'get_messages', 'send_message'].contains(mapped)) {
      mapped = 'chat/$mapped';
    } else if (['get_comments', 'add_comment'].contains(mapped)) {
      mapped = 'comments/$mapped';
    }

    return '$mapped$queryString';
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, {File? file, String fileField = 'media'}) async {
    try {
      final mappedEndpoint = _mapEndpoint(endpoint);
      if (file != null) {
        final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/$mappedEndpoint'));
        
        // Add data as fields
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        // Add file
        final fileExtension = path.extension(file.path).toLowerCase();
        final mimeType = _getMimeType(fileExtension);
        request.files.add(
          await http.MultipartFile.fromPath(
            fileField,
            file.path,
            contentType: MediaType.parse(mimeType),
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        return _handleResponse(response, endpoint);
      } else {
        final response = await http.post(
          Uri.parse('$baseUrl/$mappedEndpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(data),
        );
        return _handleResponse(response, endpoint);
      }
    } catch (e) {
      return {'success': false, 'message': 'فشل الاتصال بالخادم: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final mappedEndpoint = _mapEndpoint(endpoint);
      final response = await http.get(Uri.parse('$baseUrl/$mappedEndpoint'));
      return _handleResponse(response, endpoint);
    } catch (e) {
      return {'success': false, 'message': 'فشل الاتصال بالخادم: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> upload(String endpoint, File file, {String fieldName = 'media'}) async {
    try {
      final mappedEndpoint = _mapEndpoint(endpoint);
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/$mappedEndpoint'));
      
      final fileExtension = path.extension(file.path).toLowerCase();
      final mimeType = _getMimeType(fileExtension);

      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response, endpoint);
    } catch (e) {
      return {'success': false, 'message': 'فشل رفع الملف: ${e.toString()}'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response, String endpoint) {
    final responseBody = response.body;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(responseBody);
      } catch (e) {
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
