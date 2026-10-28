import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_languages.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  bool notificationEnabled = true;
  bool darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      notificationEnabled =
          prefs.getBool("notification") ?? true;

      darkModeEnabled =
          prefs.getBool("darkMode") ?? false;
    });
  }


  Future<void> saveNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notification", value);

    setState(() {
      notificationEnabled = value;
    });
  }


  Future<void> saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("darkMode", value);

    setState(() {
      darkModeEnabled = value;
    });

    // Later connect this with ThemeProvider
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
      darkModeEnabled
          ? const Color(0xff121212)
          : Colors.white,

      appBar: AppBar(
        title: Text(
          AppLanguage.text(
            "Settings",
            "ဆက်တင်များ",
          ),
          style: TextStyle(
            color: darkModeEnabled
                ? Colors.white
                : Colors.black,
          ),
        ),

        backgroundColor:
        darkModeEnabled
            ? const Color(0xff121212)
            : Colors.white,

        foregroundColor:
        darkModeEnabled
            ? Colors.white
            : Colors.black,
      ),


      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          Card(
            color: darkModeEnabled
                ? Colors.grey[900]
                : Colors.white,

            child: SwitchListTile(
              secondary: Icon(
                Icons.notifications,
                color: darkModeEnabled
                    ? Colors.white
                    : Colors.black,
              ),

              title: Text(
                AppLanguage.text(
                  "Notifications",
                  "အသိပေးချက်များ",
                ),
                style: TextStyle(
                  color: darkModeEnabled
                      ? Colors.white
                      : Colors.black,
                ),
              ),

              subtitle: Text(
                notificationEnabled
                    ? AppLanguage.text(
                  "Enabled",
                  "ဖွင့်ထားသည်",
                )
                    : AppLanguage.text(
                  "Disabled",
                  "ပိတ်ထားသည်",
                ),
                style: TextStyle(
                  color: darkModeEnabled
                      ? Colors.grey
                      : Colors.grey[700],
                ),
              ),

              activeColor: Colors.blue,

              value: notificationEnabled,

              onChanged: (value){
                saveNotification(value);
              },
            ),
          ),



          Card(
            color: darkModeEnabled
                ? Colors.grey[900]
                : Colors.white,

            child: SwitchListTile(

              secondary: Icon(
                Icons.dark_mode,
                color: darkModeEnabled
                    ? Colors.white
                    : Colors.black,
              ),

              title: Text(
                AppLanguage.text(
                  "Dark Mode",
                  "အမှောင် Mode",
                ),
                style: TextStyle(
                  color: darkModeEnabled
                      ? Colors.white
                      : Colors.black,
                ),
              ),

              subtitle: Text(
                darkModeEnabled
                    ? AppLanguage.text(
                  "Dark theme enabled",
                  "အမှောင်Themeဖွင့်ထားသည်",
                )
                    : AppLanguage.text(
                  "Light theme enabled",
                  "အလင်းThemeဖွင့်ထားသည်",
                ),
                style: TextStyle(
                  color: darkModeEnabled
                      ? Colors.grey
                      : Colors.grey[700],
                ),
              ),

              activeColor: Colors.blue,

              value: darkModeEnabled,

              onChanged: (value){
                saveDarkMode(value);
              },

            ),
          ),


        ],
      ),
    );
  }
}