import 'package:calc_app/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    // No Scaffold here on purpose — HomePage and AuthPage each already
    // provide their own Scaffold. Wrapping them in another Scaffold made
    // THIS the true top-level Scaffold in the app, and since it never set
    // resizeToAvoidBottomInset: false, it resized (and dragged HomePage's
    // bottom nav bar upward) every time a keyboard opened anywhere below it.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const HomePage();
        } else {
          return const AuthPage();
        }
      },
    );
  }
}