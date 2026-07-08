import 'package:calc_app/auth/main_page.dart';
//flutter code connection to google firebase services
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

//async tells flutter don't show ui we have to set heavy background
void main() async {
  //connect flutter engine to android or ios completely
  WidgetsBinding a = WidgetsFlutterBinding.ensureInitialized();
  //given reference a to the splashScreen to show photos/animations
  FlutterNativeSplash.preserve(widgetsBinding: a);

  // 2. Initialize Firebase
  await Firebase.initializeApp();

  // 3. remove the splashScreen after getting backend services
  FlutterNativeSplash.remove();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
    );
  }
}