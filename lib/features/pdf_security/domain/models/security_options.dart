/// The two operating modes for the PDF Security tool.
enum SecurityMode {
  /// Add password protection and set permissions.
  protect('Protect PDF'),

  /// Remove password protection from a PDF.
  unlock('Unlock PDF');

  const SecurityMode(this.label);

  final String label;
}

/// Permission flags for a protected PDF.
class SecurityPermissions {
  const SecurityPermissions({
    this.allowPrinting = true,
    this.allowCopying = true,
  });

  /// Whether the PDF can be printed.
  final bool allowPrinting;

  /// Whether text/images can be copied from the PDF.
  final bool allowCopying;

  SecurityPermissions copyWith({bool? allowPrinting, bool? allowCopying}) =>
      SecurityPermissions(
        allowPrinting: allowPrinting ?? this.allowPrinting,
        allowCopying: allowCopying ?? this.allowCopying,
      );
}
