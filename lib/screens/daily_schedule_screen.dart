import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/daily_schedule_model.dart';

class DailyScheduleScreen extends StatefulWidget {
  @override
  _DailyScheduleScreenState createState() => _DailyScheduleScreenState();
}

class _DailyScheduleScreenState extends State<DailyScheduleScreen> {
  final ApiService _apiService = ApiService();

  DailySchedule? _schedule;
  bool _isLoading = true;
  String? _error;
  String? _debugInfo;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  // lib/screens/daily_schedule_screen.dart - используем getFullSchedule

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _debugInfo = 'Загрузка расписания...';
    });

    try {
      print('🔄 Загрузка полного расписания...');

      // Используем getFullSchedule() вместо getScheduleJson()
      final response = await _apiService.getFullSchedule();

      print('📦 Ответ от API: $response');

      if (response['success'] == true) {
        final data = response['data'];

        if (data is List && data.isNotEmpty) {
          // Берем первый элемент (в вашем случае он один)
          final scheduleData = data[0];
          print('📦 Данные расписания: $scheduleData');

          final schedule = DailySchedule.fromJson(scheduleData);

          setState(() {
            _schedule = schedule;
            _isLoading = false;
            _debugInfo = '✅ Загружено ${schedule.activities.length} занятий';
          });

          print('✅ Расписание загружено: ${schedule.title}');
          print('📊 Всего активностей: ${schedule.activities.length}');

          // Показываем распределение по дням
          final byDay = schedule.activitiesByDay;
          byDay.forEach((day, acts) {
            print('📊 $day: ${acts.length} активностей');
          });

        } else {
          print('ℹ️ Нет данных расписания');
          setState(() {
            _schedule = null;
            _isLoading = false;
            _debugInfo = 'ℹ️ Расписание не найдено';
          });
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Ошибка загрузки';
          _isLoading = false;
          _debugInfo = '❌ Ошибка: ${response['message']}';
        });
      }

    } catch (e) {
      print('❌ Ошибка: $e');
      setState(() {
        _error = 'Ошибка соединения';
        _isLoading = false;
        _debugInfo = '❌ Исключение: $e';
      });
    }
  }

  // Группируем активности по времени для удобного отображения
  Map<String, List<Activity>> _groupActivitiesByTime() {
    if (_schedule == null || _schedule!.activities.isEmpty) {
      return {};
    }

    final grouped = <String, List<Activity>>{};

    // Определяем период дня по времени
    for (var activity in _schedule!.activities) {
      String period;
      final hour = int.tryParse(activity.startTime.split(':')[0]) ?? 0;

      if (hour < 12) {
        period = 'Утро';
      } else if (hour < 17) {
        period = 'День';
      } else {
        period = 'Вечер';
      }

      if (!grouped.containsKey(period)) {
        grouped[period] = [];
      }
      grouped[period]!.add(activity);
    }

    // Сортируем активности внутри каждой группы по времени
    grouped.forEach((key, list) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Расписание на сегодня'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSchedule,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : _schedule == null
          ? _buildEmptyWidget()
          : _buildScheduleWidget(),
    );
  }

  Widget _buildScheduleWidget() {
    final groupedActivities = _groupActivitiesByTime();

    return Column(
      children: [
        // Информационная карточка
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue.shade700),
                  SizedBox(width: 8),
                  Text(
                    'Дата: ', // ${_schedule!.scheduleDate}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                _schedule!.patientName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Всего процедур: ${_schedule!.activities.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),

        // Список активностей
        Expanded(
          child: groupedActivities.isEmpty
              ? Center(child: Text('Нет активностей'))
              : ListView(
            padding: EdgeInsets.all(12),
            children: groupedActivities.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  ...entry.value.map((activity) => _buildActivityCard(activity)),
                ],
              );
            }).toList(),
          ),
        ),

        // Отладочная информация (можно убрать в продакшене)
        if (_debugInfo != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            color: Colors.grey.shade200,
            child: Text(
              _debugInfo!,
              style: TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showActivityDetail(activity),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Время
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      activity.timeRange,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      activity.durationText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Название
              Text(
                activity.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),

              // Кабинет
              Row(
                children: [
                  Icon(Icons.meeting_room, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      activity.room,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 4),

              // Специалист
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      activity.specialist,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),

              // Разделитель, если есть дополнительная информация
              if (activity.textInCell.isNotEmpty && activity.textInCell.split('\n').length > 2) ...[
                SizedBox(height: 8),
                Divider(),
                SizedBox(height: 4),
                Text(
                  'Подробнее...',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityDetail(Activity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                Text(
                  activity.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                _buildDetailRow(Icons.access_time, 'Время', activity.timeRange),
                _buildDetailRow(Icons.timer, 'Длительность', activity.durationText),
                _buildDetailRow(Icons.meeting_room, 'Кабинет', activity.room),
                _buildDetailRow(Icons.person, 'Специалист', activity.specialist),

                if (activity.textInCell.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Дополнительная информация:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(activity.textInCell),
                  ),
                ],

                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Закрыть'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 45),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _error ?? 'Попробуйте позже',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSchedule,
              icon: Icon(Icons.refresh),
              label: Text('Повторить'),
            ),
            if (_debugInfo != null) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: Text(
                  _debugInfo!,
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'На сегодня занятий нет',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Расписание обновляется ежедневно',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSchedule,
            icon: Icon(Icons.refresh),
            label: Text('Обновить'),
          ),
          if (_debugInfo != null) ...[
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.grey.shade200,
              child: Text(
                _debugInfo!,
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}