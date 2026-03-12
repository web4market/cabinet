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
    ScheduleMode.all, // Возвращаем "Все дни"
  ];

  int _selectedModeIndex = 0;

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
    });

    try {
      print('🔄 Загрузка расписания...');

      late final Map<String, dynamic> response;

      switch (_modes[_selectedModeIndex]) {
        case ScheduleMode.today:
          response = await _apiService.getSchedule(period: 'today');
          break;
        case ScheduleMode.tomorrow:
          response = await _apiService.getSchedule(period: 'tomorrow');
          break;
        case ScheduleMode.all:
          response = await _apiService.getSchedule(period: 'all');
          break;
      }

      print('📦 Ответ: $response');

      if (response['success'] == true) {
        final schedule = PatientSchedule.fromJson(response);
        setState(() {
          _schedule = schedule;
          _isLoading = false;
        });

        print('✅ Загружено активностей: ${schedule.data.length}');
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
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSchedule,
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
    if (_schedule == null) return _buildEmptyWidget();

    // Для today и tomorrow используем старый формат (плоский список)
    if (_selectedModeIndex < 2) {
      if (_schedule!.flatActivities.isEmpty) {
        return _buildEmptyWidget();
      }
      return _buildTodayTomorrowWidget();
    }
    // Для all используем новый формат (сгруппированный)
    else {
      return _buildAllDaysWidget();
    }
  }

  /// Для сегодня и завтра - полная информация
  Widget _buildTodayTomorrowWidget() {
    // Группируем активности по пациентам
    final Map<String, List<Activity>> byPatient = {};
    for (var activity in _schedule!.data) {
      if (!byPatient.containsKey(activity.patientGuid)) {
        byPatient[activity.patientGuid] = [];
      }
      byPatient[activity.patientGuid]!.add(activity);
    }

    // Сортируем активности для каждого пациента
    byPatient.forEach((key, list) {
      list.sort((a, b) => a.sortTime.compareTo(b.sortTime));
    });

    return ListView(
      padding: EdgeInsets.all(12),
      children: byPatient.entries
          .map((entry) => _buildPatientCard(entry.key, entry.value))
          .toList(),
    );
  }

  /// Для всех дней - упрощенное отображение (только дата, время и название)
  Widget _buildAllDaysWidget() {
    if (_schedule == null || !_schedule!.isGroupedByDay) {
      print('⚠️ Нет данных для отображения всех дней');
      return _buildEmptyWidget();
    }

    final days = _schedule!.days;
    print('📊 Дней для отображения: ${days.length}');

    if (days.isEmpty) {
      return _buildEmptyWidget();
    }

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final activities = day.simpleActivities;

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с датой
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.blue.shade700),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        day.formattedDate,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    Text(
                      day.dayOfWeek,
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Список процедур (только время и название)
              ...activities
                  .map(
                    (activity) => Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            child: Text(
                              activity.time,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              activity.service,
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),

              if (activities.isEmpty)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Нет процедур в этот день',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
                        Icon(Icons.person_outline,
                            size: 14, color: Colors.grey.shade500),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.employees.additional!.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
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
                        activity.cabinet,
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
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              activity.service,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildDetailRow('Пациент', activity.childName),
            _buildDetailRow('Время', activity.timeRange),
            _buildDetailRow('Длительность', activity.durationText),
            _buildDetailRow('Специалист', activity.employees.main.name),
            if (activity.hasAdditionalEmployee)
              _buildDetailRow(
                  'Специалист', activity.employees.additional!.name),
            _buildDetailRow('Кабинет', activity.cabinet),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Закрыть'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    if (date == 'Без даты') return date;
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}.${parts[1]}.${parts[0]}';
      }
    } catch (e) {}
    return date;
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
}
