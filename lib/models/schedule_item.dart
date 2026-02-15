class ScheduleItem {
  final int id;
  final String pName;
  final DateTime startH;
  final int frontuser;
  final List<ActivityItem> activities;

  ScheduleItem({
    required this.id,
    required this.pName,
    required this.startH,
    required this.frontuser,
    required this.activities,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    var activitiesList = <ActivityItem>[];
    if (json['activities'] != null) {
      activitiesList = (json['activities'] as List)
          .map((item) => ActivityItem.fromJson(item))
          .toList();
    }

    return ScheduleItem(
      id: json['id'] ?? 0,
      pName: json['p_name'] ?? '',
      startH: DateTime.parse(json['start_h'] ?? DateTime.now().toIso8601String()),
      frontuser: json['frontuser'] ?? 0,
      activities: activitiesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'p_name': pName,
      'start_h': startH.toIso8601String(),
      'frontuser': frontuser,
      'activities': activities.map((a) => a.toJson()).toList(),
    };
  }

  // Форматированная дата для отображения
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(startH.year, startH.month, startH.day);

    if (date == today) {
      return 'Сегодня';
    } else if (date == today.add(Duration(days: 1))) {
      return 'Завтра';
    } else if (date == today.subtract(Duration(days: 1))) {
      return 'Вчера';
    } else {
      return '${startH.day}.${startH.month}.${startH.year}';
    }
  }

  // День недели
  String get dayOfWeek {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return days[startH.weekday - 1];
  }

  // Время начала
  String get startTime {
    return '${startH.hour.toString().padLeft(2, '0')}:${startH.minute.toString().padLeft(2, '0')}';
  }
}

class ActivityItem {
  final int id;
  final int? idActivity;
  final int idCell;
  final int? merge;
  final String? startT;
  final String? endT;
  final String? textincell;
  final int? duration;
  final String? actName;
  final String? description;

  ActivityItem({
    required this.id,
    this.idActivity,
    required this.idCell,
    this.merge,
    this.startT,
    this.endT,
    this.textincell,
    this.duration,
    this.actName,
    this.description,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] ?? 0,
      idActivity: json['id_activity'],
      idCell: json['id_cell'] ?? 0,
      merge: json['merge'],
      startT: json['start_t'],
      endT: json['end_t'],
      textincell: json['textincell'],
      duration: json['duration'],
      actName: json['act_name'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_activity': idActivity,
      'id_cell': idCell,
      'merge': merge,
      'start_t': startT,
      'end_t': endT,
      'textincell': textincell,
      'duration': duration,
      'act_name': actName,
      'description': description,
    };
  }

  // Отображаемое имя активности
  String get displayName {
    return actName ?? textincell ?? 'Занятие';
  }

  // Время проведения
  String get timeRange {
    if (startT != null && endT != null) {
      return '$startT - $endT';
    } else if (startT != null) {
      return startT!;
    } else {
      return 'Время не указано';
    }
  }
}