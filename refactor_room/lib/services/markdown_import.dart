import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../core/constants.dart';

class MarkdownImportResult {
  final String content;
  final String fileName;

  const MarkdownImportResult({
    required this.content,
    required this.fileName,
  });
}

class MarkdownImportException implements Exception {
  final String message;

  MarkdownImportException(this.message);

  @override
  String toString() => message;
}

class MarkdownImport {
  MarkdownImport._();

  static Future<MarkdownImportResult?> pickAndRead() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['md', 'markdown', 'txt'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      throw MarkdownImportException(
        'Could not read that file. Try a smaller .md or .txt file.',
      );
    }

    final text = utf8.decode(bytes, allowMalformed: true).trim();
    if (text.length < 10) {
      throw MarkdownImportException(
        'File is too short — need at least 10 characters of content.',
      );
    }
    if (text.length > AppConstants.maxIdeaChars) {
      throw MarkdownImportException(
        'File is too long (max ${AppConstants.maxIdeaChars} characters).',
      );
    }

    return MarkdownImportResult(
      content: text,
      fileName: file.name,
    );
  }
}
