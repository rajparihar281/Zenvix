/// Quality preset for PDF image re-encoding.
enum CompressionLevel {
  /// Minimal compression – JPEG quality 75.
  low('Low', 75),

  /// Balanced compression – JPEG quality 50.
  medium('Medium', 50),

  /// Maximum compression – JPEG quality 25.
  high('High', 25);

  const CompressionLevel(this.label, this.jpegQuality);

  /// User-facing label.
  final String label;

  /// JPEG quality factor (0–100).
  final int jpegQuality;
}
