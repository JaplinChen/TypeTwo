import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/services/provider_error.dart';

void main() {
  group('formatProviderError SocketException', () {
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

    test('英文 locale 連線被拒回傳英文訊息', () {
      final message = formatProviderError(
        const SocketException(
          'Connection refused',
          osError: OSError('Connection refused', 1225),
        ),
        locale: 'en',
      );

      expect(message, contains('Unable to connect'));
      expect(message, contains('LM Studio'));
    });

    test('越南文 locale 連線被拒回傳越南文訊息', () {
      final message = formatProviderError(
        const SocketException(
          'Connection refused',
          osError: OSError('Connection refused', 1225),
        ),
        locale: 'vi',
      );

      expect(message, contains('Không thể kết nối'));
      expect(message, contains('LM Studio'));
    });

    test('其他 SocketException 走 generic network 分支', () {
      final message = formatProviderError(
        const SocketException('something else'),
      );

      expect(message, contains('網路連線失敗'));
    });
  });

  group('formatProviderError ProviderHttpException', () {
    test('429 帶數字 Retry-After 回傳秒數提示', () {
      final message = formatProviderError(
        const ProviderHttpException(
          statusCode: 429,
          provider: 'Gemini',
          body: '',
          retryAfter: '30',
        ),
      );

      expect(message, contains('Gemini'));
      expect(message, contains('quota'));
      expect(message, contains('30 秒'));
    });

    test('429 無 Retry-After 不顯示秒數提示', () {
      final message = formatProviderError(
        const ProviderHttpException(
          statusCode: 429,
          provider: 'Gemini',
          body: '',
        ),
      );

      expect(message, contains('Gemini'));
      expect(message, contains('quota'));
      expect(message, isNot(contains('秒後')));
    });

    test('401 回傳驗證失敗訊息', () {
      final message = formatProviderError(
        const ProviderHttpException(
          statusCode: 401,
          provider: 'Azure',
          body: '',
        ),
      );

      expect(message, contains('Azure'));
      expect(message, contains('驗證失敗'));
    });

    test('403 回傳驗證失敗訊息', () {
      final message = formatProviderError(
        const ProviderHttpException(
          statusCode: 403,
          provider: 'Azure',
          body: '',
        ),
      );

      expect(message, contains('Azure'));
      expect(message, contains('驗證失敗'));
    });

    test('503 回傳服務暫時不可用', () {
      final message = formatProviderError(
        const ProviderHttpException(
          statusCode: 503,
          provider: 'OpenAI',
          body: '',
        ),
      );

      expect(message, contains('OpenAI'));
      expect(message, contains('暫時不可用'));
    });

    test('generic 5xx fallthrough 顯示 status code', () {
      final message = formatProviderError(
        const ProviderHttpException(
          statusCode: 500,
          provider: 'LM Studio',
          body: '',
        ),
      );

      expect(message, contains('LM Studio'));
      expect(message, contains('500'));
    });

    test('JSON body 內 error.message 會被擷取', () {
      final message = formatProviderError(
        const ProviderHttpException(
          statusCode: 400,
          provider: 'Gemini',
          body: '{"error":{"message":"Invalid model name"}}',
        ),
      );

      expect(message, contains('Invalid model name'));
    });

    test('JSON parse 失敗時 fallback 到 plain text', () {
      final message = formatProviderError(
        const ProviderHttpException(
          statusCode: 400,
          provider: 'Gemini',
          body: 'not-json-just-plain-text',
        ),
      );

      expect(message, contains('not-json-just-plain-text'));
    });

    test('Plain text body 超過 180 字元會被截斷加 …', () {
      final longBody = 'x' * 300;
      final message = formatProviderError(
        ProviderHttpException(
          statusCode: 400,
          provider: 'Gemini',
          body: longBody,
        ),
      );

      expect(message, contains('…'));
      expect(message.contains('x' * 200), isFalse);
    });

    test('英文 locale 429 回傳英文訊息', () {
      final message = formatProviderError(
        const ProviderHttpException(
          statusCode: 429,
          provider: 'Gemini',
          body: '',
          retryAfter: '60',
        ),
        locale: 'en',
      );

      expect(message, contains('Rate limit'));
      expect(message, contains('60 seconds'));
    });

    test('英文 locale 503 回傳英文訊息', () {
      final message = formatProviderError(
        const ProviderHttpException(
          statusCode: 503,
          provider: 'OpenAI',
          body: '',
        ),
        locale: 'en',
      );

      expect(message, contains('temporarily unavailable'));
    });
  });

  group('formatProviderError 其他例外', () {
    test('HttpException 回傳無效回應訊息', () {
      final message = formatProviderError(
        const HttpException('Bad headers'),
      );

      expect(message, contains('無效的 HTTP 回應'));
    });

    test('Generic Exception 訊息 strip Exception: 前綴', () {
      final message = formatProviderError(
        Exception('something went wrong'),
      );

      expect(message, equals('something went wrong'));
    });

    test('空字串 error 走 unknown error 分支', () {
      final message = formatProviderError(
        Exception(''),
      );

      expect(message, equals('未知錯誤'));
    });
  });
}
