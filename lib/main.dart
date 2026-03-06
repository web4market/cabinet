import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';
import 'services/api_service.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Инициализация сервиса обновлений
  await UpdateService().init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Кабинет клиента Адели-Пенза',
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
  final UpdateService _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Небольшая задержка для показа сплэша
    await Future.delayed(Duration(seconds: 1));
    // Проверяем обновления
    await _checkForUpdates();
    // Проверяем авторизацию
    await _checkAuth();
  }

  Future<void> _checkForUpdates() async {
    final versionInfo = await _updateService.checkForUpdates();

    if (versionInfo != null && mounted) {
      // Проверяем, обязательное ли обновление
      if (_updateService.isVersionDeprecated) {
        _showUpdateDialog(versionInfo, isRequired: true);
        return; // Не продолжаем, пока пользователь не обновится
      }

      // Если обновление доступно, показываем диалог
      if (_updateService.isUpdateAvailable) {
        _showUpdateDialog(versionInfo, isRequired: false);
      }
    }
  }

  void _showUpdateDialog(VersionInfo versionInfo, {required bool isRequired}) {
    showDialog(
      context: context,
      barrierDismissible:
          !isRequired, // Нельзя закрыть при обязательном обновлении
      builder: (context) => UpdateDialog(
        versionInfo: versionInfo,
        isRequired: isRequired,
      ),
    ).then((shouldUpdate) {
      if (shouldUpdate == true) {
        // Пользователь нажал "Обновить" - диалог уже открыл ссылку
        // Можно показать сообщение или просто продолжить
      } else if (isRequired) {
        // При обязательном обновлении пользователь не может отказаться
        _showUpdateDialog(versionInfo, isRequired: true);
      } else {
        // Пользователь выбрал "Позже" - продолжаем загрузку приложения
        _checkAuth();
      }
    });
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
                'Личный кабинет клиента',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Проверка обновлений...',
                style: TextStyle(color: Colors.grey.shade600),
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
