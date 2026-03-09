// расписание по дням
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/daily_schedule_model.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ApiService _apiService = ApiService();

  DailySchedule? _schedule;
  bool _isLoading = true;
  String? _error;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedDayIndex = 0;
    });

    try {
      print('🔄 ===== НАЧАЛО ЗАГРУЗКИ РАСПИСАНИЯ =====');
      print('⏰ Время: ${DateTime.now()}');

      final response = await _apiService.getSchedule();

      print('📦 Сырой ответ от API: $response');
      print('📦 Тип response: ${response.runtimeType}');
      print('📦 Ключи response: ${response.keys}');

      if (response['success'] == true) {
        print('✅ success = true');

        final data = response['data'];
        print('📦 data тип: ${data.runtimeType}');

        if (data is List) {
          print('📦 data длина: ${data.length}');

          if (data.isNotEmpty) {
            print('📦 data[0] тип: ${data[0].runtimeType}');
            print('📦 data[0] содержимое: ${data[0]}');

            print('🔄 Пытаемся создать DailySchedule...');

            try {
              final scheduleData = data[0];
              print('   scheduleData тип: ${scheduleData.runtimeType}');
              print('   scheduleData ключи: ${scheduleData.keys}');

              // Проверяем наличие обязательных полей
              print(
                  '   id: ${scheduleData['id']} (${scheduleData['id'].runtimeType})');
              print(
                  '   p_name: ${scheduleData['p_name']} (${scheduleData['p_name'].runtimeType})');
              print(
                  '   frontuser: ${scheduleData['frontuser']} (${scheduleData['frontuser'].runtimeType})');

              if (scheduleData['activities'] != null) {
                print(
                    '   activities тип: ${scheduleData['activities'].runtimeType}');
                print(
                    '   activities длина: ${(scheduleData['activities'] as List).length}');
              }

              final schedule = DailySchedule.fromJson(scheduleData);
              print('✅ DailySchedule создан успешно!');

              setState(() {
                _schedule = schedule;
                _isLoading = false;
              });

              print('✅ Загружено ${schedule.activities.length} активностей');
              print('📅 Дней в расписании: ${schedule.activitiesByDay.length}');
            } catch (e, stackTrace) {
              print('❌ ОШИБКА ПРИ СОЗДАНИИ DailySchedule: $e');
              print('📚 Stack trace: $stackTrace');
              print('📦 Проблемные данные: ${data[0]}');

              setState(() {
                _error = 'Ошибка обработки данных: $e';
                _isLoading = false;
              });
            }
          } else {
            print('ℹ️ Массив data пуст');
            setState(() {
              _schedule = null;
              _isLoading = false;
            });
          }
        } else {
          print('❌ data не является списком: ${data.runtimeType}');
          setState(() {
            _error = 'Неверный формат данных от сервера';
            _isLoading = false;
          });
        }
      } else {
        print('❌ success = false, message: ${response['message']}');
        setState(() {
          _error = response['message'] ?? 'Ошибка загрузки';
          _isLoading = false;
        });
      }

      print('🔄 ===== КОНЕЦ ЗАГРУЗКИ =====');
    } catch (e, stackTrace) {
      print('❌ КРИТИЧЕСКАЯ ОШИБКА В _loadSchedule: $e');
      print('📚 Stack trace: $stackTrace');
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
              : _schedule == null
                  ? _buildEmptyWidget()
                  : _buildScheduleWidget(),
    );
  }

  Widget _buildScheduleWidget() {
    print('🏗 _buildScheduleWidget START');
    final activitiesByDay = _schedule!.activitiesByDay;
    print('   activitiesByDay тип: ${activitiesByDay.runtimeType}');
    final dates = activitiesByDay.keys.toList();
    print('   dates: $dates');

    if (dates.isEmpty) {
      return Center(child: Text('Нет активностей'));
    }
    print(
        '   Выбранный день: $_selectedDayIndex, дата: ${dates[_selectedDayIndex]}');
    final currentDayActivities = activitiesByDay[dates[_selectedDayIndex]];
    print('   currentDayActivities тип: ${currentDayActivities.runtimeType}');

    if (currentDayActivities == null) {
      print(
          '❌ currentDayActivities = null для даты ${dates[_selectedDayIndex]}');
      return Center(child: Text('Ошибка загрузки активностей'));
    }

    print('   currentDayActivities длина: ${currentDayActivities.length}');

    // Проверяем первую активность
    if (currentDayActivities.isNotEmpty) {
      final first = currentDayActivities.first;
      print('   Первая активность:');
      print('      id: ${first.id} (${first.id.runtimeType})');
      print('      cellId: ${first.cellId} (${first.cellId.runtimeType})');
      print(
          '      startTime: ${first.startTime} (${first.startTime.runtimeType})');
      print(
          '      duration: ${first.duration} (${first.duration.runtimeType})');
    }

    return Column(
      children: [
        // Информационная карточка
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '👤 ${_schedule!.patientName}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '📅 Всего дней: ${dates.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ),

        // Переключатель дней (если больше одного дня)
        if (dates.length > 1)
          Container(
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: _selectedDayIndex > 0
                      ? () {
                          setState(() {
                            _selectedDayIndex--;
                          });
                        }
                      : null,
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'День ${_selectedDayIndex + 1} из ${dates.length}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dates[_selectedDayIndex],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: _selectedDayIndex < dates.length - 1
                      ? () {
                          setState(() {
                            _selectedDayIndex++;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),

        // Список активностей для выбранного дня
        Expanded(
          child: activitiesByDay[dates[_selectedDayIndex]]!.isEmpty
              ? Center(
                  child: Text(
                    'Нет занятий на этот день',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: activitiesByDay[dates[_selectedDayIndex]]!.length,
                  itemBuilder: (context, index) {
                    final activity =
                        activitiesByDay[dates[_selectedDayIndex]]![index];
                    return _buildActivityCard(activity, index);
                  },
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
              // Время
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${activity.startTime} - ${activity.endTime}',
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
                  Icon(Icons.meeting_room,
                      size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Кабинет ${activity.room}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),

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

              // Длительность
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity.durationText,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
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
                SizedBox(height: 16),
                _buildDetailRow(Icons.access_time, 'Время', activity.timeRange),
                _buildDetailRow(
                    Icons.timer, 'Длительность', activity.durationText),
                _buildDetailRow(
                    Icons.meeting_room, 'Кабинет', 'Кабинет ${activity.room}'),
                _buildDetailRow(
                    Icons.person, 'Специалист', activity.specialist),
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
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
        ],
      ),
    );
  }
}
