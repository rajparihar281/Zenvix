/// Configuration for PDF output.
class PdfOptions {
  const PdfOptions({
    this.pageSize = PdfPageSize.a4,
    this.orientation = PdfOrientation.portrait,
    this.marginMm = 10,
    this.scaling = ImageScaling.fit,
  });

  /// Page size preset.
  final PdfPageSize pageSize;

  /// Page orientation.
  final PdfOrientation orientation;

  /// Margin in millimeters (applied equally on all sides).
  final double marginMm;

  /// How images are scaled onto the page.
  final ImageScaling scaling;

  PdfOptions copyWith({
    PdfPageSize? pageSize,
    PdfOrientation? orientation,
    double? marginMm,
    ImageScaling? scaling,
  }) => PdfOptions(
    pageSize: pageSize ?? this.pageSize,
    orientation: orientation ?? this.orientation,
    marginMm: marginMm ?? this.marginMm,
    scaling: scaling ?? this.scaling,
  );
}

/// Supported page sizes.
enum PdfPageSize {
  a4('A4'),
  letter('Letter');

  const PdfPageSize(this.label);
  final String label;
}

/// Page orientation.
enum PdfOrientation {
  portrait('Portrait'),
  landscape('Landscape');

  const PdfOrientation(this.label);
  final String label;
}

/// How an image is placed on the PDF page.
enum ImageScaling {
  /// Scale to fit entirely within the printable area (may leave whitespace).
  fit('Fit'),

  /// Scale to fill the printable area (may crop edges).
  fill('Fill');

  const ImageScaling(this.label);
  final String label;
}
