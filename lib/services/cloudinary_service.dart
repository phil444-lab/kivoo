import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../constants.dart';
import '../utils/picked_image.dart';
import 'image_compression_service.dart';

/// Résultat d'un upload Cloudinary
class CloudinaryUploadResult {

  CloudinaryUploadResult({required this.secureUrl, required this.publicId});

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    return CloudinaryUploadResult(
      secureUrl: json['secure_url'] as String? ?? '',
      publicId: json['public_id'] as String? ?? '',
    );
  }
  final String secureUrl;
  final String publicId;
}

/// Exception personnalisée pour les erreurs d'upload Cloudinary
class CloudinaryUploadException implements Exception {

  CloudinaryUploadException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class CloudinaryService {
  /// Taille maximale autorisée par Cloudinary (10 Mo pour le plan gratuit)
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 Mo

  /// Service de compression d'images
  final ImageCompressionService _compressionService = ImageCompressionService();

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

  /// Vérifie la taille d'une image avant l'upload
  void _validateFileSize(int fileSize, String fileName) {
    if (fileSize > maxFileSizeBytes) {
      final sizeInMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      throw CloudinaryUploadException(
        'L\'image "$fileName" fait $sizeInMB Mo. '
        'La taille maximale autorisée est de 10 Mo par image. '
        'Veuillez compresser l\'image ou en choisir une plus petite.',
      );
    }
  }

  /// Analyse la réponse d'erreur Cloudinary pour extraire un message clair
  String _parseCloudinaryError(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final error = data['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? '';

      // Messages d'erreur Cloudinary courants
      if (message.contains('File size too large') || message.contains('too large')) {
        return 'L\'image dépasse la taille maximale autorisée par Cloudinary (10 Mo). '
            'Veuillez compresser l\'image ou en choisir une plus petite.';
      }
      if (message.contains('Invalid file type') || message.contains('not allowed')) {
        return 'Le format de l\'image n\'est pas autorisé. '
            'Utilisez un format JPEG, PNG, WebP ou GIF.';
      }
      if (message.contains('Invalid signature') || message.contains('signature')) {
        return 'La signature Cloudinary a expiré. Veuillez réessayer.';
      }
      if (message.contains('Upload preset') || message.contains('preset')) {
        return 'Configuration d\'upload invalide. Veuillez réessayer plus tard.';
      }
      if (message.contains('Rate limit') || message.contains('too many')) {
        return 'Trop de requêtes envoyées. Veuillez patienter quelques secondes et réessayer.';
      }
      if (message.contains('timed out') || message.contains('timeout')) {
        return 'Le téléversement a expiré. Vérifiez votre connexion internet et réessayez.';
      }

      // Message générique avec le détail Cloudinary
      return 'Erreur lors de l\'upload de l\'image : $message';
    } catch (_) {
      return 'Erreur lors de l\'upload de l\'image. Veuillez réessayer.';
    }
  }

  /// Upload direct d'une image vers Cloudinary (contourne Vercel)
  ///
  /// Cross-platform (mobile + web) : compression + upload basés sur les
  /// bytes de la [PickedImage] (aucun usage de `dart:io`).
  Future<CloudinaryUploadResult?> uploadDirect({
    required String token,
    required PickedImage image,
    String folder = 'kivoo/items',
  }) async {
    try {
      // Compresser l'image avant l'upload (réduit la taille sans altérer la qualité)
      final compressedBytes = await _compressionService.compressBytes(image.bytes);

      // Vérifier la taille de l'image après compression
      _validateFileSize(compressedBytes.length, image.name);

      // Obtenir la signature depuis le backend
      final signatureData = await _getUploadSignature(
        token: token,
        folder: folder,
      );

      if (signatureData == null) {
        throw CloudinaryUploadException(
          'Impossible d\'obtenir la signature Cloudinary. '
          'Vérifiez votre connexion internet et réessayez.',
        );
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

      // Ajouter le fichier compressé (cross-platform : fromBytes)
      final mimeType = lookupMimeType(image.name, headerBytes: compressedBytes) ?? 'image/jpeg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          compressedBytes,
          filename: image.name,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CloudinaryUploadResult.fromJson(data);
      }

      // Gérer les erreurs Cloudinary avec un message personnalisé
      final errorMessage = _parseCloudinaryError(response);
      print('⚠️ Error uploading to Cloudinary: ${response.statusCode} - $errorMessage');
      throw CloudinaryUploadException(errorMessage, statusCode: response.statusCode);
    } on CloudinaryUploadException {
      rethrow;
    } on http.ClientException {
      throw CloudinaryUploadException(
        'Connexion internet instable. Vérifiez votre connexion et réessayez.',
      );
    } catch (e) {
      print('⚠️ Error uploading to Cloudinary: $e');
      throw CloudinaryUploadException(
        'Erreur inattendue lors de l\'upload de l\'image. Veuillez réessayer.',
      );
    }
  }

  /// Upload multiple d'images vers Cloudinary en parallèle
  /// Retourne les URLs des images uploadées avec succès
  Future<List<String>> uploadMultiple({
    required String token,
    required List<PickedImage> images,
    String folder = 'kivoo/items',
  }) async {
    final results = await Future.wait(
      images.map((image) => uploadDirect(token: token, image: image, folder: folder)),
    );

    return results
        .whereType<CloudinaryUploadResult>()
        .map((r) => r.secureUrl)
        .toList();
  }

  /// Upload direct pour la photo de profil
  Future<String?> uploadProfilePhoto({
    required String token,
    required PickedImage image,
  }) async {
    final result = await uploadDirect(
      token: token,
      image: image,
      folder: 'kivoo/profiles',
    );
    return result?.secureUrl;
  }
}