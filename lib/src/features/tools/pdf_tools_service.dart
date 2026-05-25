import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfToolsService {

  /// Organize: Merge multiple PDFs into one
  static Future<Uint8List> mergePdfs(List<String> filePaths) async {
    return await compute(_mergePdfsIsolate, filePaths);
  }

  static Uint8List _mergePdfsIsolate(List<String> filePaths) {
    final document = PdfDocument();

    for (final path in filePaths) {
      final file = File(path);
      if (!file.existsSync()) continue;

      final bytes = file.readAsBytesSync();
      final sourceDocument = PdfDocument(inputBytes: bytes);

      for (int i = 0; i < sourceDocument.pages.count; i++) {
        final template = sourceDocument.pages[i].createTemplate();
        final page = document.pages.add();
        page.graphics.drawPdfTemplate(template, const Offset(0, 0));
      }
      sourceDocument.dispose();
    }

    final mergedBytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return mergedBytes;
  }

  /// Organize: Split a PDF into individual pages
  static Future<List<Uint8List>> splitPdf(String filePath) async {
    return await compute(_splitPdfIsolate, filePath);
  }

  static List<Uint8List> _splitPdfIsolate(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return [];

    final bytes = file.readAsBytesSync();
    final sourceDocument = PdfDocument(inputBytes: bytes);
    final splitFiles = <Uint8List>[];

    for (int i = 0; i < sourceDocument.pages.count; i++) {
      final document = PdfDocument();
      final template = sourceDocument.pages[i].createTemplate();
      final page = document.pages.add();
      page.graphics.drawPdfTemplate(template, const Offset(0, 0));

      splitFiles.add(Uint8List.fromList(document.saveSync()));
      document.dispose();
    }

    sourceDocument.dispose();
    return splitFiles;
  }

  /// Convert: Extract text from a PDF
  static Future<String> extractText(String filePath) async {
    return await compute(_extractTextIsolate, filePath);
  }

  static String _extractTextIsolate(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return '';

    final bytes = file.readAsBytesSync();
    final document = PdfDocument(inputBytes: bytes);

    String text = PdfTextExtractor(document).extractText();

    document.dispose();
    return text;
  }

  /// Security: Encrypt a PDF with a password
  static Future<Uint8List> encryptPdf(String filePath, String password) async {
    return await compute(_encryptPdfIsolate, {'path': filePath, 'pass': password});
  }

  static Uint8List _encryptPdfIsolate(Map<String, String> args) {
    final file = File(args['path']!);
    if (!file.existsSync()) return Uint8List(0);

    final bytes = file.readAsBytesSync();
    final document = PdfDocument(inputBytes: bytes);

    final security = document.security;
    security.userPassword = args['pass'] ?? '';
    security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;

    final encryptedBytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return encryptedBytes;
  }

  /// Security: Decrypt a PDF
  static Future<Uint8List> decryptPdf(String filePath, String password) async {
    return await compute(_decryptPdfIsolate, {'path': filePath, 'pass': password});
  }

  static Uint8List _decryptPdfIsolate(Map<String, String> args) {
    final file = File(args['path']!);
    if (!file.existsSync()) return Uint8List(0);

    final bytes = file.readAsBytesSync();
    final document = PdfDocument(inputBytes: bytes, password: args['pass']);

    // Removing the password by clearing security settings
    document.security.userPassword = '';
    document.security.ownerPassword = '';

    final decryptedBytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return decryptedBytes;
  }

  /// Security: Add Watermark
  static Future<Uint8List> watermarkPdf(String filePath, String watermarkText) async {
    return await compute(_watermarkPdfIsolate, {'path': filePath, 'text': watermarkText});
  }

  static Uint8List _watermarkPdfIsolate(Map<String, String> args) {
    final file = File(args['path']!);
    if (!file.existsSync()) return Uint8List(0);

    final bytes = file.readAsBytesSync();
    final document = PdfDocument(inputBytes: bytes);

    final font = PdfStandardFont(PdfFontFamily.helvetica, 40);
    final size = font.measureString(args['text']!);

    for (int i = 0; i < document.pages.count; i++) {
      final page = document.pages[i];
      final graphics = page.graphics;

      graphics.save();
      graphics.setTransparency(0.25);
      graphics.translateTransform(page.getClientSize().width / 2, page.getClientSize().height / 2);
      graphics.rotateTransform(-45);
      graphics.drawString(
        args['text']!,
        font,
        pen: PdfPens.red,
        brush: PdfBrushes.red,
        bounds: Rect.fromLTWH(-size.width / 2, -size.height / 2, size.width, size.height)
      );
      graphics.restore();
    }

    final watermarkedBytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return watermarkedBytes;
  }

  /// Organize: Remove Pages
  static Future<Uint8List> removePages(String filePath, List<int> pageIndicesToRemove) async {
    return await compute(_removePagesIsolate, {'path': filePath, 'indices': pageIndicesToRemove});
  }

  static Uint8List _removePagesIsolate(Map<String, dynamic> args) {
    final file = File(args['path']);
    if (!file.existsSync()) return Uint8List(0);

    final bytes = file.readAsBytesSync();
    final document = PdfDocument(inputBytes: bytes);
    final indices = (args['indices'] as List<int>)..sort((a, b) => b.compareTo(a)); // Sort descending

    for (final index in indices) {
      if (index >= 0 && index < document.pages.count) {
        document.pages.removeAt(index);
      }
    }

    final resultBytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return resultBytes;
  }

  /// Optimize: Flatten PDF (removes form fields/annotations and paints them onto the page)
  static Future<Uint8List> flattenPdf(String filePath) async {
    return await compute(_flattenPdfIsolate, filePath);
  }

  static Uint8List _flattenPdfIsolate(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return Uint8List(0);

    final bytes = file.readAsBytesSync();
    final document = PdfDocument(inputBytes: bytes);

    // Flatten annotations
    for (int i = 0; i < document.pages.count; i++) {
      document.pages[i].annotations.flattenAllAnnotations();
    }

    // Flatten form fields
    if (document.form.fields.count > 0) {
      document.form.flattenAllFields();
    }

    final resultBytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return resultBytes;
}

  /// Convert: Images to PDF
  static Future<Uint8List> imagesToPdf(List<String> imagePaths) async {
    return await compute(_imagesToPdfIsolate, imagePaths);
  }

  static Uint8List _imagesToPdfIsolate(List<String> imagePaths) {
    final document = PdfDocument();

    for (final path in imagePaths) {
      final file = File(path);
      if (!file.existsSync()) continue;

      final bytes = file.readAsBytesSync();
      final image = PdfBitmap(bytes);

      final page = document.pages.add();
      // Scale image to fit page width
      final double width = page.getClientSize().width;
      final double height = (image.height / image.width) * width;

      page.graphics.drawImage(image, Rect.fromLTWH(0, 0, width, height));
    }

    final resultBytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return resultBytes;
  }

  /// Optimize: Rotate Pages
  static Future<Uint8List> rotatePages(String filePath, int degrees) async {
    return await compute(_rotatePagesIsolate, {'path': filePath, 'degrees': degrees});
  }

  static Uint8List _rotatePagesIsolate(Map<String, dynamic> args) {
    final file = File(args['path']);
    if (!file.existsSync()) return Uint8List(0);

    final bytes = file.readAsBytesSync();
    final document = PdfDocument(inputBytes: bytes);
    final degrees = args['degrees'] as int;

    final rotation = degrees == 90 ? PdfPageRotateAngle.rotateAngle90
                   : degrees == 180 ? PdfPageRotateAngle.rotateAngle180
                   : degrees == 270 ? PdfPageRotateAngle.rotateAngle270
                   : PdfPageRotateAngle.rotateAngle0;

    for (int i = 0; i < document.pages.count; i++) {
      document.pages[i].rotation = rotation;
    }

    final resultBytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return resultBytes;
  }
}
