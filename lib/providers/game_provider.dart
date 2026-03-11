import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/room.dart';
import '../models/question.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _nickname;
  String? _roomCode;
  Room? _room;
  List<Question> _questions = [];
  bool _isLoading = false; // public state exposed via getter
  String? _errorMessage;
  StreamSubscription<Room?>? _roomSubscription;
  bool _isSinglePlayer = false;
  List<Question> _currentQuestions = [];
  int _currentQuestionIndex = 0;
  int _singlePlayerScore = 0;

  // Lifelines state
  bool _fiftyFiftyUsed = false;
  bool _askAudienceUsed = false;

  // Getters
  String? get nickname => _nickname;
  String? get roomCode => _roomCode;
  Room? get room => _room;
  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isPlayer1 => _room?.player1 == _nickname;
  bool get isSinglePlayer => _isSinglePlayer;
  List<Question> get currentQuestions => _currentQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get singlePlayerScore => _singlePlayerScore;

  bool get fiftyFiftyUsed => _fiftyFiftyUsed;
  bool get askAudienceUsed => _askAudienceUsed;

  void useFiftyFifty() {
    _fiftyFiftyUsed = true;
    notifyListeners();
  }

  void useAskAudience() {
    _askAudienceUsed = true;
    notifyListeners();
  }

  void setNickname(String name) {
    _nickname = name;
    notifyListeners();
  }

  void setSinglePlayerMode(bool isSingle) {
    _isSinglePlayer = isSingle;
    notifyListeners();
  }

  Future<void> _playSound(bool isCorrect) async {
    try {
      final soundPath = isCorrect ? 'sounds/correct.mp3' : 'sounds/wrong.mp3';
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  // Create Room
  Future<bool> createRoom(String category) async {
    if (_nickname == null || _nickname!.isEmpty) {
      _errorMessage = 'Nickname is required';
      notifyListeners();
      return false;
    }

    // Prepare UI state
    _errorMessage = null;
    _setLoading(true);

    try {
      final code = await _service.createRoom(_nickname!, category);
      if (code == null) {
        _errorMessage = 'Failed to create room. Please try again.';
        _setLoading(false);
        return false;
      }

      _roomCode = code;
      _subscribeToRoom();

      // Pre-fetch questions locally so they are ready
      await _fetchQuestions(category);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Unexpected error creating room. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // Join Room
  Future<bool> joinRoom(String code) async {
    if (_nickname == null || _nickname!.isEmpty) {
      _errorMessage = 'Nickname is required';
      notifyListeners();
      return false;
    }

    // Prepare UI state
    _errorMessage = null;
    _setLoading(true);

    try {
      final success = await _service.joinRoom(code, _nickname!);
      if (!success) {
        _errorMessage =
            'Failed to join room. Please check the code and try again.';
        _setLoading(false);
        return false;
      }

      _roomCode = code;
      _subscribeToRoom();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Unexpected error joining room. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  void _subscribeToRoom() {
    // Cancel any existing subscription
    _roomSubscription?.cancel();

    if (_roomCode == null) return;

    _roomSubscription = _service
        .streamRoom(_roomCode!)
        .listen(
          (updatedRoom) {
            // Handle null emissions safely
            if (updatedRoom == null) {
              debugPrint('streamRoom emitted null for room $_roomCode');
              return;
            }

            // Check if the game just finished
            if (updatedRoom.status == 'finished' &&
                _room?.status != 'finished') {
              // The game just finished. Update leaderboard for exactly this client.
              final myScore = isPlayer1
                  ? updatedRoom.p1Score
                  : updatedRoom.p2Score;
              final myName =
                  _nickname ??
                  (isPlayer1 ? updatedRoom.player1 : updatedRoom.player2);
              if (myName != null) {
                _service.updateLeaderboard(myName, myScore);
              }
            }

            _room = updatedRoom;

            // If we joined and don't have questions yet, fetch them
            if (_questions.isEmpty && updatedRoom.category.isNotEmpty) {
              _fetchQuestions(updatedRoom.category);
            }

            notifyListeners();
          },
          onError: (e) {
            _errorMessage = 'Realtime connection error';
            notifyListeners();
          },
        );
  }

  Future<List<String>> _getSeenQuestionIds(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'seen_ids_$category';
    final List<String>? seenStr = prefs.getStringList(key);
    return seenStr ?? [];
  }

  // Append new question IDs to existing ones stored in SharedPreferences
  Future<void> _saveSeenQuestionIds(
    String category,
    List<String> newIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'seen_ids_$category';

    // Read old list
    final existingIds = prefs.getStringList(key) ?? [];

    // Combine arrays making sure there are no duplicates inside
    final combinedIds = {...existingIds, ...newIds}.toList();

    await prefs.setStringList(key, combinedIds);
  }

  Future<void> _clearSeenQuestionIds(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'seen_ids_$category';
    await prefs.remove(key);
  }

  Future<void> _fetchQuestions(String category) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // 1. Read memory
      List<String> seenIds = await _getSeenQuestionIds(category);
      debugPrint('DEBUG: Seen IDs for $category: ${seenIds.length}');

      // 2. Fetch All Unseen
      List<Question>? result = await _service.fetchQuestionsByCategory(
        category,
        excludedIds: seenIds,
      );

      // 3. Fallback Reset
      if (result == null || result.length < 15) {
        debugPrint(
          'DEBUG: Not enough unseen questions. Clearing memory for $category.',
        );
        await _clearSeenQuestionIds(category);
        seenIds = [];
        result = await _service.fetchQuestionsByCategory(
          category,
          excludedIds: seenIds,
        );
      }

      if (result == null || result.isEmpty) {
        _errorMessage = 'Failed to load questions';
        notifyListeners();
        return;
      }

      // 4. Absolute Deduplication
      final uniqueQuestions = <String, Question>{};
      for (var q in result) {
        String cleanText = q.questionText.trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
        uniqueQuestions[cleanText] = q;
      }
      List<Question> finalQuestions = uniqueQuestions.values.toList();

      // 5. Shuffle & Take 15
      finalQuestions.shuffle();
      int takeCount = finalQuestions.length < 15 ? finalQuestions.length : 15;
      result = finalQuestions.take(takeCount).toList();

      debugPrint(
        'DEBUG: Fetched unseen unique questions from DB: ${finalQuestions.length}',
      );
      debugPrint('DEBUG: Selected questions for game: ${result.length}');

      _questions = result;

      // 6. Save New Memory
      final newIdsToSave = result.map((q) => q.id.toString()).toList();
      await _saveSeenQuestionIds(
        category,
        newIdsToSave, // Will append to existing in helper
      );

      debugPrint(
        'DEBUG: Saved new IDs to memory. Total saved: ${seenIds.length + newIdsToSave.length}',
      );
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitAnswer(int currentScore, bool isCorrect) async {
    if (_room == null) return;

    // Play sound based on answer mapping
    _playSound(isCorrect);

    int newScore = currentScore;

    // Optimistic UI update
    if (isPlayer1) {
      _room = _room!.copyWith(p1Score: newScore);
    } else {
      _room = _room!.copyWith(p2Score: newScore);
    }
    notifyListeners();

    await _service.updateScore(_roomCode!, isPlayer1 ? 1 : 2, newScore);
  }

  Future<void> nextQuestion() async {
    if (_room == null) return;
    if (_room!.currentQIndex < 14) {
      // Assuming 15 questions (0-14)
      await _service.nextQuestion(_roomCode!, _room!.currentQIndex);
    } else {
      await _service.finishGame(_roomCode!);
    }
  }

  // Start the game (only host should call this). Returns true on success.
  Future<bool> startGame() async {
    if (_roomCode == null) return false;

    _errorMessage = null;
    _setLoading(true);

    try {
      final success = await _service.startGame(_roomCode!);
      if (!success) {
        _errorMessage = 'Failed to start game';
        _setLoading(false);
        return false;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Unexpected error starting game';
      _setLoading(false);
      return false;
    }
  }

  // Start single-player game. Returns true on success, false on failure.
  Future<bool> startSinglePlayerGame(String category) async {
    _isSinglePlayer = true;
    _errorMessage = null;
    _setLoading(true);

    try {
      // 1. Read memory
      List<String> seenIds = await _getSeenQuestionIds(category);
      debugPrint('DEBUG: Seen IDs for $category: ${seenIds.length}');

      // 2. Fetch All Unseen
      List<Question>? questions = await _service.fetchQuestionsByCategory(
        category,
        excludedIds: seenIds,
      );

      // 3. Fallback Reset
      if (questions == null || questions.length < 15) {
        debugPrint(
          'DEBUG: Not enough unseen questions. Clearing memory for $category.',
        );
        await _clearSeenQuestionIds(category);
        seenIds = [];
        questions = await _service.fetchQuestionsByCategory(
          category,
          excludedIds: seenIds,
        );
      }

      if (questions == null || questions.isEmpty) {
        _errorMessage = 'Failed to load questions for this category';
        _setLoading(false);
        return false;
      }

      // 4. Absolute Deduplication
      final uniqueQuestions = <String, Question>{};
      for (var q in questions) {
        String cleanText = q.questionText.trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
        uniqueQuestions[cleanText] = q;
      }
      List<Question> finalQuestions = uniqueQuestions.values.toList();

      // 5. Shuffle & Take 15
      finalQuestions.shuffle();
      int takeCount = finalQuestions.length < 15 ? finalQuestions.length : 15;
      questions = finalQuestions.take(takeCount).toList();

      debugPrint(
        'DEBUG: Fetched unseen unique questions from DB: ${finalQuestions.length}',
      );
      debugPrint('DEBUG: Selected questions for game: ${questions.length}');

      // 6. Save New Memory
      final newIdsToSave = questions.map((q) => q.id.toString()).toList();
      await _saveSeenQuestionIds(
        category,
        newIdsToSave, // Will append in helper
      );

      debugPrint(
        'DEBUG: Saved new IDs to memory. Total saved: ${seenIds.length + newIdsToSave.length}',
      );

      _currentQuestions = questions;
      _currentQuestionIndex = 0;
      _singlePlayerScore = 0;
      _isSinglePlayer = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Unexpected error loading game';
      _setLoading(false);
      return false;
    }
  }

  void submitSinglePlayerAnswer(bool isCorrect) {
    _playSound(isCorrect);
    if (isCorrect) {
      _singlePlayerScore += 10;
      notifyListeners();
    }
  }

  bool nextSinglePlayerQuestion() {
    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
      return true;
    } else {
      // Game over logic will navigate to results screen
      if (_nickname != null) {
        _service.updateLeaderboard(_nickname!, _singlePlayerScore);
      }
      _errorMessage = 'Game Over! Final Score: $_singlePlayerScore';
      notifyListeners();
      return false;
    }
  }

  void leaveRoom() {
    _roomSubscription?.cancel();
    _roomSubscription = null;
    _room = null;
    _roomCode = null;
    _questions = [];
    _isLoading = false;
    _errorMessage = null;

    // Reset Single Player state as well
    _isSinglePlayer = false;
    _currentQuestions = [];
    _currentQuestionIndex = 0;
    _singlePlayerScore = 0;
    _fiftyFiftyUsed = false;
    _askAudienceUsed = false;

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
