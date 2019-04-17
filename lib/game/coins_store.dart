import 'package:shared_preferences/shared_preferences.dart';

const _kPoints = 100;

class CoinsStore {
  
  int _lastScore = 0;

  bool scoreChanged(int newScore) {
    final coins = newScore ~/ _kPoints;
    final old = _lastScore ~/ _lastScore;
    _lastScore = newScore;
    return coins > old;
  }
}