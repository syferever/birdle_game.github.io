import 'dart:collection';

import 'package:birdle/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

typedef LangEntry = DropdownMenuEntry<LangDropdown>;

enum LangDropdown {
  rus('Rus', Lang.rus),
  eng('Eng', Lang.eng);

  const LangDropdown(this.label, this.language);
  final String label;
  final Lang language;

  static final List<LangEntry> entries = UnmodifiableListView<LangEntry>(
    values.map<LangEntry>(
      (LangDropdown language) =>
          LangEntry(value: language, label: language.label),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final TextEditingController langController = TextEditingController();
  LangDropdown? selectedLang;

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
                onPressed: GameState().resetGame,
                iconSize: 30,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: const Text('Birdle'),
                ),
              ),
              DropdownMenu<LangDropdown>(
                initialSelection: LangDropdown.rus,
                controller: langController,
                label: const Text('Language'),
                selectOnly: true,
                onSelected: (LangDropdown? lang) {
                  setState(() {
                    if (lang != null) {
                      selectedLang = lang;
                      GameState().updateLanguage(lang.language);
                    }
                  });
                },
                dropdownMenuEntries: LangDropdown.entries,
              ),
            ],
          ),
        ),
        body: Center(child: GamePage()),
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
  final GameState _game = GameState();

  @override
  void initState() {
    super.initState();
    _game.addListener(_update);
  }

  @override
  void dispose() {
    _game.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

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
            if (!_game.didWin && !_game.didLose)
              GuessInput(
                onSubmitGuess: (String guess) {
                  if (guess.length != 5) return;
                  if (_game.isLegalGuess(guess)) {
                    _game.guess(guess);
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Not in word list")));
                  }
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
