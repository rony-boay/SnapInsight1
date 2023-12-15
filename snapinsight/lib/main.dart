import 'package:flutter/material.dart';
import 'package:snapinsight/splash_screen.dart';
import 'package:snapinsight/Summarypage.dart';
import 'package:snapinsight/MainWorking.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
 //     initialRoute: '/',
      routes: {
        '/first': (context) => ButtonPage(),
        '/second': (context) => ButtonSummaryPage(
              buttonPresses: [],
            ),
          
      },
    );
  }
}
