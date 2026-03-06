import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/menu_card.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';
import 'courses_screen.dart';
import 'help_screen.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

class MainMenuScreen extends StatelessWidget {
  void _logout(BuildContext context) async {
    // Показываем диалог подтверждения
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Выход'),
        content: Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Выйти'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      await ApiService.deleteToken();

      if (context.mounted) {
        Navigator.of(context).pop(); // Закрываем индикатор
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Главное меню',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Кнопка профиля
          IconButton(
            icon: Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
            tooltip: 'Профиль',
          ),
          // Кнопка выхода
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _logout(context),
            tooltip: 'Выход',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Приветственная карточка
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Добро пожаловать!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Выберите нужный раздел',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Карточки меню

              // lib/screens/main_menu_screen.dart - обновите переход на расписание

              MenuCard(
                icon: Icons.calendar_month,
                title: 'Расписание занятий',
                description: 'Просмотр расписания',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ScheduleScreen()),
                  );
                },
              ),

              MenuCard(
                icon: Icons.school,
                title: 'Назначенные курсы',
                description: 'Список ваших курсов и прогресс',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CoursesScreen()),
                  );
                },
              ),

              MenuCard(
                icon: Icons.help_outline,
                title: 'Помощь',
                description: 'Руководство пользователя',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HelpScreen()),
                  );
                },
              ),

              MenuCard(
                icon: Icons.system_update,
                title: 'Проверить обновления',
                description: 'Поиск новой версии приложения',
                color: Colors.purple,
                onTap: () async {
                  final updateService = UpdateService();
                  final versionInfo = await updateService.checkForUpdates();

                  if (versionInfo != null) {
                    if (updateService.isUpdateAvailable) {
                      showDialog(
                        context: context,
                        builder: (context) => UpdateDialog(
                          versionInfo: versionInfo,
                          isRequired: versionInfo.isRequired,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('У вас последняя версия приложения'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Не удалось проверить обновления'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
