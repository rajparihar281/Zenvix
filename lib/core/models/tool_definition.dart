import 'package:flutter/material.dart';

class ToolDefinition {
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

  final String id;

  final String title;

  final String description;

  final IconData icon;

  final Color accentColor;

  final Color secondaryColor;

  final String routePath;

  final bool isAvailable;
}
