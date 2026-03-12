class DailySchedule {
  final int id;
  final String title;
  final String startTime; // Это время начала дня (обычно 08:00)
  final int userId;
  final List<Activity> activities;

  DailySchedule({
    required this.id,
    required this.title,
    required this.startTime,
    required this.userId,
    required this.activities,
  });

  factory DailySchedule.fromJson(Map<String, dynamic> json) {
    print('📦 DailySchedule.fromJson START');

    // Безопасное преобразование id
    int scheduleId = 0;
    if (json['id'] != null) {
      if (json['id'] is int) {
        scheduleId = json['id'];
      } else if (json['id'] is String) {
        scheduleId = int.tryParse(json['id']) ?? 0;
      }
    }

    // Безопасное преобразование userId
    int userId = 0;
    if (json['frontuser'] != null) {
      if (json['frontuser'] is int) {
        userId = json['frontuser'];
      } else if (json['frontuser'] is String) {
        userId = int.tryParse(json['frontuser']) ?? 0;
      }
    }

    // Создаем активности
    var activitiesList = <Activity>[];
    if (json['activities'] != null && json['activities'] is List) {
      activitiesList = (json['activities'] as List)
          .map((item) => Activity.fromJson(item))
          .toList();
    }

    return DailySchedule(
      id: scheduleId,
      title: json['p_name']?.toString() ?? 'Расписание',
      startTime: json['start_h']?.toString() ?? '08:00',
      userId: userId,
      activities: activitiesList,
    );
  }

  // Получаем имя пациента из заголовка
  String get patientName {
    final parts = title.split('для пациента: ');
    return parts.length > 1 ? parts[1].trim() : 'Пациент';
  }

  // Группируем активности по дням на основе id_cell и дат из активностей
  Map<String, List<Activity>> get activitiesByDay {
    print('📅 Группировка активностей по дням...');
    print('   Всего активностей: ${activities.length}');

    final Map<String, List<Activity>> grouped = {};

    // Сначала собираем все уникальные даты из активностей
    Set<String> uniqueDates = {};
    for (var activity in activities) {
      // Извлекаем дату из start_t? Но в данных нет даты в активности.
      // Значит, дата определяется по id_cell

      // Определяем день по id_cell
      int dayIndex = (activity.cellId ~/ 1000) - 1;
      if (dayIndex < 0) dayIndex = 0;

      // Создаем ключ для дня (пока просто "День X")
      String dayKey = 'День ${dayIndex + 1}';

      if (!grouped.containsKey(dayKey)) {
        grouped[dayKey] = [];
      }
      grouped[dayKey]!.add(activity);
    }

    // Сортируем активности в каждом дне по времени
    grouped.forEach((key, list) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    print('📊 Результат группировки: ${grouped.length} дней');
    grouped.forEach((key, list) {
      print('   $key: ${list.length} активностей');
      // Покажем первую активность для примера
      if (list.isNotEmpty) {
        print('      Пример: ${list.first.name} в ${list.first.startTime}');
      }
    });

    return grouped;
  }

  // Если нужно получить массив дат для отображения
  List<String> get dayLabels {
    return activitiesByDay.keys.toList();
  }

  // Количество дней
  int get daysCount => activitiesByDay.length;
}

class Activity {
  final int id;
  final int? activityId;
  final int cellId;
  final int merge;
  final String startTime;
  final String endTime;
  final String textInCell;
  final int duration;
  final String name;
  final String description;

  Activity({
    required this.id,
    this.activityId,
    required this.cellId,
    required this.merge,
    required this.startTime,
    required this.endTime,
    required this.textInCell,
    required this.duration,
    required this.name,
    required this.description,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    print('📦 Activity.fromJson START');
    print('   Все ключи: ${json.keys}');

    // Детально проверяем каждое поле
    print('   id: ${json['id']} (${json['id'].runtimeType})');
    print(
        '   id_activity: ${json['id_activity']} (${json['id_activity'].runtimeType})');
    print('   id_cell: ${json['id_cell']} (${json['id_cell'].runtimeType})');
    print('   merge: ${json['merge']} (${json['merge'].runtimeType})');
    print('   duration: ${json['duration']} (${json['duration'].runtimeType})');
    print('   start_t: ${json['start_t']} (${json['start_t'].runtimeType})');
    print('   end_t: ${json['end_t']} (${json['end_t'].runtimeType})');
    print('   act_name: ${json['act_name']} (${json['act_name'].runtimeType})');

    try {
      // БЕЗОПАСНОЕ ПРЕОБРАЗОВАНИЕ ТИПОВ
      int id = _parseInt(json['id'], 'id');
      int? activityId = json['id_activity'] != null
          ? _parseInt(json['id_activity'], 'id_activity')
          : null;
      int cellId = _parseInt(json['id_cell'], 'id_cell');
      int merge = _parseInt(json['merge'], 'merge');
      int duration = _parseInt(json['duration'], 'duration');

      print('✅ После преобразования:');
      print('   id -> $id (${id.runtimeType})');
      print('   activityId -> $activityId (${activityId.runtimeType})');
      print('   cellId -> $cellId (${cellId.runtimeType})');
      print('   merge -> $merge (${merge.runtimeType})');
      print('   duration -> $duration (${duration.runtimeType})');

      return Activity(
        id: id,
        activityId: activityId,
        cellId: cellId,
        merge: merge,
        startTime: json['start_t']?.toString() ?? '--:--',
        endTime: json['end_t']?.toString() ?? '--:--',
        textInCell: _cleanHtmlText(json['textincell']?.toString() ?? ''),
        duration: duration,
        name: json['act_name']?.toString() ?? 'Занятие',
        description: _cleanHtmlText(json['description']?.toString() ?? ''),
      );
    } catch (e, stackTrace) {
      print('❌ ОШИБКА В Activity.fromJson: $e');
      print('📚 Stack trace: $stackTrace');
      print('📦 Проблемный JSON: $json');
      rethrow;
    }
  }

// УЛУЧШЕННЫЙ МЕТОД ПРЕОБРАЗОВАНИЯ С ОТЛАДКОЙ
  static int _parseInt(dynamic value, String fieldName) {
    print('   🔍 Парсинг $fieldName: "$value" (${value.runtimeType})');

    if (value == null) {
      print('   ⚠️ $fieldName = null -> возвращаем 0');
      return 0;
    }

    if (value is int) {
      print('   ✅ $fieldName уже int: $value');
      return value;
    }

    if (value is double) {
      int result = value.toInt();
      print('   ✅ $fieldName был double, стал int: $result');
      return result;
    }

    if (value is String) {
      String trimmed = value.trim();
      if (trimmed.isEmpty) {
        print('   ⚠️ $fieldName пустая строка -> 0');
        return 0;
      }

      try {
        int result = int.parse(trimmed);
        print('   ✅ $fieldName строка -> int: $result');
        return result;
      } catch (e) {
        try {
          double result = double.parse(trimmed);
          int intResult = result.toInt();
          print('   ⚠️ $fieldName строка -> double -> int: $intResult');
          return intResult;
        } catch (e) {
          print('   ❌ НЕ УДАЛОСЬ преобразовать $fieldName "$value" в число');
          return 0;
        }
      }
    }

    print('   ❌ Неизвестный тип для $fieldName: ${value.runtimeType}');
    return 0;
  }

  // Очистка HTML тегов из текста
  static String _cleanHtmlText(String html) {
    if (html.isEmpty) return '';

    // Удаляем HTML теги
    String text = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    // Заменяем множественные пробелы на один
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    // Декодируем HTML сущности
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    return text.trim();
  }

  String get timeRange => '$startTime - $endTime';
  String get durationText => '$duration мин';

  String get room {
    final text = textInCell.isNotEmpty ? textInCell : description;
    final lines =
        text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) return lines[0].trim();
    return 'Кабинет не указан';
  }

  String get specialist {
    final text = textInCell.isNotEmpty ? textInCell : description;
    final lines =
        text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.length > 1) return lines[1].trim();
    return 'Специалист не указан';
  }
}
