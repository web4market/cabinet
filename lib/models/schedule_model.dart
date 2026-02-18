class ScheduleModel {
  final int id;
  final String pName;
  final DateTime startH;
  final int frontuser;
  final List<ActivityModel> activities;

  ScheduleModel({
    required this.id,
    required this.pName,
    required this.startH,
    required this.frontuser,
    required this.activities,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    print('📦 ScheduleModel.fromJson: $json');

    var activitiesList = <ActivityModel>[];
    if (json['activities'] != null && json['activities'] is List) {
      activitiesList = (json['activities'] as List)
          .map((item) => ActivityModel.fromJson(item))
          .toList();
    }

    return ScheduleModel(
      id: json['id'] ?? 0,
      pName: json['p_name'] ?? '',
      startH: DateTime.parse(json['start_h'] ?? DateTime.now().toIso8601String()),
      frontuser: json['frontuser'] ?? 0,
      activities: activitiesList,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(startH.year, startH.month, startH.day);

    if (date == today) return 'Сегодня';
    if (date == today.add(Duration(days: 1))) return 'Завтра';
    if (date == today.subtract(Duration(days: 1))) return 'Вчера';

    return '${startH.day}.${startH.month}.${startH.year}';
  }

  String get dayOfWeek {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return days[startH.weekday - 1];
  }

  String get startTime => '${startH.hour.toString().padLeft(2, '0')}:${startH.minute.toString().padLeft(2, '0')}';
}

class ActivityModel {
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

  ActivityModel({
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

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
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

  String get displayName => actName ?? textincell ?? 'Занятие';

  String get timeRange {
    if (startT != null && endT != null) return '$startT - $endT';
    if (startT != null) return startT!;
    return 'Время не указано';
  }
}