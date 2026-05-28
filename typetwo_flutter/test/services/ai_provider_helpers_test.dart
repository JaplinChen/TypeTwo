import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/services/ai_provider_helpers.dart';

void main() {
  test('AiProviderHelpers openAICompatibleHeaders 會加入 JSON content type', () {
    expect(AiProviderHelpers.openAICompatibleHeaders(''), {
      'Content-Type': 'application/json',
    });
  });

  test('AiProviderHelpers openAICompatibleHeaders 會 trim token 並加入 bearer', () {
    expect(AiProviderHelpers.openAICompatibleHeaders(' sk-test '), {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer sk-test',
    });
  });

  test('AiProviderHelpers openAICompatibleModelsUri 空 endpoint 使用預設 URL', () {
    expect(
      AiProviderHelpers.openAICompatibleModelsUri(
        endpoint: ' ',
        defaultUrl: 'https://api.openai.com/v1/models',
      ).toString(),
      'https://api.openai.com/v1/models',
    );
  });

  test(
      'AiProviderHelpers openAICompatibleModelsUri 將 chat completions 改成 models',
      () {
    expect(
      AiProviderHelpers.openAICompatibleModelsUri(
        endpoint: 'https://example.com/openai/v1/chat/completions?x=1',
        defaultUrl: 'https://api.openai.com/v1/models',
      ).toString(),
      'https://example.com/openai/v1/models',
    );
  });

  test(
      'AiProviderHelpers openAICompatibleModelsUri 非 chat path 使用同源 /v1/models',
      () {
    expect(
      AiProviderHelpers.openAICompatibleModelsUri(
        endpoint: 'https://example.com/custom/path?x=1',
        defaultUrl: 'https://api.openai.com/v1/models',
      ).toString(),
      'https://example.com/v1/models',
    );
  });
}
