import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/room.dart';
import '../models/question.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Create a new room. Returns the generated room code on success, or null on failure.
  // Inserts into both 'rooms' and 'players' tables (relational schema).
  Future<String?> createRoom(
    String nickname,
    String category, {
    int maxPlayers = 2,
    String gameMode = 'ffa',
  }) async {
    const int maxRetries = 5;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final roomCode = _generateRoomCode();
      try {
        final hostPlayerMap = <String, dynamic>{
          'score': 0,
          'has_answered': false,
        };

        if (gameMode == 'teams') {
          hostPlayerMap['team'] = 1;
        }

        // Insert room into 'rooms' table with new JSONB structure
        await _client.from('rooms').insert({
          'room_code': roomCode,
          'host_nickname': nickname,
          'category': category,
          'max_players': maxPlayers,
          'game_mode': gameMode,
          'players': {nickname: hostPlayerMap},
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
      // Check if room is full
      if (room.players.length >= room.maxPlayers) {
        debugPrint('joinRoom: room full: $roomCode');
        return false;
      }

      // Check if user is already in the room
      if (room.players.containsKey(nickname)) {
        return true;
      }

      final currentPlayers = Map<String, dynamic>.from(room.players);

      final playerMap = <String, dynamic>{'score': 0, 'has_answered': false};

      if (room.gameMode == 'teams') {
        playerMap['team'] = (currentPlayers.length % 2 == 0) ? 1 : 2;
      }

      currentPlayers[nickname] = playerMap;

      await _client
          .from('rooms')
          .update({'players': currentPlayers})
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

  // Save the shuffled questions to the room so all players use exactly the same set.
  Future<bool> saveRoomQuestions(
    String roomCode,
    List<Map<String, dynamic>> questions,
  ) async {
    try {
      await _client
          .from('rooms')
          .update({'questions': questions})
          .eq('room_code', roomCode);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException (saveRoomQuestions): ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Exception (saveRoomQuestions): $e');
      return false;
    }
  }

  // Update score and answer state
  Future<bool> updateScore(
    String roomCode,
    String nickname,
    int newScore,
  ) async {
    try {
      final response = await _client
          .from('rooms')
          .select('players')
          .eq('room_code', roomCode)
          .single();
      final players = Map<String, dynamic>.from(response['players'] ?? {});

      if (players.containsKey(nickname)) {
        players[nickname]['score'] = newScore;
        players[nickname]['has_answered'] = true;
      }

      await _client
          .from('rooms')
          .update({'players': players})
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
      final response = await _client
          .from('rooms')
          .select('players')
          .eq('room_code', roomCode)
          .single();
      final players = Map<String, dynamic>.from(response['players'] ?? {});
      for (var key in players.keys) {
        players[key]['has_answered'] = false;
      }

      await _client
          .from('rooms')
          .update({'current_q_index': currentIndex + 1, 'players': players})
          .eq('room_code', roomCode)
          .eq(
            'current_q_index',
            currentIndex,
          ); // Atomic lock: Only update if no one else has updated it yet
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
