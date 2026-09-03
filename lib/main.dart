import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const ConnectFourApp());

class ConnectFourApp extends StatelessWidget {
  const ConnectFourApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Fourward',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C5CE7),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF10101A),
      useMaterial3: true,
    ),
    home: const HomeScreen(),
  );
}

enum GameMode { solo, twoPlayer }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  void _start(BuildContext context, GameMode mode) => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => GameScreen(mode: mode)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF27204B), Color(0xFF10101A)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const _Logo(),
              const SizedBox(height: 22),
              Text(
                'FOURWARD',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 5),
              ),
              const SizedBox(height: 8),
              Text(
                'Drop a disc. Connect four. Claim the board.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: .65)),
              ),
              const Spacer(),
              _ModeButton(
                icon: Icons.smart_toy_rounded,
                title: 'Play vs Bot',
                subtitle: 'Take on a clever opponent',
                color: const Color(0xFF6C5CE7),
                onTap: () => _start(context, GameMode.solo),
              ),
              const SizedBox(height: 14),
              _ModeButton(
                icon: Icons.people_alt_rounded,
                title: 'Two Players',
                subtitle: 'Pass and play on one device',
                color: const Color(0xFFEC4899),
                onTap: () => _start(context, GameMode.twoPlayer),
              ),
              const Spacer(),
              Text(
                'First to connect four wins',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .4),
                  fontSize: 12,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 116,
      height: 100,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Color(0x666C5CE7), blurRadius: 35, spreadRadius: 4),
        ],
      ),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: List.generate(
          12,
          (i) => DecoratedBox(
            decoration: BoxDecoration(
              color: i >= 8 && i != 11
                  ? const Color(0xFFFFC857)
                  : i == 11
                  ? const Color(0xFFFF5C7A)
                  : const Color(0xFF302863),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 30),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: .75),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_rounded),
      ],
    ),
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode});
  final GameMode mode;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const rows = 6, columns = 7;
  late List<List<int>> board;
  int currentPlayer = 1, score1 = 0, score2 = 0;
  int? winner, lastRow, lastColumn;
  bool isDraw = false, botThinking = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    board = List.generate(rows, (_) => List.filled(columns, 0));
    currentPlayer = 1;
    winner = lastRow = lastColumn = null;
    isDraw = botThinking = false;
  }

  void _newRound() => setState(_reset);
  int? _openRow(int column) {
    for (var row = rows - 1; row >= 0; row--) {
      if (board[row][column] == 0) return row;
    }
    return null;
  }

  Future<void> _play(int column) async {
    if (winner != null || isDraw || botThinking) return;
    final row = _openRow(column);
    if (row == null) return;
    setState(() {
      board[row][column] = currentPlayer;
      lastRow = row;
      lastColumn = column;
      _finish(row, column);
    });
    if (widget.mode == GameMode.solo &&
        winner == null &&
        !isDraw &&
        currentPlayer == 2) {
      setState(() => botThinking = true);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (mounted && winner == null) _botMove();
    }
  }

  void _finish(int row, int column) {
    if (_hasWon(row, column, currentPlayer)) {
      winner = currentPlayer;
      if (winner == 1) {
        score1++;
      } else {
        score2++;
      }
    } else if (board.every((line) => line.every((cell) => cell != 0))) {
      isDraw = true;
    } else {
      currentPlayer = currentPlayer == 1 ? 2 : 1;
    }
  }

  void _botMove() {
    final valid = List.generate(
      columns,
      (i) => i,
    ).where((c) => _openRow(c) != null).toList();
    if (valid.isEmpty) return;
    int? choice = _winningMove(2) ?? _winningMove(1);
    choice ??= valid.contains(3) ? 3 : (valid..shuffle(Random())).first;
    final row = _openRow(choice)!;
    setState(() {
      board[row][choice!] = 2;
      lastRow = row;
      lastColumn = choice;
      botThinking = false;
      _finish(row, choice);
    });
  }

  int? _winningMove(int player) {
    for (var c = 0; c < columns; c++) {
      final r = _openRow(c);
      if (r == null) continue;
      board[r][c] = player;
      final wins = _hasWon(r, c, player);
      board[r][c] = 0;
      if (wins) return c;
    }
    return null;
  }

  bool _hasWon(int row, int column, int player) {
    const directions = [(0, 1), (1, 0), (1, 1), (1, -1)];
    for (final (dr, dc) in directions) {
      var count = 1;
      for (final sign in [-1, 1]) {
        var r = row + dr * sign, c = column + dc * sign;
        while (r >= 0 &&
            r < rows &&
            c >= 0 &&
            c < columns &&
            board[r][c] == player) {
          count++;
          r += dr * sign;
          c += dc * sign;
        }
      }
      if (count >= 4) return true;
    }
    return false;
  }

  String get _status {
    if (winner != null) {
      return widget.mode == GameMode.solo && winner == 2
          ? 'Bot wins!'
          : 'Player $winner wins!';
    }
    if (isDraw) return "It's a draw!";
    if (botThinking) return 'Bot is thinking…';
    return "Player $currentPlayer's turn";
  }

  @override
  Widget build(BuildContext context) {
    final over = winner != null || isDraw;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          widget.mode == GameMode.solo ? 'VS BOT' : 'TWO PLAYERS',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            children: [
              _ScoreBar(mode: widget.mode, score1: score1, score2: score2),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Row(
                  key: ValueKey(_status),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isDraw)
                      Container(
                        width: 13,
                        height: 13,
                        margin: const EdgeInsets.only(right: 9),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (winner ?? currentPlayer) == 1
                              ? const Color(0xFFFFC857)
                              : const Color(0xFFFF5C7A),
                        ),
                      ),
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              AspectRatio(
                aspectRatio: 7 / 6.4,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0x556C5CE7), blurRadius: 25),
                    ],
                  ),
                  child: Column(
                    children: List.generate(
                      rows,
                      (r) => Expanded(
                        child: Row(
                          children: List.generate(
                            columns,
                            (c) => Expanded(
                              child: Semantics(
                                button: true,
                                label: 'Column ${c + 1}',
                                child: InkWell(
                                  key: Key('cell-$r-$c'),
                                  borderRadius: BorderRadius.circular(99),
                                  onTap: () => _play(c),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.5),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      decoration: BoxDecoration(
                                        color: board[r][c] == 1
                                            ? const Color(0xFFFFC857)
                                            : board[r][c] == 2
                                            ? const Color(0xFFFF5C7A)
                                            : const Color(0xFF202038),
                                        shape: BoxShape.circle,
                                        border: r == lastRow && c == lastColumn
                                            ? Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (over)
                FilledButton.icon(
                  onPressed: _newRound,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('PLAY AGAIN'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    minimumSize: const Size.fromHeight(54),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _newRound,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('RESTART ROUND'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.mode,
    required this.score1,
    required this.score2,
  });
  final GameMode mode;
  final int score1, score2;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const _PlayerLabel(color: Color(0xFFFFC857), label: 'PLAYER 1'),
        Expanded(
          child: Text(
            '$score1  —  $score2',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ),
        _PlayerLabel(
          color: const Color(0xFFFF5C7A),
          label: mode == GameMode.solo ? 'BOT' : 'PLAYER 2',
          alignEnd: true,
        ),
      ],
    ),
  );
}

class _PlayerLabel extends StatelessWidget {
  const _PlayerLabel({
    required this.color,
    required this.label,
    this.alignEnd = false,
  });
  final Color color;
  final String label;
  final bool alignEnd;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 70,
    child: Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .6),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
          ),
        ),
      ],
    ),
  );
}
