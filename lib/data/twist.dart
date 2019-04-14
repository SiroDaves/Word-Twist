import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:trotter/trotter.dart';
import 'package:word_twist/data/repo.dart';

const kSpace = ' ';

class TwistGame {
  final WordsRepository _repository;
  final int count;
  String _source = '';
  final List<bool> selected = [];
  List<String> _sortedLetters = [];
  final List<String> builtWord = [];
  List<String> possibleWords = [];
  final Set<String> foundWords = new Set();

  TwistGame(this._repository, {this.count = 6});

  Future createNewGame() async {
    foundWords.clear();
    _source = await _repository.getRandomWord();
    _sortedLetters = _source.split('');
    _sortedLetters.sort((a, b) => a.codeUnitAt(0).compareTo(b.codeUnitAt(0)));
    twistWord();
    await _buildPossibleWords();
    resetSelection();
  }

  Future _buildPossibleWords() async {
    final port = ReceivePort();
    await Isolate.spawn(findAllPermutations, port.sendPort);
    await port.listen((data) async {
      if (data is SendPort) {
        final SendPort isolatePort = data;
        isolatePort.send(_sortedLetters);
      } else {
        Set<String> words = data;
        Set<String> set = new Set<String>();
        for (var w in words) {
          set.addAll(await _repository.getBuildableWords(w));
        }
        possibleWords = set.toList();
        possibleWords.sort((l, r) => l.length.compareTo(r.length));
        print(possibleWords);
        port.close();
      }
    }).asFuture();
  }

  static void findAllPermutations(SendPort sendPort) async {
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

  operator [](int i) => this._source[i];

  bool isSelected(int i) => selected[i];

  void toggleSelect(int i) {
    final bool isSelected = selected[i];
    if (isSelected) {
      builtWord[builtWord.indexOf(_source[i])] = kSpace;
    } else {
      builtWord[builtWord.indexOf(kSpace)] = _source[i];
    }
    selected[i] = !isSelected;
  }

  void resetSelection() {
    selected.length = _source.length;
    selected.setAll(0, Iterable.generate(_source.length, (n) => false));
    builtWord.length = _source.length;
    builtWord.setAll(0, Iterable.generate(_source.length, (n) => kSpace));
  }

  void twistWord() {
    resetSelection();
    final rnd = new Random();
    final list = Iterable.generate(_source.length, (n) => _source[n]).toList();
    for (var i = 0; i < list.length; i++) {
      final s = list[i];
      final n = rnd.nextInt(list.length - 1);
      list[i] = list[n];
      list[n] = s;
    }
    _source = list.join().trim();
  }

  void solveAll() {
    foundWords.clear();
    foundWords.addAll(possibleWords);
  }

  int get length => _source.length;

  String get sourceLetters => _source;

  String get gameScore =>
      GameScoreCalc.calcScore(possibleWords, foundWords).toString();
}

class GameTimer {
  final Function _onTimeExpired;
  final Function _onTimeTick;
  final int time;
  int _seconds = 3 * 60;
  StreamSubscription _streamSubscription;
  bool _paused = false;

  String get gameTime {
    int mins = ((_seconds % 3600) ~/ 60);
    int seconds = _seconds % 60;
    return mins >= 10
        ? '$mins'
        : '0$mins' + ':' + (seconds >= 10 ? '$seconds' : '0$seconds');
  }

  bool get isTimeExpired => _seconds == 0;

  bool get isPaused => _paused;

  GameTimer(this._onTimeExpired, this._onTimeTick, [this.time = 3 * 60]);

  void restartTimer() {
    _seconds = time;
    dispose();
    _streamSubscription =
        new Stream.periodic(new Duration(seconds: 1))
            .where((d) => !_paused)
            .listen((d) {
          _seconds--;
          _onTimeTick();
          if (_seconds == 0) {
            _onTimeExpired();
            _streamSubscription.cancel();
          }
        });
  }

  void togglePause() {
    _paused = !_paused;
  }

  void dispose() {
    _streamSubscription?.cancel();
  }
}

class GameScoreCalc {
  static const int _kMaxWords = 200;

  static int calcScore(Iterable<String> possibleWords,
      Iterable<String> foundWords) {
    if (foundWords.isEmpty) return 0;
    int multiplier = (1 / (possibleWords.length / _kMaxWords)).round();
    return foundWords.map((w) => w.length * multiplier).reduce((l, r) => l + r);
  }
}
