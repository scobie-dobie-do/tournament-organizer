import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class LogoStorageService {
  static final LogoStorageService _instance = LogoStorageService._internal();
  factory LogoStorageService() => _instance;
  LogoStorageService._internal();

  Future<Directory> _getLogosDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final logosDir = Directory('${docDir.path}/logos');
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }
    return logosDir;
  }

  Future<String?> importLogoFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return null;

      final logosDir = await _getLogosDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String newPath = '${logosDir.path}/custom_$timestamp.png';

      final File localFile = File(image.path);
      final File savedFile = await localFile.copy(newPath);

      debugPrint('Custom logo imported and saved to: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      debugPrint('Error importing logo from gallery: $e');
      return null;
    }
  }
}
