import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

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

  // Периоды для фильтрации
  final List<String> _periods = ['today', 'week', 'month', 'all'];
  String _currentPeriod = 'week';

  final Map<String, String> _periodNames = {
    'today': 'Сегодня',
    'week': 'Неделя',
    'month': 'Месяц',
    'all': 'Всё'
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadSchedule();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentPeriod = _periods[_tabController.index];
      });
      _loadSchedule();
    }
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔄 Загрузка расписания за период: $_currentPeriod');

      final response = await _apiService.getScheduleJson(period: _currentPeriod);

      print('📦 Ответ от API: $response');

      if (response['success'] == true) {
        // API возвращает {success: true, data: [...]}
        final data = response['data'];

        if (data is List) {
          setState(() {
            _scheduleItems = data;
            _groupedSchedule = _groupScheduleByDate(data);
            _isLoading = false;
          });
          print('✅ Загружено ${data.length} записей');
        } else {
          setState(() {
            _scheduleItems = [];
            _groupedSchedule = {};
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Ошибка загрузки';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Ошибка: $e');
      setState(() {
        _error = 'Ошибка соединения: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _groupScheduleByDate(List<dynamic> items) {
    Map<String, dynamic> grouped = {};

    for (var item in items) {
      // Получаем дату из start_h
      String date = '';
      if (item['start_h'] != null) {
        date = item['start_h'].split(' ')[0]; // "2024-01-15 09:00:00" -> "2024-01-15"
      } else {
        date = 'Неизвестно';
      }

      if (!grouped.containsKey(date)) {
        grouped[date] = {
          'date': date,
          'date_formatted': _formatDate(date),
          'day_of_week': _getDayOfWeek(date),
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

  String _formatDate(String date) {
    if (date == 'Неизвестно') return date;
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}.${parts[1]}.${parts[0]}';
      }
    } catch (e) {}
    return date;
  }

  String _getDayOfWeek(String date) {
    if (date == 'Неизвестно') return '';
    try {
      final dateTime = DateTime.parse(date);
      const days = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
      return days[dateTime.weekday - 1];
    } catch (e) {
      return '';
    }
  }

  String _getTimeFromStartH(String? startH) {
    if (startH == null) return '--:--';
    try {
      final parts = startH.split(' ');
      if (parts.length > 1) {
        return parts[1].substring(0, 5); // "09:00"
      }
    } catch (e) {}
    return '--:--';
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
          isScrollable: true,
          tabs: [
            Tab(text: 'Сегодня'),
            Tab(text: 'Неделя'),
            Tab(text: 'Месяц'),
            Tab(text: 'Всё'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSchedule,
            tooltip: 'Обновить',
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
    if (_groupedSchedule.isEmpty) {
      return _buildEmptyWidget();
    }

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
                      group['date'].split('-').last,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
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
                  ),
                ],
              ),
            ),

            // Занятия за эту дату
            ...group['items'].map<Widget>((item) => _buildScheduleCard(item)).toList(),

            SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildScheduleCard(dynamic item) {
    final time = _getTimeFromStartH(item['start_h']);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showScheduleDetail(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Время
              Container(
                width: 70,
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 12),

              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['p_name'] ?? 'Занятие',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item['activities'] != null && item['activities'].isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Активностей: ${item['activities'].length}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
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
          SizedBox(height: 24),
          Text(
            'Период: ${_periodNames[_currentPeriod]}',
            style: TextStyle(color: Colors.blue),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
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
        title: Text(schedule['p_name'] ?? 'Детали занятия'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Дата и время',
              content: schedule['start_h'] ?? 'Не указано',
            ),

            if (schedule['activities'] != null && schedule['activities'].isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Активности:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ...schedule['activities'].map<Widget>((activity) =>
                  _buildActivityCard(activity)
              ).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blue),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
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
      ),
    );
  }

  Widget _buildActivityCard(dynamic activity) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(
            activity['id_cell']?.toString() ?? '?',
            style: TextStyle(color: Colors.green.shade800),
          ),
        ),
        title: Text(activity['act_name'] ?? 'Активность'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity['description'] != null)
              Text(activity['description']),
            if (activity['start_t'] != null || activity['end_t'] != null)
              Text(
                '${activity['start_t'] ?? ''} - ${activity['end_t'] ?? ''}',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
/*
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
*/