import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../logic/tournament_logic.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _boxName = 'tournaments_v1';
  late Box<String> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<void> saveTournament(TournamentState state) async {
    try {
      final jsonStr = jsonEncode(state.toJson());
      await _box.put(state.id, jsonStr);
    } catch (e) {
      // Gracefully handle serialization errors if any
      debugPrint("Database Error saving tournament: $e");
    }
  }

  TournamentState? loadTournament(String id) {
    final jsonStr = _box.get(id);
    if (jsonStr == null) return null;
    try {
      return TournamentState.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (e) {
      debugPrint("Database Error loading tournament $id: $e");
      return null;
    }
  }

  List<TournamentState> getAllTournaments() {
    try {
      final list = _box.values.map((jsonStr) {
        return TournamentState.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      }).toList();

      // Sort by creation date descending (newest first)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint("Database Error fetching tournaments: $e");
      return [];
    }
  }

  Future<void> deleteTournament(String id) async {
    await _box.delete(id);
  }
}
