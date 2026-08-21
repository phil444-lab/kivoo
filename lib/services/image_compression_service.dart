import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service de compression d'images avant upload vers Cloudinary
/// Utilise flutter_image_compress pour réduire la taille sans altérer la qualité visuelle
class ImageCompressionService {
  /// Taille maximale cible après compression (en octets)
  static const int targetMaxSizeBytes = 2 * 1024 * 1024; // 2 Mo

  /// Qualité JPEG de compression (0-100)
  static const int quality = 80;

  /// Largeur maximale de l'image (préserve la qualité pour l'affichage mobile)
  static const int maxWidth = 1920;

  /// Compresse une image et retourne le fichier compressé
  /// Si l'image est déjà petite, elle est retournée telle quelle
  Future<File> compressImage(File file) async {
    try {
      // Si l'image est déjà sous la taille cible, ne pas la compresser
      if (file.lengthSync() <= targetMaxSizeBytes) {
        return file;
      }

      // Obtenir le répertoire temporaire
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(file.path);
      final outputPath = path.join(tempDir.path, '${fileName}_compressed.jpg');

      // Compresser l'image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        outputPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxWidth,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        if (await compressedFile.exists()) {
          // Vérifier que la compression a bien réduit la taille
          if (compressedFile.lengthSync() < file.lengthSync()) {
            return compressedFile;
          }
        }
      }

      // Si la compression n'a pas aidé, retourner le fichier original
      return file;
    } catch (e) {
      print('⚠️ Error compressing image: $e');
      return file;
    }
  }

  /// Compresse une liste d'images en parallèle
  Future<List<File>> compressImages(List<File> files) async {
    final results = await Future.wait(
      files.map((file) => compressImage(file)),
    );
    return results;
  }

  /// Compresse une image et retourne les bytes compressés
  Future<Uint8List?> compressImageToBytes(File file) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        file.path,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxWidth,
        format: CompressFormat.jpeg,
      );
    } catch (e) {
      print('⚠️ Error compressing image to bytes: $e');
      return null;
    }
  }
}