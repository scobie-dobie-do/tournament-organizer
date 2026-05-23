import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  Future<String?> downloadLogo(String url, String filename) async {
    try {
      final logosDir = await _getLogosDirectory();
      // Ensure file extension is correct (.png)
      final cleanFilename = filename.endsWith('.png') ? filename : '$filename.png';
      final file = File('${logosDir.path}/$cleanFilename');

      // If file already exists, return its path without downloading again
      if (await file.exists()) {
        return file.path;
      }

      debugPrint('Downloading logo from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('Logo downloaded and saved to: ${file.path}');
        return file.path;
      } else {
        debugPrint('Failed to download logo. HTTP status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading logo: $e');
      return null;
    }
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
