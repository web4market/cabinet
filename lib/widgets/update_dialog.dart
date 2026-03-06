import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final VersionInfo versionInfo;
  final bool isRequired;

  const UpdateDialog({
    Key? key,
    required this.versionInfo,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async =>
          !isRequired, // Запрещаем закрытие при обязательном обновлении
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: isRequired ? Colors.red : Colors.blue,
              size: 28,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                isRequired ? 'Обязательное обновление' : 'Доступно обновление',
                style: TextStyle(
                  color: isRequired ? Colors.red : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Информация о версиях
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildVersionRow(
                        'Текущая версия:',
                        UpdateService().currentVersion,
                        Icons.info_outline,
                      ),
                      SizedBox(height: 8),
                      _buildVersionRow(
                        'Новая версия:',
                        versionInfo.latestVersion,
                        Icons.new_releases,
                        highlight: true,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Размер
                Row(
                  children: [
                    Icon(Icons.sd_storage, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Размер: ${versionInfo.size}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Дата релиза
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Релиз: ${versionInfo.releaseDate}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Что нового
                if (versionInfo.releaseNotes.isNotEmpty) ...[
                  Text(
                    'Что нового:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                      children: versionInfo.releaseNotes
                          .map(
                            (note) => Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ', style: TextStyle(fontSize: 16)),
                                  Expanded(
                                    child: Text(
                                      note,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (!isRequired)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Позже'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
              UpdateService().downloadUpdate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isRequired ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Обновить сейчас'),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow(String label, String version, IconData icon,
      {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: highlight ? Colors.blue : Colors.grey),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        SizedBox(width: 8),
        Text(
          version,
          style: TextStyle(
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            color: highlight ? Colors.blue : Colors.black87,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
