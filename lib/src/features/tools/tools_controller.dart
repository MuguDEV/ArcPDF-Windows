
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';

import 'pdf_tools_service.dart';

class ToolsController {

  static Future<void> handleToolAction(BuildContext context, String toolTitle) async {
    switch (toolTitle) {
      case 'Merge PDFs':
        await _mergePdfs(context);
        break;
      case 'Split PDF':
        await _splitPdf(context);
        break;
      case 'Remove Pages':
        await _removePages(context);
        break;
      case 'Extract Text':
        await _extractText(context);
        break;
      case 'Encrypt':
        await _encryptPdf(context);
        break;
      case 'Decrypt':
        await _decryptPdf(context);
        break;
      case 'Watermark':
        await _watermarkPdf(context);
        break;
      case 'Flatten':
        await _flattenPdf(context);
        break;
      case 'Images to PDF':
        await _imagesToPdf(context);
        break;
      case 'Rotate Pages':
        await _rotatePages(context);
        break;
      case 'PDF to Images':
      case 'Extract Images':
      case 'Reorder Pages':
      case 'Compress':
      case 'Crop':
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$toolTitle requires additional visual UI, coming soon!')),
          );
        }
        break;
      default:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$toolTitle is coming in the next update!')),
          );
        }
    }
  }

  static Future<void> _imagesToPdf(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      dialogTitle: 'Select images to convert into a PDF',
    );
    if (result == null || result.files.isEmpty) return;

    if (!context.mounted) return;
    _showLoading(context, 'Converting images to PDF...');
    try {
      final paths = result.files.map((f) => f.path!).toList();
      final bytes = await PdfToolsService.imagesToPdf(paths);
      if (context.mounted) Navigator.pop(context);
      await _saveFile(context, bytes, 'images_converted.pdf');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static Future<void> _rotatePages(BuildContext context) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null) return;

    if (!context.mounted) return;
    final degreesString = await _showInputDialog(context, 'Rotate Pages', 'Enter degrees to rotate (90, 180, 270):');
    if (degreesString == null || degreesString.isEmpty) return;

    final degrees = int.tryParse(degreesString) ?? 90;

    _showLoading(context, 'Rotating pages...');
    try {
      final bytes = await PdfToolsService.rotatePages(result.files.single.path!, degrees);
      if (context.mounted) Navigator.pop(context);
      await _saveFile(context, bytes, '${result.files.single.name.replaceAll('.pdf', '')}_rotated.pdf');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static Future<void> _splitPdf(BuildContext context) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null) return;

    if (!context.mounted) return;
    _showLoading(context, 'Splitting into single pages...');
    try {
      final pagesBytes = await PdfToolsService.splitPdf(result.files.single.path!);
      if (context.mounted) Navigator.pop(context);

      for (int i = 0; i < pagesBytes.length; i++) {
        await _saveFile(context, pagesBytes[i], '${result.files.single.name.replaceAll('.pdf', '')}_page_${i + 1}.pdf');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static Future<void> _removePages(BuildContext context) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null) return;

    if (!context.mounted) return;
    final pagesString = await _showInputDialog(context, 'Remove Pages', 'Enter comma separated page numbers to remove (e.g. 1, 3, 5):');
    if (pagesString == null || pagesString.isEmpty) return;

    final indices = pagesString.split(',').map((e) => int.tryParse(e.trim())).where((e) => e != null).map((e) => e! - 1).toList();

    _showLoading(context, 'Removing pages...');
    try {
      final bytes = await PdfToolsService.removePages(result.files.single.path!, indices);
      if (context.mounted) Navigator.pop(context);
      await _saveFile(context, bytes, '${result.files.single.name.replaceAll('.pdf', '')}_pages_removed.pdf');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static Future<void> _mergePdfs(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      dialogTitle: 'Select PDFs to Merge (Hold Ctrl to select multiple)',
    );

    if (result == null || result.files.length < 2) {
      if (context.mounted && result?.files.length == 1) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 2 PDFs to merge.')));
      }
      return;
    }

    _showLoading(context, 'Merging PDFs...');
    try {
      final paths = result.files.map((e) => e.path!).toList();
      final bytes = await PdfToolsService.mergePdfs(paths);
      if (context.mounted) Navigator.pop(context); // Close loading
      await _saveFile(context, bytes, 'merged_document.pdf');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static Future<void> _extractText(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;

    _showLoading(context, 'Extracting text...');
    try {
      final text = await PdfToolsService.extractText(result.files.single.path!);
      if (context.mounted) Navigator.pop(context); // Close loading

      // Save as .txt
      await _saveFile(context, Uint8List.fromList(utf8.encode(text)), '${result.files.single.name.replaceAll('.pdf', '')}_text.txt');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static Future<void> _encryptPdf(BuildContext context) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null) return;

    if (!context.mounted) return;
    final password = await _showInputDialog(context, 'Encrypt PDF', 'Enter a password to lock this PDF:');
    if (password == null || password.isEmpty) return;

    _showLoading(context, 'Encrypting...');
    try {
      final bytes = await PdfToolsService.encryptPdf(result.files.single.path!, password);
      if (context.mounted) Navigator.pop(context);
      await _saveFile(context, bytes, '${result.files.single.name.replaceAll('.pdf', '')}_locked.pdf');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static Future<void> _decryptPdf(BuildContext context) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null) return;

    if (!context.mounted) return;
    final password = await _showInputDialog(context, 'Decrypt PDF', 'Enter the current password:');
    if (password == null || password.isEmpty) return;

    _showLoading(context, 'Decrypting...');
    try {
      final bytes = await PdfToolsService.decryptPdf(result.files.single.path!, password);
      if (context.mounted) Navigator.pop(context);
      await _saveFile(context, bytes, '${result.files.single.name.replaceAll('.pdf', '')}_unlocked.pdf');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error decrypting file. Incorrect password?')));
      }
    }
  }

  static Future<void> _watermarkPdf(BuildContext context) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null) return;

    if (!context.mounted) return;
    final text = await _showInputDialog(context, 'Watermark PDF', 'Enter watermark text (e.g., CONFIDENTIAL):');
    if (text == null || text.isEmpty) return;

    _showLoading(context, 'Adding watermark...');
    try {
      final bytes = await PdfToolsService.watermarkPdf(result.files.single.path!, text);
      if (context.mounted) Navigator.pop(context);
      await _saveFile(context, bytes, '${result.files.single.name.replaceAll('.pdf', '')}_watermarked.pdf');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static Future<void> _flattenPdf(BuildContext context) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null) return;

    _showLoading(context, 'Flattening...');
    try {
      final bytes = await PdfToolsService.flattenPdf(result.files.single.path!);
      if (context.mounted) Navigator.pop(context);
      await _saveFile(context, bytes, '${result.files.single.name.replaceAll('.pdf', '')}_flattened.pdf');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static Future<void> _saveFile(BuildContext context, Uint8List bytes, String defaultName) async {
    final savePath = await FilePicker.saveFile(
      dialogTitle: 'Save File',
      fileName: defaultName,
    );

    if (savePath != null) {
      final file = File(savePath);
      await file.writeAsBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully!')));
      }
    }
  }

  static void _showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(message),
          ],
        ),
      ),
    );
  }

  static Future<String?> _showInputDialog(BuildContext context, String title, String prompt) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prompt),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('OK')),
        ],
      ),
    );
  }
}
