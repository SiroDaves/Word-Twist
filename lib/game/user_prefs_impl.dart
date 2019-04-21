import 'package:word_twist/data/user_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsImpl implements UserPrefs {
  SharedPreferences sharedPrefs;
  static UserPrefsImpl _instance;

  bool get isLoaded => sharedPrefs != null;

  static UserPrefsImpl instance() {
    if (_instance == null) {
      _instance = UserPrefsImpl();
    }
    return _instance;
  }

  Future init() async {
    sharedPrefs = await SharedPreferences.getInstance();
  }

  @override
  int getInt(String key) => sharedPrefs.getInt(key);

  @override
  bool getBool(String key) => sharedPrefs.getBool(key);

  @override
  void setBool(String key, bool value) {
    sharedPrefs.setBool(key, value);
  }

  @override
  void setInt(String key, int value) {
    sharedPrefs.setInt(key, value);
  }
}
