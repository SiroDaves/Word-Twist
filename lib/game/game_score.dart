import 'dart:math';

import 'package:word_twist/game/twist.dart';

class GameScore {
  static const int _kWordLenFactor = 100;

  int _score = 0;
  GameMode _gameMode;
  int _scoreMultiplier;

  int get score => _score;

  void _newGame(GameMode gameMode, List<String> possibleWords) {
    _score = 0;
    _gameMode = gameMode;
    final divisor = min(1, (possibleWords.length / _kWordLenFactor));
    _scoreMultiplier = (1 / divisor).round();
    if (gameMode == GameMode.hard) {
      _scoreMultiplier += max((_scoreMultiplier ~/ 2), 2);
    }
  }

  void onWordFound(String word) {
    if (_gameMode != GameMode.unlimited) {
      _score += word.length * _scoreMultiplier;
    }
  }

  void onWordMissed(String falseWord) {
    if (_gameMode == GameMode.hard) {
      _score -= falseWord.length * _scoreMultiplier;
    }
  }

  void _onWordTwist() {
    if (_gameMode == GameMode.hard) {
      _score -= _scoreMultiplier;
    }
  }
}