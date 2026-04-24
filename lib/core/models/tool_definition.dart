import 'package:flutter/material.dart';

/// Defines a single tool available in the Zenvix hub.
///
/// Adding a new tool to the app requires creating a [ToolDefinition]
/// and registering it in [tool_registry.dart] â€” no other wiring needed.
class ToolDefinition {
  /// Unique machine-readable identifier (e.g., 'image_to_pdf').
  final String id;

  /// Human-readable name shown in UI.
  final String title;

  /// One-line description for the feature card.
  final String description;

  /// Icon displayed on the feature card.
  final IconData icon;

  /// Accent color for this tool's icon background gradient.
  final Color accentColor;

  /// Secondary accent for gradient.
  final Color secondaryColor;

  /// Route path used by the app router.
  final String routePath;

  /// Whether the tool is implemented and interactive.
  /// When `false`, a "Coming Soon" badge is shown.
  final bool isAvailable;

  const ToolDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.secondaryColor,
    required this.routePath,
    this.isAvailable = true,
  });
}
