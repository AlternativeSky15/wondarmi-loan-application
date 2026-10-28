import 'package:flutter/material.dart';
import 'package:loan_application/user/info.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Home2.dart';
import 'login.dart';

class SessionPage extends StatelessWidget {
  const SessionPage({super.key});

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn =
        prefs.getBool("isLoggedIn") ?? false;

    return isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isLoggedIn(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data!) {
          return const HomePage();
        }

        return const IntroScreen(nextPage: LoginPage(),);
      },
    );
  }
}