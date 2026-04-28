import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  if (error is SocketException) {
    final detail =
        '${error.message} ${error.osError?.message ?? ''}'.toLowerCase();
    final isRefused = detail.contains('connection refused') ||
        detail.contains('actively refused') ||
        detail.contains('拒絕網路連線') ||
        detail.contains('拒絕連線');
    final isLookupFailed = detail.contains('failed host lookup') ||
        detail.contains('name or service not known') ||
        detail.contains('找不到主機');
    if (isRefused) {
      return switch (locale) {
        'en' =>
          'Unable to connect to the server. If you are using a local service '
              '(such as Ollama or LM Studio), make sure it is running and the '
              'endpoint is correct.',
        'vi' =>
          'Không thể kết nối đến máy chủ. Nếu bạn đang dùng dịch vụ cục bộ '
              '(như Ollama hoặc LM Studio), hãy đảm bảo dịch vụ đã chạy và '
              'endpoint chính xác.',
        _ => '無法連線到伺服器。若使用本機服務（例如 Ollama 或 LM Studio），'
            '請先確認服務已啟動，並檢查 endpoint 是否正確。',
      };
    }
    if (isLookupFailed) {
      return switch (locale) {
        'en' => 'Unable to resolve the server address. Please verify the '
            'endpoint host name.',
        'vi' => 'Không thể phân giải địa chỉ máy chủ. Vui lòng kiểm tra tên '
            'host trong endpoint.',
        _ => '無法解析伺服器位址，請確認 endpoint 的主機名稱是否正確。',
      };
    }
    return switch (locale) {
      'en' =>
        'Network connection failed. Please verify the server status and endpoint.',
      'vi' =>
        'Kết nối mạng thất bại. Vui lòng kiểm tra trạng thái máy chủ và endpoint.',
      _ => '網路連線失敗，請確認伺服器狀態與 endpoint 設定。',
    };
  }
  if (error is TimeoutException) {
    return switch (locale) {
      'en' => 'The request timed out. Please check the server status and try '
          'again.',
      'vi' => 'Yêu cầu đã hết thời gian chờ. Vui lòng kiểm tra trạng thái máy '
          'chủ rồi thử lại.',
      _ => '請求逾時，請確認伺服器狀態後再試一次。',
    };
  }
  if (error is HttpException) {
    return switch (locale) {
      'en' => 'The server returned an invalid HTTP response.',
      'vi' => 'Máy chủ trả về phản hồi HTTP không hợp lệ.',
      _ => '伺服器回傳了無效的 HTTP 回應。',
    };
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
