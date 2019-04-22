import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:trotter/trotter.dart';
import 'package:word_twist/data/repo.dart';

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
  
  TwistGame(this._repository, {this.wordLength = 6});

  operator [](int i) => this._letters[i];

  int get length => _letters.length;
  String get sourceLetters => _letters; 
  bool isSelected(int i) => selectedIndexes[i];

  Future createNewGame({GameMode gameMode = GameMode.hard}) async {    
    foundWords.clear();
    _letters = await _repository.getRandomWord();
    twistWord();
    final sortedLetters = _letters.split('');
    sortedLetters.sort((a, b) => a.codeUnitAt(0).compareTo(b.codeUnitAt(0)));
    await _buildPossibleWords(sortedLetters);
    resetSelection();
    gameScore._newGame(gameMode, possibleWords);
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
        print(possibleWords);
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
    gameScore._onWordTwist();
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
      print(s);
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

class GameTimer {
  final Function _onTimeExpired;
  final Function _onTimeTick;
  final int time;

  int _seconds = 2 * 60;
  StreamSubscription _streamSubscription;
  bool _paused = false;

  int get seconds => _seconds;

  String get gameTime {
    int mins = ((_seconds % 3600) ~/ 60);
    int seconds = _seconds % 60;
    return mins >= 10 ? '$mins' : '0$mins' + ':' + (seconds >= 10 ? '$seconds' : '0$seconds');
  }

  bool get isTimeExpired => _seconds == 0;
  bool get isPaused => _paused;

  GameTimer(this._onTimeExpired, this._onTimeTick, [this.time = 2 * 60]);

  void restartTimer() {
    dispose();
    _seconds = time;
    _streamSubscription = new Stream.periodic(new Duration(seconds: 1)).where((d) => !_paused).listen((d) {
      _seconds--;
      _onTimeTick();
      if (_seconds == 0) {
        _onTimeExpired();
        _streamSubscription.cancel();
      }
    });
  }

  void addTime(int seconds) {
    _seconds += seconds;
  }

  void stop() {
    dispose();
    _seconds = 0;
  }

  void togglePause() {
    _paused = !_paused;
  }

  void dispose() {
    _streamSubscription?.cancel();
  }
}

class GameScore {
  static const int _kMaxWords = 170;

  int _score = 0;
  GameMode _gameMode;
  int _scoreMultiplier;

  int get score => _score;
 
  void _newGame(GameMode gameMode, List<String> possibleWords) {
    _score = 0;
    _gameMode = gameMode;
    _scoreMultiplier = (1 / (possibleWords.length / _kMaxWords)).round();
    if (gameMode == GameMode.hard) {
      _scoreMultiplier += (_scoreMultiplier ~/ 2);
    }
  }

  void onWordFound(String word) {
    _score += word.length * _scoreMultiplier;
  }

  void onWordMissed(String falseWord) {
    if (_gameMode == GameMode.hard) {
      _score -= falseWord.length * _scoreMultiplier;
    }
  }

  void _onWordTwist() {
    if (_gameMode == GameMode.hard) {
      _score -= 2 * _scoreMultiplier;
    }
  }

  static int calcScore(Iterable<String> possibleWords, Iterable<String> foundWords, {GameMode gameMode = GameMode.normal}) {
    if (foundWords.isEmpty || gameMode == GameMode.unlimited) return 0;
    int multiplier = (1 / (possibleWords.length / _kMaxWords)).round();
    return foundWords.map((w) => w.length * multiplier * (gameMode == GameMode.normal ? 1 : 1.5)).reduce((l, r) => l + r);
  }
}

enum GameMode {
  normal,
  hard,
  unlimited
}