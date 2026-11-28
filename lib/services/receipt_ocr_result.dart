class OcrResult {
  const OcrResult({
    required this.supported,
    required this.rawText,
    this.errorMessage,
  });

  final bool supported;
  final String rawText;
  final String? errorMessage;

  bool get hasText => rawText.trim().isNotEmpty;
}
