import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class LogoSearchResult {
  final String categoryId;
  final String categoryName;
  final String id;
  final String name;
  final List<String> altNames;
  final String hash;

  LogoSearchResult({
    required this.categoryId,
    required this.categoryName,
    required this.id,
    required this.name,
    required this.altNames,
    required this.hash,
  });

  factory LogoSearchResult.fromJson(Map<String, dynamic> json) {
    return LogoSearchResult(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      id: json['id'] as String,
      name: json['name'] as String,
      altNames: List<String>.from(json['altNames'] ?? []),
      hash: json['h'] as String,
    );
  }

  String get logoUrl {
    // 256x256 standard size. Extract hash suffix for 256x256 from indices 9 to 17
    final String hash256 = hash.length >= 17 ? hash.substring(9, 17) : hash;
    return 'https://assets.football-logos.cc/logos/$categoryId/256x256/$id.$hash256.png';
  }
}

class LogoService {
  static final LogoService _instance = LogoService._internal();
  factory LogoService() => _instance;
  LogoService._internal();

  List<LogoSearchResult> _cachedLogos = [];
  Future<void>? _initFuture;

  Future<void> init() {
    _initFuture ??= _loadOrFetchAutocompleteData();
    return _initFuture!;
  }

  Future<void> _loadOrFetchAutocompleteData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/logos_ac.json');

      bool shouldFetch = true;
      if (await file.exists()) {
        final lastModified = await file.lastModified();
        final difference = DateTime.now().difference(lastModified);
        // Only fetch from network if cached file is older than 7 days
        if (difference.inDays < 7) {
          shouldFetch = false;
        }
      }

      String jsonContent;
      if (shouldFetch) {
        try {
          debugPrint('Fetching ac.json from football-logos.cc...');
          final response = await http.get(
            Uri.parse('https://football-logos.cc/ac.json'),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          );
          if (response.statusCode == 200) {
            jsonContent = response.body;
            // Validate it is valid JSON list before writing
            final decoded = jsonDecode(jsonContent);
            if (decoded is List) {
              await file.writeAsString(jsonContent);
              debugPrint('ac.json fetched and cached successfully.');
            } else {
              throw Exception('Invalid JSON format: expected List');
            }
          } else {
            throw Exception('Failed to fetch autocomplete index from server (HTTP ${response.statusCode})');
          }
        } catch (e) {
          debugPrint('Failed to fetch from network, attempting to read cache: $e');
          if (await file.exists()) {
            jsonContent = await file.readAsString();
          } else {
            rethrow;
          }
        }
      } else {
        debugPrint('Loading ac.json from local cache...');
        jsonContent = await file.readAsString();
      }

      final List<dynamic> jsonList = jsonDecode(jsonContent);
      _cachedLogos = jsonList.map((json) => LogoSearchResult.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading autocomplete data: $e');
      _initFuture = null; // reset so it can be retried
      rethrow;
    }
  }

  Future<List<LogoSearchResult>> searchLogos(String query) async {
    await init();
    if (query.trim().isEmpty) {
      // Return a set of default entries when query is empty
      return _cachedLogos.take(60).toList();
    }

    final lowercaseQuery = query.toLowerCase().trim();
    return _cachedLogos.where((logo) {
      if (logo.name.toLowerCase().contains(lowercaseQuery)) return true;
      if (logo.id.toLowerCase().contains(lowercaseQuery)) return true;
      if (logo.categoryName.toLowerCase().contains(lowercaseQuery)) return true;
      if (logo.altNames.any((alt) => alt.toLowerCase().contains(lowercaseQuery))) return true;
      return false;
    }).toList();
  }
}
