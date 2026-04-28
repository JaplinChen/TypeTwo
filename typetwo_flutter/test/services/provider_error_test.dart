import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/services/provider_error.dart';

void main() {
  group('formatProviderError', () {
    test('連線被拒時回傳本機服務診斷訊息', () {
      final message = formatProviderError(
        const SocketException(
          'Connection refused',
          osError: OSError('Connection refused', 1225),
        ),
      );

      expect(message, contains('無法連線到伺服器'));
      expect(message, contains('Ollama'));
      expect(message, isNot(contains('SocketException')));
    });

    test('主機名稱無法解析時回傳 endpoint 檢查提示', () {
      final message = formatProviderError(
        const SocketException(
          'Failed host lookup',
          osError: OSError('No such host is known', 11001),
        ),
      );

      expect(message, contains('無法解析伺服器位址'));
      expect(message, contains('endpoint'));
    });

    test('逾時時回傳簡潔訊息', () {
      final message = formatProviderError(
        TimeoutException('Request timed out'),
      );

      expect(message, contains('請求逾時'));
      expect(message, isNot(contains('TimeoutException')));
    });
  });
}
