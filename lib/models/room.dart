class Room {
  final String roomCode;
  final String? player1;
  final String? player2;
  final int p1Score;
  final int p2Score;
  final int currentQIndex;
  final String status;
  final String category;

  Room({
    required this.roomCode,
    this.player1,
    this.player2,
    this.p1Score = 0,
    this.p2Score = 0,
    this.currentQIndex = 0,
    this.status = 'waiting',
    required this.category,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomCode: json['room_code'] as String,
      player1: json['player1_id'] as String?,
      player2: json['player2_id'] as String?,
      p1Score: json['p1_score'] as int? ?? 0,
      p2Score: json['p2_score'] as int? ?? 0,
      currentQIndex: json['current_q_index'] as int? ?? 0,
      status: json['status'] as String? ?? 'waiting',
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_code': roomCode,
      'player1_id': player1,
      'player2_id': player2,
      'p1_score': p1Score,
      'p2_score': p2Score,
      'current_q_index': currentQIndex,
      'status': status,
      'category': category,
    };
  }

  Room copyWith({
    String? roomCode,
    String? player1,
    String? player2,
    int? p1Score,
    int? p2Score,
    int? currentQIndex,
    String? status,
    String? category,
  }) {
    return Room(
      roomCode: roomCode ?? this.roomCode,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      p1Score: p1Score ?? this.p1Score,
      p2Score: p2Score ?? this.p2Score,
      currentQIndex: currentQIndex ?? this.currentQIndex,
      status: status ?? this.status,
      category: category ?? this.category,
    );
  }
}
