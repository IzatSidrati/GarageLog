import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'receipt_ocr_result.dart';

Future<OcrResult> extractTextFromReceiptPath(String path) async {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    return const OcrResult(supported: false, rawText: '');
  }

  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final inputImage = InputImage.fromFilePath(path);
    final recognized = await recognizer.processImage(inputImage);
    return OcrResult(
      supported: true,
      rawText: recognized.text,
    );
  } catch (e) {
    return OcrResult(
      supported: true,
      rawText: '',
      errorMessage: e.toString(),
    );
  } finally {
    await recognizer.close();
  }
}
