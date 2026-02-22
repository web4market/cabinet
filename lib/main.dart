import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';
import 'services/api_service.dart';
import 'package:flutter/services.dart' show rootBundle;

void checkAsset() async {
  try {
    await rootBundle.load('assets/images/Adeli-logo101.png');
    print('✅ Логотип найден');
  } catch (e) {
    print('❌ Логотип не найден: $e');
  }
}
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Кабинет Адели',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Небольшая задержка для показа сплэша
    await Future.delayed(Duration(seconds: 1));

    if (!mounted) return;

    // Проверяем, есть ли токен и валиден ли он
    final token = await ApiService.getToken();

    if (token != null) {
      final isValid = await _apiService.checkToken();
      if (isValid && mounted) {
        // Токен валиден - переходим в меню
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainMenuScreen()),
        );
        return;
      }
    }

    // Токена нет или он недействителен - на экран входа
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 250,
                height: 150,
                  child: Image.asset(
                    'assets/images/Adeli-logo101.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Ошибка загрузки логотипа: $error');
                      // Если изображение не загрузилось, показываем иконку
                      return Container(
                        color: Colors.blue,
                        child: Icon(
                          Icons.diversity_3,
                          size: 60,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
              ),
              SizedBox(height: 32),
              Text(
                'Личный кабинет',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }
}