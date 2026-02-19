import 'package:flutter/material.dart';

class CourseModel {
  final int id;
  final int userId;
  final List<String> content;
  final ParsedCourseData parsedData;

  CourseModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.parsedData,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    print('📦 CourseModel.fromJson: $json');

    // Безопасное преобразование id в int
    int courseId = 0;
    if (json['id'] != null) {
      if (json['id'] is int) {
        courseId = json['id'];
      } else if (json['id'] is String) {
        courseId = int.tryParse(json['id']) ?? 0;
      }
    }

    // Безопасное преобразование user_id в int
    int userId = 0;
    if (json['user_id'] != null) {
      if (json['user_id'] is int) {
        userId = json['user_id'];
      } else if (json['user_id'] is String) {
        userId = int.tryParse(json['user_id']) ?? 0;
      }
    }

    return CourseModel(
      id: courseId,
      userId: userId,
      content: json['content'] != null
          ? List<String>.from(json['content'])
          : [],
      parsedData: ParsedCourseData.fromJson(json['parsed_data'] ?? {}),
    );
  }
}

class ParsedCourseData {
  final String? ticketNumber;
  final String? registrationDate;
  final String? recordNumber;
  final String? startDate;
  final String? endDate;
  final String? patientName;
  final String? clientName;
  final String? status;
  final List<Contact> contacts;

  ParsedCourseData({
    this.ticketNumber,
    this.registrationDate,
    this.recordNumber,
    this.startDate,
    this.endDate,
    this.patientName,
    this.clientName,
    this.status,
    required this.contacts,
  });

  factory ParsedCourseData.fromJson(Map<String, dynamic> json) {
    // Безопасное преобразование record_number в строку
    String? recordNumber;
    if (json['record_number'] != null) {
      recordNumber = json['record_number'].toString();
    }

    return ParsedCourseData(
      ticketNumber: json['ticket_number']?.toString(),
      registrationDate: json['registration_date']?.toString(),
      recordNumber: recordNumber,
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      patientName: json['patient_name']?.toString(),
      clientName: json['client_name']?.toString(),
      status: json['status']?.toString(),
      contacts: json['contacts'] != null
          ? (json['contacts'] as List)
          .map((c) => Contact.fromJson(c))
          .toList()
          : [],
    );
  }

  // Цвет статуса
  Color get statusColor {
    switch (status) {
      case 'Выполнена':
        return Colors.green;
      case 'В обработке':
        return Colors.orange;
      case 'Отменена':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Иконка статуса
  IconData get statusIcon {
    switch (status) {
      case 'Выполнена':
        return Icons.check_circle;
      case 'В обработке':
        return Icons.hourglass_empty;
      case 'Отменена':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}

class Contact {
  final String type;
  final String value;
  final String display;

  Contact({
    required this.type,
    required this.value,
    required this.display,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      type: json['type'] ?? '',
      value: json['value'] ?? '',
      display: json['display'] ?? '',
    );
  }

  // Действие при нажатии
  void launch(context) {
    if (type == 'phone') {
      // Звонок
      // можно добавить url_launcher пакет
    } else if (type == 'email') {
      // Email
    }
  }
}