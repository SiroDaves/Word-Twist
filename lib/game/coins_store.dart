import 'package:word_twist/data/user_prefs.dart';

const _kPoints = 100;
const _kCoinsKey = 'coins';
const kCoinsForOneMin = 5;

class CoinsStore {
  final UserPrefs _userPrefs;

  int _lastScore = 0;
  int _coins = 0;

  int get coins => _coins;

  CoinsStore(this._userPrefs) {
    _coins = _userPrefs.getInt(_kCoinsKey) ?? 20;
  }

  int scoreChanged(int newScore) {
    final newVal = newScore ~/ _kPoints;
    final oldVal = _lastScore == 0 ? 0 : _lastScore ~/ _kPoints;
    _lastScore = newScore;
    if (newVal > oldVal) {
      coinEarned(newVal - oldVal);
    }
    return newVal - oldVal;
  }

  void coinEarned(int amount) {    
    _coins += amount;
    _userPrefs.setInt(_kCoinsKey, _coins);
  }

  bool consumeCoins(int amount) {
    if (amount > _coins) {
      return false;
    }
    _coins -= amount;
    _userPrefs.setInt(_kCoinsKey, _coins);
    return true;
  }

  void reset() {
    _lastScore = 0;
  }
}
