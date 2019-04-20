abstract class UserPrefs {
    int getInt(String key);
    bool getBool(String key);
    void setValue<T>(String key, T value);
}