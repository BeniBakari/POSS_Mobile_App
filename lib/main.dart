import 'package:flutter/material.dart';
import 'package:poss_mobile_app/pages/auth/login.dart';
import 'package:poss_mobile_app/pages/auth/registeration.dart';
import 'package:poss_mobile_app/pages/home.dart';
import 'package:poss_mobile_app/wrapper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POSS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 3, 16, 139)),
        useMaterial3: true,
      ),
      routes: {
        'login': (BuildContext context) => const Login(),
        'home': (BuildContext context) => const Home(),
        'registration': (BuildContext context) => const Registration()
      },
      home: const Wrapper(), // 👈 Wrapper is the entry point
    );
  }
}
