import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

/// Wrapper cross-platform (mobile + web) autour d'une image sélectionnée
/// avec l'ImagePicker.
///
/// - Les bytes sont lus une seule fois à la sélection puis réutilisés pour
///   la compression et l'upload multipart (`MultipartFile.fromBytes`).
/// - L'affichage passe par un `MemoryImage`, qui fonctionne à la fois sur
///   mobile et sur web.
///
/// Cette classe évite tout usage de `dart:io` (`File`), ce qui permet au
/// projet de compiler pour le web (PWA).
class PickedImage {
  PickedImage({required this.file, required this.bytes});

  final XFile file;
  final Uint8List bytes;

  /// Crée une [PickedImage] en lisant les bytes du fichier sélectionné.
  static Future<PickedImage> fromXFile(XFile file) async =>
      PickedImage(file: file, bytes: await file.readAsBytes());

  /// Charge plusieurs fichiers en parallèle.
  static Future<List<PickedImage>> fromXFiles(List<XFile> files) async =>
      Future.wait(files.map(fromXFile));

  /// ImageProvider cross-platform prêt à l'emploi pour un widget `Image`.
  ImageProvider get provider => MemoryImage(bytes);

  /// Nom du fichier (avec extension).
  String get name => file.name;

  /// Taille du fichier en octets.
  int get sizeInBytes => bytes.lengthInBytes;
}