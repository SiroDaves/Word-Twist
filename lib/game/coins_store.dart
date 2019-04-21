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

  bool scoreChanged(int newScore) {
    final coins = newScore ~/ _kPoints;
    final old = _lastScore == 0 ? 0 : _lastScore ~/ _lastScore;
    _lastScore = newScore;
    if (coins > old) {
      _coinEarned();
    }
    return coins > old;
  }

  void _coinEarned() {    
    _coins++;
    _userPrefs.setValue(_kCoinsKey, _coins);
  }

  bool consumeCoins(int amount) {
    if (amount > _coins) {
      return false;
    }
    _coins -= amount;
    _userPrefs.setValue(_kCoinsKey, _coins);
    return true;
  }
}
