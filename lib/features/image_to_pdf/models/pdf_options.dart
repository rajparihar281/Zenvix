/// Configuration for PDF output.
class PdfOptions {
  /// Page size preset.
  final PdfPageSize pageSize;

  /// Page orientation.
  final PdfOrientation orientation;

  /// Margin in millimeters (applied equally on all sides).
  final double marginMm;

  /// How images are scaled onto the page.
  final ImageScaling scaling;

  const PdfOptions({
    this.pageSize = PdfPageSize.a4,
    this.orientation = PdfOrientation.portrait,
    this.marginMm = 10,
    this.scaling = ImageScaling.fit,
  });

  PdfOptions copyWith({
    PdfPageSize? pageSize,
    PdfOrientation? orientation,
    double? marginMm,
    ImageScaling? scaling,
  }) {
    return PdfOptions(
      pageSize: pageSize ?? this.pageSize,
      orientation: orientation ?? this.orientation,
      marginMm: marginMm ?? this.marginMm,
      scaling: scaling ?? this.scaling,
    );
  }
}

/// Supported page sizes.
enum PdfPageSize {
  a4('A4'),
  letter('Letter');

  final String label;
  const PdfPageSize(this.label);
}

/// Page orientation.
enum PdfOrientation {
  portrait('Portrait'),
  landscape('Landscape');

  final String label;
  const PdfOrientation(this.label);
}

/// How an image is placed on the PDF page.
enum ImageScaling {
  /// Scale to fit entirely within the printable area (may leave whitespace).
  fit('Fit'),

  /// Scale to fill the printable area (may crop edges).
  fill('Fill');

  final String label;
  const ImageScaling(this.label);
}
