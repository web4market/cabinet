import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'main_menu_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Проверяем, может уже есть сохраненный токен
    _checkExistingToken();
  }

  Future<void> _checkExistingToken() async {
    final token = await ApiService.getToken();
    if (token != null) {
      // Проверяем, валиден ли токен
      final isValid = await _apiService.checkToken();
      if (isValid && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainMenuScreen()),
        );
      }
    }
  }

  void _login() async {
    // Скрываем клавиатуру
    FocusScope.of(context).unfocus();

    // Валидация формы
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Попытка входа: ${_loginController.text}');

      final result = await _apiService.login(
        _loginController.text.trim(),
        _passwordController.text.trim(),
      );

      print('Результат авторизации: $result');

      if (result['success'] == true && mounted) {
        // Успешная авторизация
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainMenuScreen()),
        );
      } else {
        // Ошибка авторизации
        setState(() {
          _errorMessage = result['error'] ?? 'Неверный логин или пароль';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка при авторизации: $e');
      setState(() {
        _errorMessage = 'Ошибка подключения к серверу';
        _isLoading = false;
      });
    }
  }

  String? _validateLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите логин';
    }
    if (value.length < 3) {
      return 'Логин должен быть не менее 3 символов';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    if (value.length < 4) {
      return 'Пароль должен быть не менее 4 символов';
    }
    return null;
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Логотип Адели вместо иконки
                    Container(
                      width: 250,
                      height: 150,

                      child: ClipOval(
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
                    ),
                    SizedBox(height: 40),

                    Text(
                      'Личный кабинет',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Адели Пенза',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 40),

                    // Поле логина
                    TextFormField(
                      controller: _loginController,
                      validator: _validateLogin,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Логин',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        errorStyle: TextStyle(color: Colors.red.shade700),
                      ),
                      enabled: !_isLoading,
                    ),
                    SizedBox(height: 16),

                    // Поле пароля
                    TextFormField(
                      controller: _passwordController,
                      validator: _validatePassword,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        errorStyle: TextStyle(color: Colors.red.shade700),
                      ),
                      enabled: !_isLoading,
                    ),

                    // Сообщение об ошибке
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 24),

                    // Кнопка входа
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Вход...'),
                          ],
                        )
                            : Text(
                          'Войти',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}