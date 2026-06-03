import 'package:flutter/material.dart';

enum ToolCategory {
  pdf,
  documents,
  utilities,
}

extension ToolCategoryX on ToolCategory {
  String get label {
    switch (this) {
      case ToolCategory.pdf:
        return 'PDF Tools';
      case ToolCategory.documents:
        return 'Documents & Sheets';
      case ToolCategory.utilities:
        return 'Utilities';
    }
  }

  IconData get icon {
    switch (this) {
      case ToolCategory.pdf:
        return Icons.picture_as_pdf_rounded;
      case ToolCategory.documents:
        return Icons.description_outlined;
      case ToolCategory.utilities:
        return Icons.build_outlined;
    }
  }
}

class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.secondaryColor,
    required this.routePath,
    required this.category,
    this.isAvailable = true,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final Color secondaryColor;
  final String routePath;
  final ToolCategory category;
  final bool isAvailable;
}
