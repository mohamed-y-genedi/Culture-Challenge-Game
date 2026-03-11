class Room {
  final String roomCode;
  final String hostNickname;
  final int maxPlayers;
  // Dynamic map representing the players JSONB from DB.
  // Example: {"Alice": {"score": 10, "has_answered": false}, "Bob": ...}
  final Map<String, dynamic> players;
  final int currentQIndex;
  final String status;
  final String category;
  final String gameMode; // 'ffa' or 'teams'
  final List<Map<String, dynamic>>? questions;

  Room({
    required this.roomCode,
    required this.hostNickname,
    this.maxPlayers = 2,
    required this.players,
    this.currentQIndex = 0,
    this.status = 'waiting',
    required this.category,
    this.gameMode = 'ffa',
    this.questions,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomCode: json['room_code'] as String,
      hostNickname: json['host_nickname'] as String? ?? '',
      maxPlayers: json['max_players'] as int? ?? 2,
      players: json['players'] as Map<String, dynamic>? ?? {},
      currentQIndex: json['current_q_index'] as int? ?? 0,
      status: json['status'] as String? ?? 'waiting',
      category: json['category'] as String,
      gameMode: json['game_mode'] as String? ?? 'ffa',
      questions: json['questions'] != null
          ? List<Map<String, dynamic>>.from(json['questions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_code': roomCode,
      'host_nickname': hostNickname,
      'max_players': maxPlayers,
      'players': players,
      'current_q_index': currentQIndex,
      'status': status,
      'category': category,
      'game_mode': gameMode,
      if (questions != null) 'questions': questions,
    };
  }

  // Legacy getters to prevent UI errors during data layer transition
  String? get player1 {
    if (players.isEmpty) return null;
    return players.keys.elementAt(0);
  }

  String? get player2 {
    if (players.length < 2) return null;
    return players.keys.elementAt(1);
  }

  int get p1Score {
    final p1 = player1;
    if (p1 == null) return 0;
    return players[p1]['score'] as int? ?? 0;
  }

  int get p2Score {
    final p2 = player2;
    if (p2 == null) return 0;
    return players[p2]['score'] as int? ?? 0;
  }

  Room copyWith({
    String? roomCode,
    String? hostNickname,
    int? maxPlayers,
    Map<String, dynamic>? players,
    int? currentQIndex,
    String? status,
    String? category,
    String? gameMode,
    List<Map<String, dynamic>>? questions,
  }) {
    return Room(
      roomCode: roomCode ?? this.roomCode,
      hostNickname: hostNickname ?? this.hostNickname,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      players: players ?? this.players,
      currentQIndex: currentQIndex ?? this.currentQIndex,
      status: status ?? this.status,
      category: category ?? this.category,
      gameMode: gameMode ?? this.gameMode,
      questions: questions ?? this.questions,
    );
  }
}
