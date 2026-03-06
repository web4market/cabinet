import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();

  factory UpdateService() => _instance;

  UpdateService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://cabinet.adelipnz.ru/api',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
  ));

  PackageInfo? _packageInfo;
  VersionInfo? _versionInfo;

  // Инициализация - получаем информацию о текущем приложении
  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
    print('📱 Текущее приложение: ${_packageInfo?.appName}');
    print('📱 Версия: ${_packageInfo?.version}');
    print('📱 Build: ${_packageInfo?.buildNumber}');
  }

  // Проверка обновлений на сервере
  Future<VersionInfo?> checkForUpdates() async {
    try {
      print('🔍 Проверка обновлений...');

      final response = await _dio.get('/version.php');

      if (response.statusCode == 200 && response.data['success'] == true) {
        _versionInfo = VersionInfo.fromJson(response.data['data']);
        print('✅ Информация о версии получена');
        print('📦 Последняя версия: ${_versionInfo?.latestVersion}');
        return _versionInfo;
      }
    } catch (e) {
      print('❌ Ошибка проверки обновлений: $e');
    }
    return null;
  }

  // Сравнение версий
  bool get isUpdateAvailable {
    if (_packageInfo == null || _versionInfo == null) return false;

    String current = _packageInfo!.version;
    String latest = _versionInfo!.latestVersion;

    return _compareVersions(current, latest) < 0;
  }

  // Проверка, является ли текущая версия устаревшей (обязательное обновление)
  bool get isVersionDeprecated {
    if (_packageInfo == null || _versionInfo == null) return false;

    String current = _packageInfo!.version;
    String min = _versionInfo!.minVersion;

    return _compareVersions(current, min) < 0;
  }

  // Сравнение версий (возвращает -1, 0, 1)
  int _compareVersions(String v1, String v2) {
    List<int> parts1 = v1.split('.').map(int.parse).toList();
    List<int> parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < parts1.length && i < parts2.length; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }

    return parts1.length.compareTo(parts2.length);
  }

  // Скачивание обновления (открытие ссылки)
  Future<void> downloadUpdate() async {
    if (_versionInfo == null) return;

    final url = _versionInfo!.downloadUrl;
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // Получить информацию о текущей версии
  String get currentVersion => _packageInfo?.version ?? 'unknown';

  // Получить информацию о последней версии
  VersionInfo? get versionInfo => _versionInfo;
}

class VersionInfo {
  final String latestVersion;
  final String minVersion;
  final String releaseDate;
  final String downloadUrl;
  final List<String> releaseNotes;
  final bool isRequired;
  final String size;

  VersionInfo({
    required this.latestVersion,
    required this.minVersion,
    required this.releaseDate,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isRequired,
    required this.size,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      latestVersion: json['latest_version'] ?? '1.0.0',
      minVersion: json['min_version'] ?? '1.0.0',
      releaseDate: json['release_date'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      releaseNotes: List<String>.from(json['release_notes'] ?? []),
      isRequired: json['is_required'] ?? false,
      size: json['size'] ?? '0 MB',
    );
  }
}
