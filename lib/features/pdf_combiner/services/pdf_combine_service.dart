import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

/// Merges multiple PDF files into a single document.
///
/// The result is written to a temporary app-documents path. The caller is
/// responsible for moving it to the desired user-visible location via
/// `[StorageService]`.
class PdfCombineService {
  /// Merge [paths] into one PDF. Returns the temporary output file path.
  Future<String> combinePdfs(List<String> paths) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${dir.path}/.zenvix_tmp_merged_$timestamp.pdf';

    await PdfCombiner.mergeMultiplePDFs(
      inputPaths: paths,
      outputPath: outputPath,
    );

    return outputPath;
  }
}
