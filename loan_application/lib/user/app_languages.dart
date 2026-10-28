import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  static String current = "English";

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    current = prefs.getString("language") ?? "English";
  }

  static bool get isMyanmar => current == "Myanmar";

  static String text(String en, String mm) {
    return isMyanmar ? mm : en;
  }
}