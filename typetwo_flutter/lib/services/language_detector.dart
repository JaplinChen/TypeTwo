class LanguageDetector {
  static const _knownLanguages = [
    '繁體中文',
    '簡體中文',
    '越南文',
    '日文',
    '韓文',
    '泰文',
  ];

  static bool looksLike(String text, String lang) {
    switch (lang) {
      case '繁體中文':
      case '簡體中文':
        return RegExp(r'[一-鿿]').hasMatch(text);
      case '越南文':
        return RegExp(
          r'[ÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚÝàáâãèéêìíòóôõùúýĂăĐđĨĩŨũƠơƯưẠ-ỹ]',
        ).hasMatch(text);
      case '日文':
        return RegExp(r'[぀-ヿ]').hasMatch(text);
      case '韓文':
        return RegExp(r'[가-힯]').hasMatch(text);
      case '泰文':
        return RegExp(r'[฀-๿]').hasMatch(text);
      default:
        return false;
    }
  }

  static bool looksLikeKnown(String text) =>
      _knownLanguages.any((lang) => looksLike(text, lang));
}
