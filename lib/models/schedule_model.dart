import 'package:flutter/material.dart';

/// Модель расписания для пациента
class PatientSchedule {
  final bool success;
  final List<dynamic> data; // может быть List<Activity> или List<ScheduleDay>
  final int total;
  final int userId;
  final int timestamp;
  final int? totalDays;
  final String? date;
  final String? formattedDate;
  final String? dayOfWeek;

  PatientSchedule({
    required this.success,
    required this.data,
    required this.total,
    required this.userId,
    required this.timestamp,
    this.totalDays,
    this.date,
    this.formattedDate,
    this.dayOfWeek,
  });

  factory PatientSchedule.fromJson(Map<String, dynamic> json) {
    print('📦 PatientSchedule.fromJson: ${json.keys}');

    // Определяем формат данных по наличию total_days
    bool isGrouped = json.containsKey('total_days');
    print('📌 Формат данных: ${isGrouped ? 'сгруппированный' : 'плоский'}');

    List<dynamic> parsedData = [];

    if (json['data'] != null && json['data'] is List) {
      if (isGrouped) {
        // Сгруппированный формат (для period=all)
        parsedData = (json['data'] as List)
            .map((item) => ScheduleDay.fromJson(item))
            .toList();
        print('📅 Загружено дней: ${parsedData.length}');
      } else {
        // Плоский формат (для today/tomorrow)
        parsedData = (json['data'] as List)
            .map((item) => Activity.fromJson(item))
            .toList();
        print('📅 Загружено активностей: ${parsedData.length}');
      }
    }

    return PatientSchedule(
      success: json['success'] ?? false,
      data: parsedData,
      total: _parseInt(json['total'] ?? json['total_days']),
      userId: _parseInt(json['user_id']),
      timestamp: _parseInt(json['timestamp']),
      totalDays: _parseInt(json['total_days']),
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

  /// Получить все активности (для today/tomorrow)
  List<Activity> get flatActivities {
    return data.whereType<Activity>().toList();
  }

  /// Получить все дни (для all)
  List<ScheduleDay> get days {
    return data.whereType<ScheduleDay>().toList();
  }

  /// Проверить, сгруппировано ли по дням
  bool get isGroupedByDay => data.isNotEmpty && data.first is ScheduleDay;
}

/// Модель дня расписания (для period=all)
class ScheduleDay {
  final String date;
  final String formattedDate;
  final String dayOfWeek;
  final List<PatientInfo> patients;

  ScheduleDay({
    required this.date,
    required this.formattedDate,
    required this.dayOfWeek,
    required this.patients,
  });

  factory ScheduleDay.fromJson(Map<String, dynamic> json) {
    print('📅 ScheduleDay.fromJson: ${json['date']}');

    var patientsList = <PatientInfo>[];
    if (json['patients'] != null && json['patients'] is List) {
      patientsList = (json['patients'] as List)
          .map((item) => PatientInfo.fromJson(item))
          .toList();
      print('   Пациентов в этот день: ${patientsList.length}');
    }

    return ScheduleDay(
      date: json['date'] ?? '',
      formattedDate: json['formatted_date'] ?? '',
      dayOfWeek: json['day_of_week'] ?? '',
      patients: patientsList,
    );
  }

  /// Получить все активности в этом дне (упрощенные)
  List<SimpleActivity> get simpleActivities {
    List<SimpleActivity> result = [];
    for (var patient in patients) {
      for (var activity in patient.activities) {
        result.add(SimpleActivity(
          time: activity.time,
          service: activity.service,
        ));
      }
    }
    // Сортируем по времени
    result.sort((a, b) => a.sortTime.compareTo(b.sortTime));
    return result;
  }

  /// Получить все активности в этом дне (полные)
  List<Activity> get fullActivities {
    List<Activity> result = [];
    for (var patient in patients) {
      result.addAll(patient.activities);
    }
    return result;
  }
}

/// Упрощенная модель для отображения в списке "Все дни"
class SimpleActivity {
  final String time;
  final String service;

  SimpleActivity({
    required this.time,
    required this.service,
  });

  int get sortTime {
    try {
      List<String> parts = time.split(':');
      if (parts.length >= 2) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    } catch (e) {}
    return 0;
  }
}

/// Модель информации о пациенте
class PatientInfo {
  final String patientGuid;
  final String patientName;
  final String childName;
  final String relation;
  final List<Activity> activities;

  PatientInfo({
    required this.patientGuid,
    required this.patientName,
    required this.childName,
    required this.relation,
    required this.activities,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    print('👤 PatientInfo.fromJson: ${json['patient_name']}');

    var activitiesList = <Activity>[];
    if (json['activities'] != null && json['activities'] is List) {
      activitiesList = (json['activities'] as List)
          .map((item) => Activity.fromJson(item))
          .toList();
    }

    return PatientInfo(
      patientGuid: json['patient_guid']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? '',
      childName: json['child_name']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '',
      activities: activitiesList,
    );
  }

  /// Получить инициалы для аватара
  String get initials {
    if (childName.isNotEmpty) {
      return childName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join();
    }
    return patientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join();
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
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    print('🏥 Activity.fromJson: ${json['service'] ?? 'null'}');

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
      List<String> parts = time.split(':');
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
