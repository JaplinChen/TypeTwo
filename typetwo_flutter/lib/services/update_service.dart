import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_constants.dart';

class UpdateInfo {
  final String version;
  final String releaseUrl;

  const UpdateInfo({required this.version, required this.releaseUrl});
}

class UpdateService {
  static const _apiUrl =
      'https://api.github.com/repos/JaplinChen/TypeTwo/releases/latest';

  static Future<UpdateInfo?> checkForUpdate() async {
    final response = await http.get(
      Uri.parse(_apiUrl),
      headers: {'Accept': 'application/vnd.github+json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final tag = ((json['tag_name'] as String?) ?? '').replaceAll('v', '');
    final url = (json['html_url'] as String?) ?? '';

    if (isNewer(tag, kAppVersion)) {
      return UpdateInfo(version: tag, releaseUrl: url);
    }
    return null;
  }

  static bool isNewer(String remote, String current) {
    final r = _parseVersion(remote);
    final c = _parseVersion(current);
    for (var i = 0; i < 3; i++) {
      if (r[i] > c[i]) return true;
      if (r[i] < c[i]) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String v) {
    final parts = v.split('.');
    return List.generate(
        3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }
}
