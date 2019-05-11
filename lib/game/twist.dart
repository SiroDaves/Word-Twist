import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:trotter/trotter.dart';
import 'package:word_twist/data/repo.dart';
import 'package:word_twist/game/game_score.dart';

const kSpace = ' ';

class TwistGame {
  final WordsRepository _repository;
  final int wordLength;
  final List<bool> selectedIndexes = [];
  final List<String> builtWord = [];
  final Set<String> foundWords = new Set();
  final List<String> possibleWords = [];
  final GameScore gameScore = new GameScore();

  String _letters = '';
  GameMode _gameMode;

  TwistGame(this._repository, {this.wordLength = 6});

  operator [](int i) => this._letters[i];

  int get length => _letters.length;
  String get sourceLetters => _letters;
  bool isSelected(int i) => selectedIndexes[i];
  bool get isSolved => possibleWords.length > 0 && possibleWords.length == foundWords.length;
  GameMode get gameMode => _gameMode;

  Future createNewGame(GameMode gameMode) async {
    _gameMode = gameMode;
    foundWords.clear();
    _letters = await _repository.getRandomWord();
    twistWord();
    final sortedLetters = _letters.split('');
    sortedLetters.sort((a, b) => a.codeUnitAt(0).compareTo(b.codeUnitAt(0)));
    await _buildPossibleWords(sortedLetters);    
    gameScore.newGame(gameMode, possibleWords);
  }

  Future _buildPossibleWords(List<String> sortedLetters) async {
    final port = ReceivePort();
    await Isolate.spawn(_findAllPermutations, port.sendPort);
    await port.listen((data) async {
      if (data is SendPort) {
        final SendPort isolatePort = data;
        isolatePort.send(sortedLetters);
      } else {
        Set<String> words = data;
        Set<String> possibleWordsSet = new Set<String>();
        for (var w in words) {
          possibleWordsSet.addAll(await _repository.getBuildableWords(w));
        }
        possibleWords
          ..clear()
          ..addAll(possibleWordsSet.toList());
        possibleWords.sort((l, r) => l.length.compareTo(r.length));        
        port.close();
      }
    }).asFuture();
  }

  void twistWord() {
    resetSelection();
    final rnd = new Random();
    final list = Iterable.generate(_letters.length, (n) => _letters[n]).toList();
    for (var i = 0; i < list.length; i++) {
      final s = list[i];
      final n = rnd.nextInt(list.length - 1);
      list[i] = list[n];
      list[n] = s;
    }
    _letters = list.join().trim();
    gameScore.onWordTwist();
  }

  void resetSelection() {
    selectedIndexes.length = _letters.length;
    selectedIndexes.setAll(0, Iterable.generate(_letters.length, (n) => false));
    builtWord.length = _letters.length;
    builtWord.setAll(0, Iterable.generate(_letters.length, (n) => kSpace));
  }

  static void _findAllPermutations(SendPort sendPort) async {
    Set<String> set = new Set();
    var receivePort = new ReceivePort();
    sendPort.send(receivePort.sendPort);
    List<String> sortedLetters = await receivePort.first;
    final subsets = new Subsets(sortedLetters);
    print(subsets);
    for (var s in subsets()) {      
      if (s.length > 2) {
        s.sort((l, r) => l.toString().length.compareTo(r.toString().length));
        set.add(s.join());
      }
    }
    sendPort.send(set);
    receivePort.close();
  }

  void toggleSelect(int pos) {
    final bool isSelected = selectedIndexes[pos];
    if (isSelected) {
      builtWord[builtWord.indexOf(_letters[pos])] = kSpace;
    } else {
      builtWord[builtWord.indexOf(kSpace)] = _letters[pos];
    }
    selectedIndexes[pos] = !isSelected;
  }

  void solveAll() {
    foundWords.clear();
    foundWords.addAll(possibleWords);
  }
}

enum GameMode { normal, hard, unlimited }