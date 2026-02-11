import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/menu_card.dart';
import 'login_screen.dart';

class MainMenuScreen extends StatelessWidget {
  void _logout(BuildContext context) async {
    await ApiService.deleteToken();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Меню'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MenuCard(
              icon: Icons.calendar_month,
              title: 'Расписание занятий',
              onTap: () {
                // Здесь будет переход на экран расписания
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Раздел в разработке')),
                );
              },
            ),
            MenuCard(
              icon: Icons.school,
              title: 'Назначенные курсы',
              onTap: () {
                // Переход на курсы
              },
            ),
            MenuCard(
              icon: Icons.assignment,
              title: 'Заполнить анкету',
              onTap: () {
                // Переход на анкету
              },
            ),
          ],
        ),
      ),
    );
  }
}