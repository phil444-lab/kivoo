import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Service de compression d'images avant upload vers Cloudinary.
///
/// Version cross-platform (mobile + web) : travaille uniquement sur des
/// `Uint8List` via `FlutterImageCompress.compressWithList`, supporté à la
/// fois sur mobile et sur web (encoder `flutter_image_compress_web`).
/// Aucun usage de `dart:io`, compatible PWA.
class ImageCompressionService {
  /// Taille maximale cible après compression (en octets)
  static const int targetMaxSizeBytes = 2 * 1024 * 1024; // 2 Mo

  /// Qualité JPEG de compression (0-100)
  static const int quality = 80;

  /// Largeur maximale de l'image (préserve la qualité pour l'affichage mobile)
  static const int maxWidth = 1920;

  /// Compresse les bytes d'une image et retourne le résultat compressé.
  /// Si l'image est déjà petite, ou en cas d'erreur, les bytes originaux
  /// sont retournés tels quels.
  Future<Uint8List> compressBytes(Uint8List bytes) async {
    try {
      // Si l'image est déjà sous la taille cible, ne pas la compresser
      if (bytes.lengthInBytes <= targetMaxSizeBytes) {
        return bytes;
      }

      final result = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxWidth,
        format: CompressFormat.jpeg,
      );

      // Vérifier que la compression a bien réduit la taille
      if (result.isNotEmpty && result.lengthInBytes < bytes.lengthInBytes) {
        return result;
      }

      // Si la compression n'a pas aidé, retourner les bytes originaux
      return bytes;
    } catch (e) {
      print('⚠️ Error compressing image: $e');
      return bytes;
    }
  }

  /// Compresse une liste d'images en parallèle
  Future<List<Uint8List>> compressImages(List<Uint8List> bytesList) async {
    final results = await Future.wait(
      bytesList.map(compressBytes),
    );
    return results;
  }
}