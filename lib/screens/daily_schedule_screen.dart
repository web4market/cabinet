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

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _debugInfo = 'Загрузка расписания...';
    });

    try {
      print('🔄 Загрузка дневного расписания...');

      // Используем period='today' для получения расписания на сегодня
      final response = await _apiService.getScheduleJson(period: 'today');

      print('📦 Ответ от API: $response');

      if (response['success'] == true) {
        final data = response['data'];

        if (data is List && data.isNotEmpty) {
          // Берем первый элемент массива
          final scheduleData = data[0];
          setState(() {
            _schedule = DailySchedule.fromJson(scheduleData);
            _isLoading = false;
            _debugInfo = '✅ Загружено ${_schedule!.activities.length} занятий';
          });
          print('✅ Расписание загружено: ${_schedule!.title}');
        } else {
          setState(() {
            _schedule = null;
            _isLoading = false;
            _debugInfo = 'ℹ️ На сегодня занятий нет';
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
    return Column(
      children: [
        // Заголовок с информацией о расписании
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _schedule!.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Всего занятий: ${_schedule!.activities.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ),

        // Список занятий
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: _schedule!.activities.length,
            itemBuilder: (context, index) {
              final activity = _schedule!.activities[index];
              return _buildActivityCard(activity, index);
            },
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

  Widget _buildActivityCard(Activity activity, int index) {
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
              // Время и номер занятия
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      activity.timeRange,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
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
                      'Занятие ${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Название занятия
              Text(
                activity.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),

              // Кабинет и специалист
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

              SizedBox(height: 8),

              // Длительность
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.grey.shade500),
                  SizedBox(width: 4),
                  Text(
                    activity.durationText,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
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
                SizedBox(height: 8),

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