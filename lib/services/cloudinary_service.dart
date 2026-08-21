import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../constants.dart';

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;

  CloudinaryUploadResult({required this.secureUrl, required this.publicId});

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    return CloudinaryUploadResult(
      secureUrl: json['secure_url'] as String? ?? '',
      publicId: json['public_id'] as String? ?? '',
    );
  }
}

class CloudinaryService {
  /// Obtient une signature Cloudinary signée depuis le backend
  Future<Map<String, dynamic>?> _getUploadSignature({
    required String token,
    required String folder,
    String? publicId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/uploads/signature'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'folder': folder,
          if (publicId != null) 'publicId': publicId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>?;
      }
      print('⚠️ Error getting upload signature: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('⚠️ Error getting upload signature: $e');
      return null;
    }
  }

  /// Upload direct d'un fichier vers Cloudinary (contourne Vercel)
  Future<CloudinaryUploadResult?> uploadDirect({
    required String token,
    required File file,
    String folder = 'kivoo/items',
  }) async {
    try {
      // Obtenir la signature depuis le backend
      final signatureData = await _getUploadSignature(
        token: token,
        folder: folder,
      );

      if (signatureData == null) {
        throw Exception('Impossible d\'obtenir la signature Cloudinary');
      }

      final cloudName = signatureData['cloudName'] as String;
      final apiKey = signatureData['apiKey'] as String;
      final timestamp = signatureData['timestamp'].toString();
      final signature = signatureData['signature'] as String;

      // Upload direct vers Cloudinary
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      // Paramètres signés
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      request.fields['folder'] = folder;

      // Ajouter le fichier
      final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CloudinaryUploadResult.fromJson(data);
      }
      print('⚠️ Error uploading to Cloudinary: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('⚠️ Error uploading to Cloudinary: $e');
      return null;
    }
  }

  /// Upload multiple fichiers vers Cloudinary en parallèle
  Future<List<String>> uploadMultiple({
    required String token,
    required List<File> imageFiles,
    String folder = 'kivoo/items',
  }) async {
    final results = await Future.wait(
      imageFiles.map((file) => uploadDirect(token: token, file: file, folder: folder)),
    );

    return results
        .whereType<CloudinaryUploadResult>()
        .map((r) => r.secureUrl)
        .toList();
  }

  /// Upload direct pour la photo de profil
  Future<String?> uploadProfilePhoto({
    required String token,
    required File imageFile,
  }) async {
    final result = await uploadDirect(
      token: token,
      file: imageFile,
      folder: 'kivoo/profiles',
    );
    return result?.secureUrl;
  }
}