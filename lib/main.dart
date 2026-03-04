import 'package:birdle/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Key gameKey = UniqueKey();

  void _restartGame() {
    setState(() {
      gameKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.restart_alt_rounded),
                onPressed: _restartGame,
                iconSize: 30,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: const Text('Birdle'),
                ),
              ),
            ],
          ),
        ),
        body: Center(child: GamePage(key: gameKey)),
      ),
    );
  }
}

class Tile extends StatelessWidget {
  const Tile(this.letter, this.hitType, {super.key});

  final String letter;
  final HitType hitType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 80),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 500),
            curve: Curves.bounceIn,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              color: switch (hitType) {
                HitType.hit => Colors.green,
                HitType.partial => Colors.yellow,
                HitType.miss => Colors.grey,
                _ => Colors.white,
              },
            ),
            child: Center(
              child: Text(
                letter.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final Game _game = Game();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          spacing: 5.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_game.didLose)
              Text(
                "The answer was: ${_game.hiddenWord}",
                style: TextStyle(fontSize: 20),
              )
            else if (_game.didWin)
              Text("Congratulations, you win!", style: TextStyle(fontSize: 20)),
            for (var guess in _game.guesses)
              Row(
                spacing: 5.0,
                children: [
                  for (var letter in guess)
                    Flexible(child: Tile(letter.char, letter.type)),
                ],
              ),
            GuessInput(
              onSubmitGuess: (String guess) {
                setState(() {
                  _game.guess(guess);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GuessInput extends StatelessWidget {
  GuessInput({super.key, required this.onSubmitGuess});

  final void Function(String) onSubmitGuess;

  final TextEditingController _textEditingController = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  void _onSubmit() {
    onSubmitGuess(_textEditingController.text);
    _textEditingController.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              maxLength: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(35)),
                ),
              ),
              controller: _textEditingController,
              autofocus: true,
              onSubmitted: (String input) => _onSubmit(),
            ),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(Icons.arrow_circle_up),
          onPressed: _onSubmit,
          iconSize: 65,
        ),
      ],
    );
  }
}
