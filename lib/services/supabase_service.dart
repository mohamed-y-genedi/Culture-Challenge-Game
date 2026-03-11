import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/room.dart';
import '../models/question.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Create a new room. Returns the generated room code on success, or null on failure.
  // Inserts into both 'rooms' and 'players' tables (relational schema).
  Future<String?> createRoom(String nickname, String category) async {
    const int maxRetries = 5;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final roomCode = _generateRoomCode();
      try {
        // Insert room into 'rooms' table
        await _client.from('rooms').insert({
          'room_code': roomCode,
          'player1_id': nickname,
          'host_nickname': nickname,
          'category': category,
        });

        // Insert host into 'players' table
        await _client.from('players').insert({
          'room_code': roomCode,
          'nickname': nickname,
          'score': 0,
        });

        return roomCode;
      } on PostgrestException catch (e) {
        // HTTP 409 Conflict / Postgres 23505 Unique Violation means the room code exists
        if (e.code == '23505') {
          debugPrint(
            'Room code conflict ($roomCode). Retrying... (${attempt + 1}/$maxRetries)',
          );
          continue; // Try again with a new generated code
        }

        debugPrint('PostgrestException (createRoom): ${e.message}');
        return null;
      } catch (e) {
        debugPrint('Exception (createRoom): $e');
        return null;
      }
    }

    // Checked out all retries
    debugPrint(
      'Failed to generate a unique room code after $maxRetries attempts.',
    );
    return null;
  }

  // Join an existing room. Returns true on success, false on failure.
  Future<bool> joinRoom(String roomCode, String nickname) async {
    try {
      final response = await _client
          .from('rooms')
          .select()
          .eq('room_code', roomCode)
          .maybeSingle();

      if (response == null) {
        debugPrint('joinRoom: room not found: $roomCode');
        return false;
      }

      final room = Room.fromJson(Map<String, dynamic>.from(response));
      if (room.player2 != null) {
        debugPrint('joinRoom: room full: $roomCode');
        return false;
      }

      await _client
          .from('rooms')
          .update({'player2_id': nickname, 'status': 'playing'})
          .eq('room_code', roomCode);

      return true;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (joinRoom): ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Exception (joinRoom): $e');
      return false;
    }
  }

  // Listen to room updates. Emits `Room?` and yields null when payload is invalid.
  Stream<Room?> streamRoom(String roomCode) {
    return _client
        .from('rooms')
        .stream(primaryKey: ['room_code'])
        .eq('room_code', roomCode)
        .map((payload) {
          try {
            if (payload.isNotEmpty) {
              return Room.fromJson(payload.first);
            }
          } catch (e) {
            debugPrint('streamRoom mapping error: $e');
          }
          return null;
        });
  }

  Future<List<Question>?> getQuestions(
    String category, {
    List<String> excludedIds = const [],
  }) async {
    try {
      var query = _client.from('questions').select().eq('category', category);

      if (excludedIds.isNotEmpty) {
        query = query.not('id', 'in', excludedIds);
      }

      final response = await query;

      final questions = List<Map<String, dynamic>>.from(
        response,
      ).map((json) => Question.fromJson(json)).toList();

      return questions;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (getQuestions): ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Exception (getQuestions): $e');
      return null;
    }
  }

  Future<List<Question>?> fetchQuestionsByCategory(
    String category, {
    List<String> excludedIds = const [],
  }) async {
    try {
      var query = _client.from('questions').select().eq('category', category);

      if (excludedIds.isNotEmpty) {
        query = query.not('id', 'in', excludedIds);
      }

      final response = await query;

      final questions = List<Map<String, dynamic>>.from(
        response,
      ).map((json) => Question.fromJson(json)).toList();

      return questions;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (fetchQuestionsByCategory): ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Exception (fetchQuestionsByCategory): $e');
      return null;
    }
  }

  // Update score. Returns true on success, false on failure.
  Future<bool> updateScore(
    String roomCode,
    int playerNumber,
    int newScore,
  ) async {
    final column = playerNumber == 1 ? 'p1_score' : 'p2_score';
    try {
      await _client
          .from('rooms')
          .update({column: newScore})
          .eq('room_code', roomCode);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (updateScore): ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Exception (updateScore): $e');
      return false;
    }
  }

  // Next question. Returns true on success, false on failure.
  Future<bool> nextQuestion(String roomCode, int currentIndex) async {
    try {
      await _client
          .from('rooms')
          .update({'current_q_index': currentIndex + 1})
          .eq('room_code', roomCode);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (nextQuestion): ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Exception (nextQuestion): $e');
      return false;
    }
  }

  // Finish game. Returns true on success, false on failure.
  Future<bool> finishGame(String roomCode) async {
    try {
      await _client
          .from('rooms')
          .update({'status': 'finished'})
          .eq('room_code', roomCode);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (finishGame): ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Exception (finishGame): $e');
      return false;
    }
  }

  // Start game (set status to 'playing'). Returns true on success.
  Future<bool> startGame(String roomCode) async {
    try {
      await _client
          .from('rooms')
          .update({'status': 'playing'})
          .eq('room_code', roomCode);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (startGame): ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Exception (startGame): $e');
      return false;
    }
  }

  // Upsert user score into leaderboard. Supabase handles the check if high_score > existing.
  // Assuming the table is 'leaderboard' with columns: nickname (PK), high_score.
  Future<bool> updateLeaderboard(String nickname, int score) async {
    try {
      // First, fetch current score to see if we need an update
      final response = await _client
          .from('leaderboard')
          .select('high_score')
          .eq('nickname', nickname)
          .maybeSingle();

      if (response != null) {
        final currentHighScore = response['high_score'] as int? ?? 0;
        if (score <= currentHighScore) {
          return true; // No need to update, existing score is higher or equal
        }
      }

      // Upsert the new higher score
      await _client.from('leaderboard').upsert({
        'nickname': nickname,
        'high_score': score,
      });
      return true;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (updateLeaderboard): ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Exception (updateLeaderboard): $e');
      return false;
    }
  }

  // Fetch top 10 players
  Future<List<Map<String, dynamic>>?> getLeaderboard() async {
    try {
      final response = await _client
          .from('leaderboard')
          .select()
          .order('high_score', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (getLeaderboard): ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Exception (getLeaderboard): $e');
      return null;
    }
  }

  // Fetch OTA App Settings
  Future<Map<String, dynamic>?> getAppSettings() async {
    try {
      final response = await _client
          .from('app_settings')
          .select()
          .limit(1)
          .maybeSingle();
      return response;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (getAppSettings): ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Exception (getAppSettings): $e');
      return null;
    }
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        5,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}
