import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';
import 'services/api_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Кабинет Адели',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder(
        future: ApiService.getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data != null) {
            return MainMenuScreen();
          }
          return LoginScreen();
        },
      ),
    );
  }
}