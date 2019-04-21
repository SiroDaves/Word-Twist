abstract class UserPrefs {
    int getInt(String key);
    bool getBool(String key);
    void setInt(String key, int value);
    void setBool(String key, bool value);
}