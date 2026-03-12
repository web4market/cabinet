// Модель расписания для пациента
class PatientSchedule {
  final bool success;
  final List<Activity> data;
  final int total;
  final int userId;
  final int timestamp;
  final String? date; // для period=today
  final String? formattedDate; // для period=today
  final String? dayOfWeek; // для period=today

  PatientSchedule({
    required this.success,
    required this.data,
    required this.total,
    required this.userId,
    required this.timestamp,
    this.date,
    this.formattedDate,
    this.dayOfWeek,
  });

  factory PatientSchedule.fromJson(Map<String, dynamic> json) {
    print('📦 PatientSchedule.fromJson: ${json.keys}');

    // Безопасное преобразование data
    List<Activity> activitiesList = [];
    if (json['data'] != null && json['data'] is List) {
      activitiesList = (json['data'] as List)
          .map((item) => Activity.fromJson(item))
          .toList();
    }

    return PatientSchedule(
      success: json['success'] ?? false,
      data: activitiesList,
      total: _parseInt(json['total']),
      userId: _parseInt(json['user_id']),
      timestamp: _parseInt(json['timestamp']),
      date: json['date']?.toString(),
      formattedDate: json['formatted_date']?.toString(),
      dayOfWeek: json['day_of_week']?.toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  /// Получить все уникальные даты из активностей
  List<String> get availableDates {
    Set<String> dates = {};
    for (var activity in data) {
      if (activity.date.isNotEmpty) {
        dates.add(activity.date);
      }
    }
    return dates.toList()..sort();
  }

  /// Получить активности для конкретной даты
  List<Activity> getActivitiesForDate(String targetDate) {
    return data.where((activity) => activity.date == targetDate).toList();
  }

  /// Получить активности, сгруппированные по датам
  Map<String, List<Activity>> get groupedByDate {
    final Map<String, List<Activity>> grouped = {};
    for (var activity in data) {
      if (activity.date.isEmpty) continue;
      if (!grouped.containsKey(activity.date)) {
        grouped[activity.date] = [];
      }
      grouped[activity.date]!.add(activity);
    }

    // Сортируем активности в каждой дате
    grouped.forEach((key, list) {
      list.sort((a, b) => a.sortTime.compareTo(b.sortTime));
    });

    return grouped;
  }

  /// Получить активности, сгруппированные по пациентам для конкретной даты
  Map<String, List<Activity>> getActivitiesByPatientForDate(String date) {
    final Map<String, List<Activity>> grouped = {};
    final activities = getActivitiesForDate(date);

    for (var activity in activities) {
      if (!grouped.containsKey(activity.patientGuid)) {
        grouped[activity.patientGuid] = [];
      }
      grouped[activity.patientGuid]!.add(activity);
    }

    // Сортируем активности для каждого пациента
    grouped.forEach((key, list) {
      list.sort((a, b) => a.sortTime.compareTo(b.sortTime));
    });

    return grouped;
  }
}

/// Модель активности (занятия)
class Activity {
  final int id;
  final String patientGuid;
  final String patientName;
  final String childName;
  final String relation;
  final String time;
  final String timeRange;
  final String timeStart;
  final String timeEnd;
  final Employees employees;
  final String cabinet;
  final String service;
  final int duration;
  final String date; // Дата, которую мы извлечем из API

  Activity({
    required this.id,
    required this.patientGuid,
    required this.patientName,
    required this.childName,
    required this.relation,
    required this.time,
    required this.timeRange,
    required this.timeStart,
    required this.timeEnd,
    required this.employees,
    required this.cabinet,
    required this.service,
    required this.duration,
    required this.date,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    print('🏥 Activity.fromJson: ${json['service']}');

    // Пытаемся получить дату из разных источников
    String activityDate = '';

    // Вариант 1: если есть поле date
    if (json.containsKey('date') && json['date'] != null) {
      activityDate = json['date'].toString();
    }
    // Вариант 2: если есть поле date в корне (для period=all его нет)
    // Вариант 3: пока пустая строка - будем группировать позже

    return Activity(
      id: _parseInt(json['id']),
      patientGuid: json['patient_guid']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? '',
      childName: json['child_name']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      timeRange: json['time_range']?.toString() ?? '',
      timeStart: json['time_start']?.toString() ?? '',
      timeEnd: json['time_end']?.toString() ?? '',
      employees: Employees.fromJson(json['employees'] ?? {}),
      cabinet: json['cabinet']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      duration: _parseInt(json['duration']),
      date: activityDate,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  /// Форматированная длительность
  String get durationText {
    if (duration <= 0) return '—';
    return '$duration мин';
  }

  /// Проверить, есть ли дополнительный сотрудник
  bool get hasAdditionalEmployee => employees.additional != null;

  /// Получить время для сортировки (в минутах от полуночи)
  int get sortTime {
    try {
      List<String> parts = timeStart.split(':');
      if (parts.length >= 2) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    } catch (e) {}
    return 0;
  }

  /// Получить инициалы пациента
  String get initials {
    if (childName.isNotEmpty) {
      return childName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join();
    }
    return patientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join();
  }
}

/// Модель сотрудников
class Employees {
  final Employee main;
  final Employee? additional;

  Employees({
    required this.main,
    this.additional,
  });

  factory Employees.fromJson(Map<String, dynamic> json) {
    return Employees(
      main: Employee.fromJson(json['main'] ?? {}),
      additional: json['additional'] != null
          ? Employee.fromJson(json['additional'])
          : null,
    );
  }

  /// Получить список всех сотрудников
  List<Employee> get all {
    List<Employee> list = [main];
    if (additional != null) list.add(additional!);
    return list;
  }

  /// Получить текстовое представление сотрудников
  String get employeesText {
    if (additional == null) return main.name;
    return '${main.name} + ${additional!.name}';
  }
}

/// Модель сотрудника
class Employee {
  final String name;
  final String guid;

  Employee({
    required this.name,
    required this.guid,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      name: json['name']?.toString() ?? '',
      guid: json['guid']?.toString() ?? '',
    );
  }
}

/// Расширения для списка активностей
extension ActivityListExtension on List<Activity> {
  /// Сортировка по времени
  List<Activity> sortByTime() {
    sort((a, b) => a.sortTime.compareTo(b.sortTime));
    return this;
  }

  /// Группировка по пациентам
  Map<String, List<Activity>> groupByPatient() {
    final Map<String, List<Activity>> grouped = {};
    for (var activity in this) {
      if (!grouped.containsKey(activity.patientGuid)) {
        grouped[activity.patientGuid] = [];
      }
      grouped[activity.patientGuid]!.add(activity);
    }
    return grouped;
  }

  /// Группировка по датам (если есть дата)
  Map<String, List<Activity>> groupByDate() {
    final Map<String, List<Activity>> grouped = {};
    for (var activity in this) {
      if (!grouped.containsKey(activity.date)) {
        grouped[activity.date] = [];
      }
      grouped[activity.date]!.add(activity);
    }
    return grouped;
  }
}
