import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/schedule_card.dart';
// Убираем импорт schedule_item.dart, так как он не используется напрямую

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  List<dynamic> _scheduleItems = [];
  Map<String, dynamic> _groupedSchedule = {};
  bool _isLoading = true;
  String? _error;

  // Фильтры
  String _currentPeriod = 'week'; // week, month, all
  final List<String> _periods = ['week', 'month', 'all'];
  final Map<String, String> _periodNames = {
    'week': 'Неделя',
    'month': 'Месяц',
    'all': 'Всё'
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getSchedule(period: _currentPeriod);

      if (response['success'] == true) {
        setState(() {
          _scheduleItems = response['items'] ?? [];
          _groupedSchedule = _groupScheduleByDate(_scheduleItems);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Ошибка загрузки';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка соединения: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _groupScheduleByDate(List<dynamic> items) {
    Map<String, dynamic> grouped = {};

    for (var item in items) {
      String date = item['date'];
      if (!grouped.containsKey(date)) {
        grouped[date] = {
          'date': date,
          'date_formatted': item['date_display'],
          'day_of_week': item['day_of_week'],
          'items': []
        };
      }
      grouped[date]['items'].add(item);
    }

    // Сортируем даты
    var sortedKeys = grouped.keys.toList()..sort();
    Map<String, dynamic> sortedGrouped = {};
    for (var key in sortedKeys) {
      sortedGrouped[key] = grouped[key];
    }

    return sortedGrouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Расписание занятий'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Неделя'),
            Tab(text: 'Месяц'),
            Tab(text: 'Всё'),
          ],
          onTap: (index) {
            setState(() {
              _currentPeriod = _periods[index];
            });
            _loadSchedule();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSchedule,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSchedule,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorWidget()
            : _scheduleItems.isEmpty
            ? _buildEmptyWidget()
            : _buildScheduleList(),
      ),
    );
  }

  Widget _buildScheduleList() {
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: _groupedSchedule.length,
      itemBuilder: (context, index) {
        String dateKey = _groupedSchedule.keys.elementAt(index);
        var group = _groupedSchedule[dateKey];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок даты
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      group['date'].split('-')[2],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['date_formatted'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        group['day_of_week'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Занятия за эту дату
            ...group['items'].map<Widget>((item) => ScheduleCard(
              schedule: item,
              onTap: () => _showScheduleDetail(item),
            )).toList(),

            SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
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
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Нет занятий',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'На выбранный период занятий не найдено',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showScheduleDetail(dynamic item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleDetailScreen(schedule: item),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Экран деталей занятия
class ScheduleDetailScreen extends StatelessWidget {
  final dynamic schedule;

  const ScheduleDetailScreen({Key? key, required this.schedule}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(schedule['activity_name'] ?? 'Занятие'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Дата и время
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule['date_display'] ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        schedule['day_of_week'] ?? '',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Начало: ${schedule['time'] ?? ''}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Информация о занятии
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'Занятие',
              content: schedule['activity_name'] ?? 'Не указано',
            ),

            _buildInfoCard(
              icon: Icons.person_outline,
              title: 'Преподаватель',
              content: schedule['teacher'] ?? 'Не указан',
            ),

            _buildInfoCard(
              icon: Icons.meeting_room,
              title: 'Кабинет',
              content: schedule['room'] ?? 'Не указан',
            ),

            if (schedule['description'] != null && schedule['description'].isNotEmpty)
              _buildInfoCard(
                icon: Icons.description,
                title: 'Описание',
                content: schedule['description'],
              ),

            if (schedule['duration'] != null)
              _buildInfoCard(
                icon: Icons.timer,
                title: 'Длительность',
                content: '${schedule['duration']} мин',
              ),

            SizedBox(height: 20),

            // Статус
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: schedule['is_past'] == true
                    ? Colors.grey.shade100
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: schedule['is_past'] == true
                      ? Colors.grey.shade300
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    schedule['is_past'] == true
                        ? Icons.check_circle_outline
                        : Icons.access_time,
                    color: schedule['is_past'] == true
                        ? Colors.grey
                        : Colors.green,
                  ),
                  SizedBox(width: 12),
                  Text(
                    schedule['is_past'] == true
                        ? 'Занятие прошло'
                        : schedule['is_today'] == true
                        ? 'Сегодня'
                        : 'Предстоит',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: schedule['is_past'] == true
                          ? Colors.grey
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
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
}