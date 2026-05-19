import 'dart:io';
import 'dart:typed_data';

import 'package:zenvix/core/services/storage_service.dart';
import 'package:zenvix/features/batch_processor/domain/models/batch_job.dart';
import 'package:zenvix/features/pdf_combiner/services/pdf_combine_service.dart';
import 'package:zenvix/features/pdf_compression/data/services/pdf_compression_service.dart';
import 'package:zenvix/features/pdf_compression/domain/models/compression_options.dart';
import 'package:zenvix/features/pdf_security/data/services/pdf_security_service.dart';

class BatchProcessingService {
  BatchProcessingService({
    StorageService? storage,
    PdfCompressionService? compression,
    PdfSecurityService? security,
    PdfCombineService? combiner,
  }) : _storage = storage ?? StorageService(),
       _compression = compression ?? PdfCompressionService(),
       _security = security ?? PdfSecurityService(),
       _combiner = combiner ?? PdfCombineService();

  final StorageService _storage;
  final PdfCompressionService _compression;
  final PdfSecurityService _security;
  final PdfCombineService _combiner;

  /// Processes a single [job] and returns an updated job with result/error.
  Future<BatchJob> processJob(
    BatchJob job, {
    String protectPassword = '',
  }) async {
    try {
      final outputPath = await _execute(job, protectPassword: protectPassword);
      return job.copyWith(status: BatchJobStatus.done, outputPath: outputPath);
    } on Exception catch (e) {
      return job.copyWith(status: BatchJobStatus.failed, error: e.toString());
    }
  }

  Future<String> _execute(
    BatchJob job, {
    required String protectPassword,
  }) async {
    final dir = await _storage.getDefaultZenvixDirectory();

    switch (job.operation) {
      case BatchOperation.compress:
        return _compress(job, dir.path);
      case BatchOperation.protect:
        return _protect(job, dir.path, protectPassword);
      case BatchOperation.merge:
        throw Exception('Merge must be handled separately via mergeAll.');
      case BatchOperation.imageToPdf:
        throw Exception('Image-to-PDF batch not supported in single-job mode.');
    }
  }

  Future<String> _compress(BatchJob job, String dirPath) async {
    final bytes = await File(job.filePath).readAsBytes();
    final compressed = await _compression.compress(
      pdfData: bytes,
      level: CompressionLevel.medium,
    );
    final name = _batchName(job.fileName);
    final result = await _storage.saveBytes(
      bytes: compressed,
      fileName: name,
      directoryPath: dirPath,
      location: SaveLocation.defaultZenvix,
    );
    return result.savedPath;
  }

  Future<String> _protect(BatchJob job, String dirPath, String password) async {
    if (password.isEmpty) {
      throw Exception('Password required for protect operation.');
    }
    final bytes = await File(job.filePath).readAsBytes();
    final protected = _security.protect(
      pdfData: Uint8List.fromList(bytes),
      userPassword: password,
    );
    final name = _batchName(job.fileName);
    final result = await _storage.saveBytes(
      bytes: protected,
      fileName: name,
      directoryPath: dirPath,
      location: SaveLocation.defaultZenvix,
    );
    return result.savedPath;
  }

  /// Merges all [paths] into a single output PDF.
  Future<String> mergeAll(List<String> paths) async {
    final tmpPath = await _combiner.combinePdfs(paths);
    final dir = await _storage.getDefaultZenvixDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final result = await _storage.copyFile(
      sourcePath: tmpPath,
      fileName: 'batch_merged_$timestamp.pdf',
      directoryPath: dir.path,
      location: SaveLocation.defaultZenvix,
    );
    // Clean up temp file.
    final tmp = File(tmpPath);
    if (tmp.existsSync()) {
      await tmp.delete();
    }
    return result.savedPath;
  }

  String _batchName(String originalName) {
    final base = originalName.contains('.')
        ? originalName.substring(0, originalName.lastIndexOf('.'))
        : originalName;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${base}_batch_$timestamp.pdf';
  }
}
