import 'dart:collection';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:legal_wordle_words/legal_wordle_words.dart';
import 'package:russian_wordle_repo/russian_wordle_repo.dart';

const List<String> allLegalGuessesEng = [...legalWords, ...legalGuesses];
const List<String> allLegalGuessesRus = [...legalWordsRus, ...legalGuessesRus];

enum Lang { rus, eng }

enum HitType { none, hit, partial, miss, removed }

typedef Letter = ({String char, HitType type});

class GameState with ChangeNotifier {
  GameState._internal() {
    resetGame();
  }

  static final GameState _instance = GameState._internal();

  factory GameState() => _instance;

  int numAllowedGuesses = 5;
  Lang lang = Lang.rus;
  int? seed;

  late List<Word> _guesses;
  late Word _wordToGuess;

  void init({Lang? newLang, int? newSeed}) {
    if (newLang != null) lang = newLang;
    seed = newSeed;
    resetGame();
  }

  void updateLanguage(Lang newLang) {
    if (lang == newLang) return;
    lang = newLang;
    resetGame();
  }

  List<String> get allLegalGuesses => switch (lang) {
    Lang.rus => allLegalGuessesRus,
    Lang.eng => allLegalGuessesEng,
  };

  // Select the correct dictionary based on language
  List<String> get _dictionary => lang == Lang.rus ? legalWordsRus : legalWords;

  void resetGame() {
    final words = _dictionary;
    if (seed == null) {
      _wordToGuess = Word.fromString(words[Random().nextInt(words.length)]);
    } else {
      _wordToGuess = Word.fromString(words[seed! % words.length]);
    }
    _guesses = List.generate(numAllowedGuesses, (_) => Word.empty());
    notifyListeners();
  }

  Word matchGuessOnly(String guess) {
    var hiddenCopy = Word.fromString(_wordToGuess.toString());
    return Word.fromString(guess).evaluateGuess(hiddenCopy, allLegalGuesses);
  }

  bool isLegalGuess(String guess) {
    return Word.fromString(guess).isLegalGuess(allLegalGuesses);
  }

  Word get hiddenWord => _wordToGuess;

  UnmodifiableListView<Word> get guesses => UnmodifiableListView(_guesses);

  Word get previousGuess {
    final index = _guesses.lastIndexWhere((word) => word.isNotEmpty);
    return index == -1 ? Word.empty() : _guesses[index];
  }

  int get activeIndex {
    return _guesses.indexWhere((word) => word.isEmpty);
  }

  int get guessesRemaining {
    if (activeIndex == -1) return 0;
    return numAllowedGuesses - activeIndex;
  }

  // Most common entry-point for handling guess logic.
  // For finer control over logic, use other methods such as [isGuessLegal]
  // and [matchGuess]
  Word guess(String guess) {
    final result = matchGuessOnly(guess);
    addGuessToList(result);
    notifyListeners();
    return result;
  }

  bool get didWin {
    if (_guesses.first.isEmpty) return false;

    for (var letter in previousGuess) {
      if (letter.type != HitType.hit) return false;
    }

    return true;
  }

  bool get didLose => guessesRemaining == 0 && !didWin;

  void addGuessToList(Word guess) {
    final i = _guesses.indexWhere((word) => word.isEmpty);
    _guesses[i] = guess;
  }
}

class Word with IterableMixin<Letter> {
  Word(this._letters);

  factory Word.empty() {
    return Word(List.filled(5, (char: '', type: HitType.none)));
  }

  factory Word.fromString(String guess) {
    var list = guess.toLowerCase().split('');
    var letters = list
        .map((String char) => (char: char, type: HitType.none))
        .toList();
    return Word(letters);
  }

  factory Word.random() {
    var rand = Random();
    var nextWord = legalWords[rand.nextInt(legalWords.length)];
    return Word.fromString(nextWord);
  }

  factory Word.fromSeed(int seed) {
    return Word.fromString(legalWords[seed % legalWords.length]);
  }

  final List<Letter> _letters;

  /// Loop over the Letters in this word
  @override
  Iterator<Letter> get iterator => _letters.iterator;

  @override
  bool get isEmpty {
    return every((letter) => letter.char.isEmpty);
  }

  @override
  bool get isNotEmpty => !isEmpty;

  Letter operator [](int i) => _letters[i];
  operator []=(int i, Letter value) => _letters[i] = value;

  @override
  String toString() {
    return _letters.map((Letter c) => c.char).join().trim();
  }

  // Used to play game in the CLI implementation
  String toStringVerbose() {
    return _letters.map((l) => '${l.char} - ${l.type.name}').join('\n');
  }
}

extension WordUtils on Word {
  // Pass the word list explicitly to check legality
  bool isLegalGuess(List<String> legalList) {
    return legalList.contains(toString());
  }

  Word evaluateGuess(Word other, List<String> legalList) {
    if (!isLegalGuess(legalList)) {
      throw ArgumentError(
        'The guess is not a legal word according to the current rules.',
      );
    }

    // Create a copy of the letters to avoid side effects during logic
    final resultLetters = List<Letter>.from(this);
    final targetLetters = List<Letter>.from(other);

    // 1. Find exact hits
    for (var i = 0; i < resultLetters.length; i++) {
      if (targetLetters[i].char == resultLetters[i].char) {
        resultLetters[i] = (char: resultLetters[i].char, type: HitType.hit);
        targetLetters[i] = (char: targetLetters[i].char, type: HitType.removed);
      }
    }

    // 2. Find partial matches
    for (var i = 0; i < targetLetters.length; i++) {
      if (targetLetters[i].type == HitType.removed) continue;

      for (var j = 0; j < resultLetters.length; j++) {
        if (resultLetters[j].type != HitType.none) continue;

        if (resultLetters[j].char == targetLetters[i].char) {
          resultLetters[j] = (
            char: resultLetters[j].char,
            type: HitType.partial,
          );
          targetLetters[i] = (
            char: targetLetters[i].char,
            type: HitType.removed,
          );
          break;
        }
      }
    }

    // 3. Mark remaining as misses
    for (var i = 0; i < resultLetters.length; i++) {
      if (resultLetters[i].type == HitType.none) {
        resultLetters[i] = (char: resultLetters[i].char, type: HitType.miss);
      }
    }

    return Word(resultLetters);
  }
}
