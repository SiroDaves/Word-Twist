import 'package:word_twist/data/user_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsImpl implements UserPrefs {
  SharedPreferences sharedPrefs;

  UserPrefsImpl() {
    SharedPreferences.getInstance().then((v) => sharedPrefs = v);
  }

  @override
  int getInt(String key) => sharedPrefs.getInt(key);

  @override
  bool getBool(String key) => sharedPrefs.getBool(key);

  @override
  void setValue<T>(String key, T value) {
    switch (T.runtimeType) {
      case int:
        sharedPrefs.setInt(key, value as int);
        break;
      case bool:
        sharedPrefs.setBool(key, value as bool);
        break;
      default:        
    }
  }
}
