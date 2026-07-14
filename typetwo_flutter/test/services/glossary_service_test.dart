import 'package:flutter_test/flutter_test.dart';
import 'package:typetwo/services/glossary_service.dart';

void main() {
  group('GlossaryService.applyPost', () {
    test('replaces ASCII terms on word boundaries only', () {
      expect(GlossaryService.applyPost('AI and rain', {'AI': '人工智慧'}),
          '人工智慧 and rain');
    });

    test('replaces CJK terms (no word boundary)', () {
      expect(GlossaryService.applyPost('這是台灣', {'台灣': 'Đài Loan'}),
          '這是Đài Loan');
    });

    test('longest key wins over shorter overlapping key', () {
      final out = GlossaryService.applyPost(
          '台灣', {'台': 'X', '台灣': 'Taiwan'});
      expect(out, 'Taiwan');
    });

    test('replaces Vietnamese term with diacritics', () {
      expect(
          GlossaryService.applyPost('xin chào bạn', {'chào': 'hello'}),
          'xin hello bạn');
    });

    test('empty glossary returns text unchanged', () {
      expect(GlossaryService.applyPost('abc', {}), 'abc');
    });
  });
}
