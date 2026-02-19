import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/course_model.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final ApiService _apiService = ApiService();

  List<CourseModel> _courses = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔄 Загрузка курсов...');

      final response = await _apiService.getCourses();

      if (response['success'] == true) {
        final List<dynamic> coursesData = response['data'] ?? [];
        setState(() {
          _courses = coursesData
              .map((c) => CourseModel.fromJson(c))
              .toList();
          _stats = response['stats'];
          _isLoading = false;
        });
        print('✅ Загружено ${_courses.length} курсов');
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
        title: Text('Назначенные курсы'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCourses,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : _buildCoursesList(),
    );
  }

  Widget _buildCoursesList() {
    if (_courses.isEmpty) {
      return _buildEmptyWidget();
    }

    return Column(
      children: [
        // Статистика
        if (_stats != null) _buildStatsWidget(),

        // Список курсов
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: _courses.length,
            itemBuilder: (context, index) {
              final course = _courses[index];
              return _buildCourseCard(course);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Всего',
            _stats!['total']?.toString() ?? '0',
            Colors.blue,
            Icons.assignment,
          ),
          _buildStatItem(
            'Выполнено',
            _stats!['completed']?.toString() ?? '0',
            Colors.green,
            Icons.check_circle,
          ),
          _buildStatItem(
            'В обработке',
            _stats!['processing']?.toString() ?? '0',
            Colors.orange,
            Icons.hourglass_empty,
          ),
          _buildStatItem(
            'Отменено',
            _stats!['cancelled']?.toString() ?? '0',
            Colors.red,
            Icons.cancel,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    final status = course.parsedData.status ?? 'Неизвестно';
    final statusColor = course.parsedData.statusColor;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и статус
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Заявка №${course.id}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          course.parsedData.statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Пациент
              if (course.parsedData.patientName != null) ...[
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        course.parsedData.patientName!,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
              ],

              // Даты
              if (course.parsedData.startDate != null || course.parsedData.endDate != null) ...[
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${course.parsedData.startDate ?? '?'} - ${course.parsedData.endDate ?? '?'}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
              ],

              // Регистрация
              if (course.parsedData.registrationDate != null) ...[
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Зарегистрирован: ${course.parsedData.registrationDate}',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
              onPressed: _loadCourses,
              icon: Icon(Icons.refresh),
              label: Text('Повторить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
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
          Icon(Icons.assignment, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Нет назначенных курсов',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'У вас пока нет назначенных курсов',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCourses,
            icon: Icon(Icons.refresh),
            label: Text('Обновить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}