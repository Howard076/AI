import 'package:flutter/material.dart';

import 'splash_screen.dart';
import 'home_screen.dart';

void main() {
  runApp(const AI4LifeApp());
}

class AI4LifeApp extends StatelessWidget {
  const AI4LifeApp({super.key});

  // Tạo NavigatorKey để có thể điều hướng
  // mà không phụ thuộc vào context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Gắn navigatorKey vào MaterialApp
      navigatorKey: navigatorKey,

      home: SplashScreen(
        onFinished: () {
          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
      ),
    );
  }
}
