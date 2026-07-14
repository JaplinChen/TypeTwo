import '../models/app_config.dart';
import '../models/app_constants.dart';
import 'language_detector.dart';

class GlossaryService {
  static const _kMaxEntries = 100;

  static bool termMatches(String term, String text) {
    if (term.codeUnits.every((c) => c < 128)) {
      return RegExp(
        r'\b' + RegExp.escape(term) + r'\b',
        caseSensitive: false,
      ).hasMatch(text);
    }
    return text.toLowerCase().contains(term.toLowerCase());
  }

  static String glossaryRules(Map<String, String> glossary) {
    final entries = glossary.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    return entries.map((e) => '- ${e.key} → ${e.value}').join('\n');
  }

  static String applyPost(String text, Map<String, String> glossary) {
    final entries = glossary.entries.where((e) => e.key.isNotEmpty).toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    if (entries.isEmpty) return text;
    // ponytail: longest-key-first alternation stops a short term (台) firing
    // inside a longer one (台灣); CJK has no word boundary, so non-ASCII terms
    // match as plain substrings — acceptable since glossary terms are deliberate.
    final alternation = entries.map((e) {
      final escaped = RegExp.escape(e.key);
      return e.key.codeUnits.every((c) => c < 128)
          ? r'\b' + escaped + r'\b'
          : escaped;
    }).join('|');
    final pattern = RegExp(alternation, caseSensitive: false);
    final lookup = {for (final e in entries) e.key.toLowerCase(): e.value};
    return text.replaceAllMapped(
        pattern, (m) => lookup[m[0]!.toLowerCase()] ?? m[0]!);
  }

  static bool directionMatchesTarget(
    String inputTerm,
    String outputTerm,
    String targetLang,
  ) {
    if (targetLang.isEmpty) return true;
    if (LanguageDetector.looksLike(outputTerm, targetLang)) return true;
    if (LanguageDetector.looksLike(inputTerm, targetLang)) return false;
    if (LanguageDetector.looksLikeKnown(outputTerm)) return false;
    if (LanguageDetector.looksLikeKnown(inputTerm)) return true;
    return true;
  }

  static Map<String, String> resolve(AppConfig cfg,
      {AppConfig? originalCfg}) {
    void addPair(Map<String, String> result, String source, String target) {
      final entries = cfg.langGlossary['$source-$target'];
      if (entries != null) result.addAll(entries);
    }

    final result = <String, String>{...cfg.glossary};
    addPair(result, cfg.sourceLang, cfg.targetLang);
    addPair(result, cfg.targetLang, cfg.sourceLang);
    final autoCfg = originalCfg ?? cfg;
    final second = autoCfg.secondTargetLang;
    if (autoCfg.sourceLang == kAutoDetectLang &&
        second != null &&
        second.isNotEmpty) {
      addPair(result, autoCfg.targetLang, second);
      addPair(result, second, autoCfg.targetLang);
    }
    return result;
  }

  static Map<String, String> pickRelevant(
    String text,
    AppConfig cfg, {
    AppConfig? originalCfg,
  }) {
    final targetLang = cfg.targetLang;
    final matched = <String, String>{};
    resolve(cfg, originalCfg: originalCfg).forEach((src, tgt) {
      _addIfRelevant(matched, text, src, tgt, targetLang);
      _addIfRelevant(matched, text, tgt, src, targetLang);
    });
    if (matched.length <= _kMaxEntries) return matched;
    final entries = matched.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    return Map.fromEntries(entries.take(_kMaxEntries));
  }

  static void _addIfRelevant(
    Map<String, String> matched,
    String text,
    String inputTerm,
    String outputTerm,
    String targetLang,
  ) {
    if (inputTerm.isEmpty || outputTerm.isEmpty) return;
    if (!termMatches(inputTerm, text)) return;
    if (!directionMatchesTarget(inputTerm, outputTerm, targetLang)) return;
    matched[inputTerm] = outputTerm;
  }
}
