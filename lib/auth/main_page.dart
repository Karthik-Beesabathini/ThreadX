import 'package:calc_app/pages/home_page.dart';
import 'package:flutter/material.dart';
//getting firebaseAuth services
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    //returns two things either a valid firebase user object
    //or a null means no user logged in
    return StreamBuilder<User?>(
      //continuous stream listen authStateChanges
      stream: FirebaseAuth.instance.authStateChanges(),
      //builder builds everytime when authState happened
      builder: (context, snapshot) {
        //snapshot has latest data from authState changes
        if (snapshot.hasData) {
          return const HomePage();
        } else {
          return const AuthPage();
        }
      },
    );
  }
}