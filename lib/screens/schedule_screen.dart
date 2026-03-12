import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/schedule_model.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  PatientSchedule? _schedule;
  bool _isLoading = true;
  String? _error;

  final List<ScheduleMode> _modes = [
    ScheduleMode.today,
    ScheduleMode.tomorrow,
    ScheduleMode.all,
  ];

  int _selectedModeIndex = 0;
  List<String> _availableDates = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _modes.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadSchedule();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedModeIndex = _tabController.index;
      });
      _loadSchedule();
    }
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _availableDates = [];
    });

    try {
      print('🔄 Загрузка расписания...');

      String period = _modes[_selectedModeIndex].apiPeriod;
      final response = await _apiService.getSchedule(period: period);

      print('📦 Ответ: $response');

      if (response['success'] == true) {
        final schedule = PatientSchedule.fromJson(response);

        // Для period=all нам нужно получить даты из верхнего уровня или из данных
        List<String> dates = [];

        if (period == 'all') {
          // Для всех дней используем даты из данных (если есть)
          // или показываем всё как один день
          if (schedule.data.isNotEmpty) {
            // Проверяем, есть ли даты в данных
            bool hasDates = schedule.data.any((a) => a.date.isNotEmpty);
            if (hasDates) {
              dates = schedule.availableDates;
            } else {
              // Если нет дат, создаем одну виртуальную дату
              dates = ['all'];
            }
          }
        } else {
          // Для today/tomorrow используем дату из верхнего уровня
          if (schedule.date != null) {
            dates = [schedule.date!];
          }
        }

        setState(() {
          _schedule = schedule;
          _availableDates = dates;
          _isLoading = false;
        });

        print('✅ Загружено активностей: ${schedule.data.length}');
        print('📅 Даты: $_availableDates');

        if (schedule.data.isNotEmpty) {
          final first = schedule.data.first;
          print('   Пример: ${first.service} в ${first.time}');
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
        _error = 'Ошибка соединения';
        _isLoading = false;
      });
    }
  }

  List<Activity> _getActivitiesForCurrentMode() {
    if (_schedule == null) return [];

    switch (_modes[_selectedModeIndex]) {
      case ScheduleMode.today:
        final today = DateTime.now().toIso8601String().split('T').first;
        if (_schedule!.date == today) {
          return _schedule!.data;
        }
        // Если нет точной даты, показываем все (для теста)
        return _schedule!.data;

      case ScheduleMode.tomorrow:
        final tomorrow = DateTime.now()
            .add(Duration(days: 1))
            .toIso8601String()
            .split('T')
            .first;
        if (_schedule!.date == tomorrow) {
          return _schedule!.data;
        }
        return [];

      case ScheduleMode.all:
        return _schedule!.data;
    }
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
          tabs: _modes.map((mode) => Tab(text: mode.title)).toList(),
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 14),
        ),
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
              : _schedule == null || _schedule!.data.isEmpty
                  ? _buildEmptyWidget()
                  : _buildScheduleWidget(),
    );
  }

  Widget _buildScheduleWidget() {
    final activities = _getActivitiesForCurrentMode();

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'Нет занятий ${_modes[_selectedModeIndex].title.toLowerCase()}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // Группируем по пациентам
    final byPatient = activities.groupByPatient();

    return ListView(
      padding: EdgeInsets.all(12),
      children: byPatient.entries
          .map((entry) => _buildPatientCard(entry.key, entry.value))
          .toList(),
    );
  }

  Widget _buildPatientCard(String patientGuid, List<Activity> activities) {
    final firstActivity = activities.first;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация о пациенте
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade200,
                  child: Text(
                    firstActivity.initials,
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstActivity.childName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        firstActivity.relation,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (activities.length > 1)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${activities.length}',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Список занятий
          ...activities
              .map((activity) => _buildActivityCard(activity))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return InkWell(
      onTap: () => _showActivityDetail(activity),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            // Время
            Container(
              width: 70,
              child: Column(
                children: [
                  Text(
                    activity.time,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    activity.durationText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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
                    activity.service,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14, color: Colors.grey.shade500),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.employees.main.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (activity.hasAdditionalEmployee) ...[
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.people,
                            size: 12, color: Colors.grey.shade500),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'ассистент: ${activity.employees.additional!.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.meeting_room,
                          size: 14, color: Colors.grey.shade500),
                      SizedBox(width: 4),
                      Text(
                        'Каб. ${activity.cabinet}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
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

                // Заголовок
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        activity.initials,
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.childName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            activity.relation,
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

                SizedBox(height: 20),

                // Детали
                _buildDetailRow('Услуга', activity.service),
                _buildDetailRow('Время', activity.timeRange),
                _buildDetailRow('Длительность', activity.durationText),
                _buildDetailRow('Специалист', activity.employees.main.name),
                if (activity.hasAdditionalEmployee)
                  _buildDetailRow(
                      'Ассистент', activity.employees.additional!.name),
                _buildDetailRow('Кабинет', 'Каб. ${activity.cabinet}'),

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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15),
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
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Нет занятий',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSchedule,
            icon: Icon(Icons.refresh),
            label: Text('Обновить'),
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

/// Режимы отображения расписания
enum ScheduleMode {
  today,
  tomorrow,
  all;

  String get title {
    switch (this) {
      case ScheduleMode.today:
        return 'Сегодня';
      case ScheduleMode.tomorrow:
        return 'Завтра';
      case ScheduleMode.all:
        return 'Все дни';
    }
  }

  String get apiPeriod {
    switch (this) {
      case ScheduleMode.today:
        return 'today';
      case ScheduleMode.tomorrow:
        return 'tomorrow';
      case ScheduleMode.all:
        return 'all';
    }
  }
}
