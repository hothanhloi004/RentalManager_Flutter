import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImgBBService {
  static const String _apiKey = '7b1b32a85809c2e714b2d44b72a0f934'; // API Key cu t? Android

  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = _apiKey;

      final bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name.isEmpty ? 'upload.jpg' : imageFile.name,
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final json = jsonDecode(responseData);
        return json['data']['url'];
      }
    } catch (e) {
      debugPrint('ImgBB Upload Error: $e');
    }
    return null;
  }
}

