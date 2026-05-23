import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tournament_organizer/services/logo_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup mock path provider platform channel handler
  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (MethodCall methodCall) async {
      return '.'; // Return current directory for mock path
    },
  );

  tearDown(() async {
    // Cleanup temporary files created during testing
    final file = File('./logos_ac.json');
    if (await file.exists()) {
      await file.delete();
    }
  });

  test('Test LogoSearchResult model parsing and URL builder', () {
    final result = LogoSearchResult(
      categoryId: 'italy',
      categoryName: 'Italy',
      id: 'juventus',
      name: 'Juventus',
      altNames: ['Juve'],
      hash: '0d7288ed1a8baf848563bac23ad61748086191d309408e035f443cb4efced70a8f3e0e7',
    );

    expect(result.logoUrl, 'https://assets.football-logos.cc/logos/italy/256x256/juventus.a8baf848.png');
  });

  test('Test LogoService offline caching and search fallback', () async {
    final file = File('./logos_ac.json');
    final mockJson = [
      {
        'categoryId': 'italy',
        'categoryName': 'Italy',
        'id': 'juventus',
        'name': 'Juventus',
        'altNames': ['Juve'],
        'h': '0d7288ed1a8baf848563bac23ad61748086191d309408e035f443cb4efced70a8f3e0e7',
      },
      {
        'categoryId': 'england',
        'categoryName': 'England',
        'id': 'arsenal',
        'name': 'Arsenal',
        'altNames': ['The Gunners'],
        'h': '18ac9dce1a6abf3e7042846fc1f018f604104ccf0f1dede1c922a9c709024b0451c4b420',
      }
    ];
    await file.writeAsString(jsonEncode(mockJson));

    final logoService = LogoService();
    final results = await logoService.searchLogos('Gunners');
    
    expect(results, isNotEmpty);
    expect(results.first.id, 'arsenal');
    expect(results.first.logoUrl, contains('https://assets.football-logos.cc/logos/england/256x256/arsenal.'));
  });
}
