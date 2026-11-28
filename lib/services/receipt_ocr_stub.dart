import 'receipt_ocr_result.dart';

Future<OcrResult> extractTextFromReceiptPath(String path) async {
  return const OcrResult(supported: false, rawText: '');
}
