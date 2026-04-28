/// Classifies the content type of a scanned QR code.
enum QrContentType { url, email, phone, text }

/// Immutable value object representing a single QR scan result.
class QrResult {
  const QrResult({required this.rawValue, required this.type});

  /// Derives the content type from [raw] using simple prefix detection.
  factory QrResult.fromRaw(String raw) {
    final lower = raw.toLowerCase();
    final QrContentType type;
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      type = QrContentType.url;
    } else if (lower.startsWith('mailto:')) {
      type = QrContentType.email;
    } else if (lower.startsWith('tel:')) {
      type = QrContentType.phone;
    } else {
      type = QrContentType.text;
    }
    return QrResult(rawValue: raw, type: type);
  }

  /// The raw string decoded from the QR code.
  final String rawValue;

  /// Detected content type.
  final QrContentType type;

  /// Display-friendly value (strips scheme prefixes for email/phone).
  String get displayValue {
    switch (type) {
      case QrContentType.email:
        return rawValue.replaceFirst('mailto:', '');
      case QrContentType.phone:
        return rawValue.replaceFirst('tel:', '');
      case QrContentType.url:
      case QrContentType.text:
        return rawValue;
    }
  }

  /// Icon label for the content type.
  String get typeLabel {
    switch (type) {
      case QrContentType.url:
        return 'URL';
      case QrContentType.email:
        return 'Email';
      case QrContentType.phone:
        return 'Phone';
      case QrContentType.text:
        return 'Text';
    }
  }
}
