class Question {
  final int id;
  final String category;
  final String questionText;
  final String a;
  final String b;
  final String c;
  final String d;
  final String correctOption;

  Question({
    required this.id,
    required this.category,
    required this.questionText,
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.correctOption,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? 0,
      category: json['category'] ?? 'General',
      questionText: json['question_text'] ?? 'Unknown Question',
      a: json['a'] ?? 'Option A',
      b: json['b'] ?? 'Option B',
      c: json['c'] ?? 'Option C',
      d: json['d'] ?? 'Option D',
      correctOption: json['correct_option'] ?? 'a',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'question_text': questionText,
      'a': a,
      'b': b,
      'c': c,
      'd': d,
      'correct_option': correctOption,
    };
  }
}
