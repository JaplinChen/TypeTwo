import 'dart:convert';

class ProviderHttpException implements Exception {
  final int statusCode;
  final String provider;
  final String body;
  final String? retryAfter;

  const ProviderHttpException({
    required this.statusCode,
    required this.provider,
    required this.body,
    this.retryAfter,
  });

  String userMessage(String locale) {
    final providerName = provider.isEmpty ? 'API' : provider;
    if (statusCode == 429) {
      final detail = _extractProviderMessage();
      final waitText = _retryAfterText(locale);
      switch (locale) {
        case 'en':
          return 'Rate limit or quota exceeded for $providerName.$waitText'
              '${detail == null ? '' : ' $detail'}';
        case 'vi':
          return 'Đã vượt quá giới hạn hoặc quota của $providerName.$waitText'
              '${detail == null ? '' : ' $detail'}';
        default:
          return '$providerName 已超過請求頻率或 quota 限制。$waitText'
              '${detail == null ? '' : ' $detail'}';
      }
    }
    if (statusCode == 401 || statusCode == 403) {
      switch (locale) {
        case 'en':
          return 'Authentication failed for $providerName. Please verify the API key and permissions.';
        case 'vi':
          return 'Xác thực $providerName thất bại. Vui lòng kiểm tra API key và quyền.';
        default:
          return '$providerName 驗證失敗，請確認 API Key 與權限設定。';
      }
    }
    if (statusCode == 503) {
      switch (locale) {
        case 'en':
          return '$providerName is temporarily unavailable. Please try again later.';
        case 'vi':
          return '$providerName tạm thời không khả dụng. Vui lòng thử lại sau.';
        default:
          return '$providerName 服務暫時不可用，請稍後再試。';
      }
    }
    final detail = _extractProviderMessage();
    switch (locale) {
      case 'en':
        return '$providerName request failed (HTTP $statusCode).${detail == null ? '' : ' $detail'}';
      case 'vi':
        return 'Yêu cầu $providerName thất bại (HTTP $statusCode).${detail == null ? '' : ' $detail'}';
      default:
        return '$providerName 請求失敗（HTTP $statusCode）。${detail ?? ''}';
    }
  }

  String? _extractProviderMessage() {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message']?.toString().trim();
          if (message != null && message.isNotEmpty) {
            return message;
          }
        }
      }
    } catch (_) {
      // Fall back to plain text below.
    }
    final plain = body.trim();
    if (plain.isEmpty) return null;
    return plain.length > 180 ? '${plain.substring(0, 180)}…' : plain;
  }

  String _retryAfterText(String locale) {
    final value = retryAfter?.trim();
    if (value == null || value.isEmpty) return '';
    final sec = int.tryParse(value);
    if (sec == null || sec <= 0) return '';
    switch (locale) {
      case 'en':
        return ' Retry after about $sec seconds.';
      case 'vi':
        return ' Vui lòng thử lại sau khoảng $sec giây.';
      default:
        return ' 請約 $sec 秒後再試。';
    }
  }

  @override
  String toString() => 'HTTP $statusCode';
}

String formatProviderError(Object error, {String locale = 'zh'}) {
  if (error is ProviderHttpException) {
    return error.userMessage(locale);
  }
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  if (text.isEmpty) {
    return switch (locale) {
      'en' => 'Unknown error',
      'vi' => 'Lỗi không xác định',
      _ => '未知錯誤',
    };
  }
  return text;
}
