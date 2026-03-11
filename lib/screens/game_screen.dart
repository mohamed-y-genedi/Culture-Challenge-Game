import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/question.dart';
import '../utils/translations.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  void _submitAnswer(String option, String correctOption) {
    final provider = Provider.of<GameProvider>(context, listen: false);
    final isCorrect = option == correctOption;

    int currentScore = 0;
    if (provider.nickname != null &&
        provider.room != null &&
        provider.room!.players.containsKey(provider.nickname!)) {
      currentScore =
          (provider.room!.players[provider.nickname!]
              as Map<String, dynamic>)['score'] ??
          0;
    }

    final newScore = isCorrect ? currentScore + 10 : currentScore;
    provider.submitAnswer(newScore, isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        if (provider.isSinglePlayer) {
          if (provider.currentQuestions.isEmpty) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final currentIndex = provider.currentQuestionIndex;
          final question = provider.currentQuestions[currentIndex];
          return _SinglePlayerGameView(
            key: ValueKey('single_$currentIndex'),
            question: question,
          );
        }

        if (provider.room == null || provider.questions.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.room!.status == 'finished') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/multiplayer_result');
          });
          return const Scaffold(body: SizedBox());
        }

        final currentIndex = provider.room!.currentQIndex;

        if (currentIndex >= provider.questions.length) {
          return const Scaffold(
            body: Center(child: Text("جاري إنهاء اللعبة...")),
          );
        }

        final question = provider.questions[currentIndex];

        return _GameView(
          key: ValueKey('multi_$currentIndex'),
          question: question,
          players: provider.room!.players,
          myName: provider.nickname ?? '',
          hostNickname: provider.room!.hostNickname,
          isHost: provider.isHost,
          allPlayersAnswered: provider.allPlayersAnswered,
          currentIndex: currentIndex,
          totalQuestions: provider.questions.length,
          onAnswer: (option) => _submitAnswer(option, question.correctOption),
          onTimeout: (idx) {
            if (provider.isHost) {
              provider.nextQuestion();
            }
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------
// MULTIPLAYER GAME VIEW
// ---------------------------------------------------------
class _GameView extends StatefulWidget {
  final Question question;
  final Map<String, dynamic> players;
  final String myName;
  final String hostNickname;
  final bool isHost;
  final bool allPlayersAnswered;
  final int currentIndex;
  final int totalQuestions;
  final Function(String) onAnswer;
  final Function(int) onTimeout;

  const _GameView({
    super.key,
    required this.question,
    required this.players,
    required this.myName,
    required this.hostNickname,
    required this.isHost,
    required this.allPlayersAnswered,
    required this.currentIndex,
    required this.totalQuestions,
    required this.onAnswer,
    required this.onTimeout,
  });

  @override
  State<_GameView> createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> {
  int _seconds = 15;
  Timer? _timer;
  String? _selectedOption;
  bool _answered = false;
  final Set<String> _hiddenOptions = {};

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _GameView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.allPlayersAnswered &&
        widget.allPlayersAnswered &&
        widget.isHost) {
      _timer?.cancel();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) widget.onTimeout(widget.question.id);
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _timer?.cancel();
          if (!_answered) {
            _answered = true;
            widget.onAnswer('TIMEOUT');
          }
          if (widget.isHost) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) widget.onTimeout(widget.question.id);
            });
          }
        }
      });
    });
  }

  void _handleOptionTap(String option) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedOption = option;
    });
    widget.onAnswer(option);
  }

  void _useFiftyFifty(GameProvider provider) {
    if (provider.fiftyFiftyUsed || _answered) return;
    provider.useFiftyFifty();

    final options = ['a', 'b', 'c', 'd'];
    options.remove(widget.question.correctOption);
    options.shuffle();
    setState(() {
      _hiddenOptions.add(options[0]);
      _hiddenOptions.add(options[1]);
    });
  }

  void _useAskAudience(GameProvider provider) {
    if (provider.askAudienceUsed || _answered) return;
    provider.useAskAudience();

    final options = ['a', 'b', 'c', 'd'];
    Map<String, int> percentages = {};
    int correctPercent = 60 + Random().nextInt(26);
    percentages[widget.question.correctOption] = correctPercent;

    int remainingPercent = 100 - correctPercent;
    options.remove(widget.question.correctOption);
    options.shuffle();

    percentages[options[0]] = remainingPercent ~/ 2 + Random().nextInt(5);
    percentages[options[1]] =
        (remainingPercent - percentages[options[0]]!) ~/ 2;
    percentages[options[2]] =
        remainingPercent - percentages[options[0]]! - percentages[options[1]]!;

    _showAudienceDialog(percentages);
  }

  void _showAudienceDialog(Map<String, int> percentages) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'نتيجة تصويت الجمهور',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _audienceRow(widget.question.a, percentages['a']!),
            _audienceRow(widget.question.b, percentages['b']!),
            _audienceRow(widget.question.c, percentages['c']!),
            _audienceRow(widget.question.d, percentages['d']!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Widget _audienceRow(String text, int percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$percent%',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 12,
                color: Colors.blueAccent,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              text,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getOptionColor(String optionKey) {
    if (!_answered) return const Color(0xFF2D2D44);
    if (optionKey == widget.question.correctOption) {
      return Colors.green.shade700;
    }
    if (optionKey == _selectedOption) return Colors.red.shade700;
    return const Color(0xFF2D2D44).withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'السؤال ${widget.currentIndex + 1} من ${widget.totalQuestions}',
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Timer Details
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    value: _seconds / 15,
                                    strokeWidth: 6,
                                    color: _seconds <= 5
                                        ? Colors.red
                                        : Theme.of(context).colorScheme.primary,
                                    backgroundColor: Colors.white10,
                                  ),
                                ),
                                Text(
                                  '$_seconds',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Header Details (Players)
                          provider.room!.gameMode == 'teams'
                              ? _buildTeamsScoreboard(context, widget.players)
                              : _buildFFAScoreboard(context, widget.players),
                          const SizedBox(height: 24),

                          // Lifelines Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Semantics(
                                label: 'LIFELINE_FIFTY_FIFTY',
                                button: true,
                                child: ElevatedButton.icon(
                                  onPressed: provider.fiftyFiftyUsed
                                      ? null
                                      : () => _useFiftyFifty(provider),
                                  icon: const Icon(Icons.exposure_minus_2),
                                  label: const Text('حذف إجابتين'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent,
                                    disabledBackgroundColor: Colors.white10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Semantics(
                                label: 'LIFELINE_ASK_AUDIENCE',
                                button: true,
                                child: ElevatedButton.icon(
                                  onPressed: provider.askAudienceUsed
                                      ? null
                                      : () => _useAskAudience(provider),
                                  icon: const Icon(Icons.groups),
                                  label: const Text('رأي الجمهور'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purpleAccent,
                                    disabledBackgroundColor: Colors.white10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Question
                          Flexible(
                            fit: FlexFit.loose,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  widget.question.questionText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_answered &&
                              !widget.allPlayersAnswered &&
                              _seconds > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                "Waiting for players...".tr(),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),

                          // Options List
                          Flexible(
                            fit: FlexFit.loose,
                            child: Column(
                              children: [
                                if (!_hiddenOptions.contains('a'))
                                  _OptionButton(
                                    label: widget.question.a,
                                    color: _getOptionColor('a'),
                                    onTap: () => _handleOptionTap('a'),
                                  ),
                                const SizedBox(height: 12),
                                if (!_hiddenOptions.contains('b'))
                                  _OptionButton(
                                    label: widget.question.b,
                                    color: _getOptionColor('b'),
                                    onTap: () => _handleOptionTap('b'),
                                  ),
                                const SizedBox(height: 12),
                                if (!_hiddenOptions.contains('c'))
                                  _OptionButton(
                                    label: widget.question.c,
                                    color: _getOptionColor('c'),
                                    onTap: () => _handleOptionTap('c'),
                                  ),
                                const SizedBox(height: 12),
                                if (!_hiddenOptions.contains('d'))
                                  _OptionButton(
                                    label: widget.question.d,
                                    color: _getOptionColor('d'),
                                    onTap: () => _handleOptionTap('d'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFFAScoreboard(
    BuildContext context,
    Map<String, dynamic> players,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: players.entries.map((entry) {
        final pName = entry.key;
        final pScore = (entry.value as Map<String, dynamic>)['score'] ?? 0;
        final isMe = pName == widget.myName;
        final isHost = pName == widget.hostNickname;
        return _ScoreBadge(
          name: pName,
          score: pScore,
          isMe: isMe,
          isHost: isHost,
        );
      }).toList(),
    );
  }

  Widget _buildTeamsScoreboard(
    BuildContext context,
    Map<String, dynamic> players,
  ) {
    int team1Score = 0;
    int team2Score = 0;

    players.forEach((name, data) {
      final t = data['team'] as int?;
      final s = data['score'] as int? ?? 0;
      if (t == 1) {
        team1Score += s;
      } else if (t == 2) {
        team2Score += s;
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Team Red
          Column(
            children: [
              Text(
                'Team Red'.tr(),
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$team1Score',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ],
          ),

          Container(height: 40, width: 2, color: Colors.white24),

          // Team Blue
          Column(
            children: [
              Text(
                'Team Blue'.tr(),
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$team2Score',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// SINGLEPLAYER GAME VIEW
// ---------------------------------------------------------
class _SinglePlayerGameView extends StatefulWidget {
  final Question question;

  const _SinglePlayerGameView({super.key, required this.question});

  @override
  State<_SinglePlayerGameView> createState() => _SinglePlayerGameViewState();
}

class _SinglePlayerGameViewState extends State<_SinglePlayerGameView> {
  int _seconds = 15;
  Timer? _timer;
  String? _selectedOption;
  bool _isAnswerRevealed = false;
  final Set<String> _hiddenOptions = {};

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _timer?.cancel();
          if (!_isAnswerRevealed) {
            _handleOptionSelected(
              'TIMEOUT',
              Provider.of<GameProvider>(context, listen: false),
            );
          }
        }
      });
    });
  }

  void _handleOptionSelected(String selectedKey, GameProvider provider) {
    if (_isAnswerRevealed) return;
    _timer?.cancel();

    setState(() {
      _selectedOption = selectedKey;
      _isAnswerRevealed = true;
    });

    final isCorrect = selectedKey == widget.question.correctOption;
    provider.submitSinglePlayerAnswer(isCorrect);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        bool hasNext = provider.nextSinglePlayerQuestion();
        if (!hasNext) {
          Navigator.pushReplacementNamed(context, '/result');
        }
      }
    });
  }

  void _useFiftyFifty(GameProvider provider) {
    if (provider.fiftyFiftyUsed || _isAnswerRevealed) return;
    provider.useFiftyFifty();

    final options = ['a', 'b', 'c', 'd'];
    options.remove(widget.question.correctOption);
    options.shuffle();
    setState(() {
      _hiddenOptions.add(options[0]);
      _hiddenOptions.add(options[1]);
    });
  }

  void _useAskAudience(GameProvider provider) {
    if (provider.askAudienceUsed || _isAnswerRevealed) return;
    provider.useAskAudience();

    final options = ['a', 'b', 'c', 'd'];
    Map<String, int> percentages = {};
    int correctPercent = 60 + Random().nextInt(26);
    percentages[widget.question.correctOption] = correctPercent;

    int remainingPercent = 100 - correctPercent;
    options.remove(widget.question.correctOption);
    options.shuffle();

    percentages[options[0]] = remainingPercent ~/ 2 + Random().nextInt(5);
    percentages[options[1]] =
        (remainingPercent - percentages[options[0]]!) ~/ 2;
    percentages[options[2]] =
        remainingPercent - percentages[options[0]]! - percentages[options[1]]!;

    _showAudienceDialog(percentages);
  }

  void _showAudienceDialog(Map<String, int> percentages) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'نتيجة تصويت الجمهور',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _audienceRow(widget.question.a, percentages['a']!),
            _audienceRow(widget.question.b, percentages['b']!),
            _audienceRow(widget.question.c, percentages['c']!),
            _audienceRow(widget.question.d, percentages['d']!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Widget _audienceRow(String text, int percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$percent%',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 12,
                color: Colors.blueAccent,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              text,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getButtonColor(String key, BuildContext context) {
    if (!_isAnswerRevealed) return Theme.of(context).cardColor;
    if (key == widget.question.correctOption) return Colors.green.shade700;
    if (key == _selectedOption) return Colors.red.shade700;
    return Theme.of(context).cardColor.withValues(alpha: 0.5);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final currentIndex = provider.currentQuestionIndex;
    final totalQuestions = provider.currentQuestions.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لعبة فردية'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'السؤال ${currentIndex + 1} من $totalQuestions',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            value: _seconds / 15,
                            strokeWidth: 5,
                            color: _seconds <= 5
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                        Text(
                          '$_seconds',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'النتيجة: ${provider.singlePlayerScore}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Lifelines Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      label: 'LIFELINE_FIFTY_FIFTY',
                      button: true,
                      child: ElevatedButton.icon(
                        onPressed: provider.fiftyFiftyUsed
                            ? null
                            : () => _useFiftyFifty(provider),
                        icon: const Icon(Icons.exposure_minus_2),
                        label: const Text('حذف إجابتين'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          disabledBackgroundColor: Colors.white10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Semantics(
                      label: 'LIFELINE_ASK_AUDIENCE',
                      button: true,
                      child: ElevatedButton.icon(
                        onPressed: provider.askAudienceUsed
                            ? null
                            : () => _useAskAudience(provider),
                        icon: const Icon(Icons.groups),
                        label: const Text('رأي الجمهور'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          disabledBackgroundColor: Colors.white10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Question Box
                Flexible(
                  fit: FlexFit.loose,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.question.questionText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Options List
                Flexible(
                  fit: FlexFit.loose,
                  child: Column(
                    children: [
                      if (!_hiddenOptions.contains('a'))
                        _OptionButton(
                          label: widget.question.a,
                          color: _getButtonColor('a', context),
                          onTap: () => _handleOptionSelected('a', provider),
                        ),
                      const SizedBox(height: 12),
                      if (!_hiddenOptions.contains('b'))
                        _OptionButton(
                          label: widget.question.b,
                          color: _getButtonColor('b', context),
                          onTap: () => _handleOptionSelected('b', provider),
                        ),
                      const SizedBox(height: 12),
                      if (!_hiddenOptions.contains('c'))
                        _OptionButton(
                          label: widget.question.c,
                          color: _getButtonColor('c', context),
                          onTap: () => _handleOptionSelected('c', provider),
                        ),
                      const SizedBox(height: 12),
                      if (!_hiddenOptions.contains('d'))
                        _OptionButton(
                          label: widget.question.d,
                          color: _getButtonColor('d', context),
                          onTap: () => _handleOptionSelected('d', provider),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// SHARED WIDGETS
// ---------------------------------------------------------
class _ScoreBadge extends StatelessWidget {
  final String name;
  final int score;
  final bool isMe;
  final bool isHost;

  const _ScoreBadge({
    required this.name,
    required this.score,
    required this.isMe,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isMe ? 'أنت' : name,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isHost) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.workspace_premium,
                color: Colors.amber,
                size: 16,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: 'OPTION_BTN_$label',
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
