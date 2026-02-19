import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course_model.dart';

class CourseDetailScreen extends StatelessWidget {
  final CourseModel course;

  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = course.parsedData;

    return Scaffold(
      appBar: AppBar(
        title: Text('Заявка №${course.id}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статус
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: data.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: data.statusColor),
              ),
              child: Row(
                children: [
                  Icon(
                    data.statusIcon,
                    color: data.statusColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Статус заявки',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          data.status ?? 'Неизвестно',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: data.statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Основная информация
            _buildSection(
              'Информация о заявке',
              [
                _buildInfoRow('Номер заявки', data.ticketNumber ?? '—'),
                _buildInfoRow('Номер записи', data.recordNumber ?? '—'),
                _buildInfoRow('Дата регистрации', data.registrationDate ?? '—'),
              ],
            ),

            // Информация о курсе
            _buildSection(
              'Информация о курсе',
              [
                _buildInfoRow('Дата начала', data.startDate ?? '—'),
                _buildInfoRow('Дата окончания', data.endDate ?? '—'),
              ],
            ),

            // Пациент и клиент
            _buildSection(
              'Участники',
              [
                _buildInfoRow('Пациент', data.patientName ?? '—'),
                _buildInfoRow('Клиент', data.clientName ?? '—'),
              ],
            ),

            // Контакты
            if (data.contacts.isNotEmpty) ...[
              _buildSection(
                'Контакты',
                data.contacts.map((contact) =>
                    _buildContactRow(context, contact)
                ).toList(),
              ),
            ],

            // Полное описание
            if (course.content.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(
                'Полное описание',
                style: TextStyle(
                  fontSize: 18,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: course.content.map((line) =>
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $line',
                          style: TextStyle(fontSize: 14),
                        ),
                      )
                  ).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, Contact contact) {
    IconData icon = contact.type == 'phone'
        ? Icons.phone
        : Icons.email;
    Color color = contact.type == 'phone'
        ? Colors.green
        : Colors.blue;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () async {
          final Uri launchUri = contact.type == 'phone'
              ? Uri(scheme: 'tel', path: contact.value)
              : Uri(scheme: 'mailto', path: contact.value);

          if (await canLaunchUrl(launchUri)) {
            await launchUrl(launchUri);
          }
        },
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                contact.display,
                style: TextStyle(
                  color: color,
                  decoration: TextDecoration.underline,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}