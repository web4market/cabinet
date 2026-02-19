// lib/screens/diagnostic_schedule_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DiagnosticScheduleScreen extends StatefulWidget {
  @override
  _DiagnosticScheduleScreenState createState() => _DiagnosticScheduleScreenState();
}

class _DiagnosticScheduleScreenState extends State<DiagnosticScheduleScreen> {
  final ApiService _apiService = ApiService();
  String _result = 'Нажмите кнопку для теста';
  bool _loading = false;

  Future<void> _testSchedule() async {
    setState(() {
      _loading = true;
      _result = 'Запрос к API...';
    });

    try {
      final response = await _apiService.getScheduleTest();

      String responseStr = response.toString();
      String preview = responseStr.length > 500
          ? responseStr.substring(0, 500) + '...'
          : responseStr;

      setState(() {
        _result = '✅ Ответ получен:\n\n$preview';

        if (response['success'] == true) {
          final data = response['data'];
          if (data is List) {
            _result += '\n\n📊 data длина: ${data.length}';
            if (data.isNotEmpty) {
              _result += '\n✅ ЕСТЬ ДАННЫЕ!';
            } else {
              _result += '\n❌ data пустой';
            }
          }
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Ошибка: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Диагностика расписания'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _testSchedule,
              child: Text('Тестировать API расписания'),
            ),
            SizedBox(height: 20),
            if (_loading)
              CircularProgressIndicator()
            else
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _result,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}