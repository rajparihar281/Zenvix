import 'package:flutter/material.dart';

import 'package:zenvix/core/models/tool_definition.dart';
import 'package:zenvix/core/theme/app_colors.dart';

/// Central registry of all tools in the app.
///
/// To add a new tool:
///   1. Create its feature folder under `lib/features/`.
///   2. Add a [ToolDefinition] entry below.
///   3. Add its route in `app_router.dart`.
/// That's it — the home grid and drawer auto-populate from this list.
final List<ToolDefinition> registeredTools = [
  // ── Available Tools ───────────────────────────────────────────────────
  const ToolDefinition(
    id: 'image_to_pdf',
    title: 'Image → PDF',
    description: 'Convert images to polished PDF documents',
    icon: Icons.image_outlined,
    accentColor: AppColors.neonBlue,
    secondaryColor: AppColors.electricPurple,
    routePath: '/image-to-pdf',
  ),
  const ToolDefinition(
    id: 'pdf_combiner',
    title: 'PDF Combiner',
    description: 'Merge multiple PDFs into a single document',
    icon: Icons.merge_type_outlined,
    accentColor: AppColors.electricPurple,
    secondaryColor: AppColors.accentPink,
    routePath: '/pdf-combiner',
  ),
  const ToolDefinition(
    id: 'pdf_page_manager',
    title: 'Page Manager',
    description: 'Reorder, rotate, delete, and extract PDF pages',
    icon: Icons.pages_outlined,
    accentColor: AppColors.accentPink,
    secondaryColor: AppColors.warning,
    routePath: '/pdf-page-manager',
  ),

  const ToolDefinition(
    id: 'pdf_compression',
    title: 'PDF Compress',
    description: 'Reduce PDF file size while preserving quality',
    icon: Icons.compress_rounded,
    accentColor: AppColors.success,
    secondaryColor: AppColors.accentCyan,
    routePath: '/pdf-compression',
  ),
  const ToolDefinition(
    id: 'pdf_security',
    title: 'PDF Security',
    description: 'Add or remove password protection',
    icon: Icons.lock_outline,
    accentColor: AppColors.electricPurple,
    secondaryColor: AppColors.accentPink,
    routePath: '/pdf-security',
  ),
  const ToolDefinition(
    id: 'qr_tools',
    title: 'QR Tools',
    description: 'Scan and generate QR codes instantly',
    icon: Icons.qr_code_2_outlined,
    accentColor: AppColors.warning,
    secondaryColor: AppColors.accentCyan,
    routePath: '/qr-tools',
  ),

  // ── Coming Soon ───────────────────────────────────────────────────────
  const ToolDefinition(
    id: 'pdf_to_image',
    title: 'PDF → Image',
    description: 'Extract images from PDF pages',
    icon: Icons.broken_image_outlined,
    accentColor: AppColors.accentCyan,
    secondaryColor: AppColors.neonBlue,
    routePath: '/pdf-to-image',
    isAvailable: false,
  ),
  const ToolDefinition(
    id: 'image_compressor',
    title: 'Image Compressor',
    description: 'Reduce image file size without losing quality',
    icon: Icons.compress_outlined,
    accentColor: AppColors.success,
    secondaryColor: AppColors.accentCyan,
    routePath: '/image-compressor',
    isAvailable: false,
  ),
  const ToolDefinition(
    id: 'qr_generator',
    title: 'QR Generator',
    description: 'Create and scan QR codes instantly',
    icon: Icons.qr_code_2_outlined,
    accentColor: AppColors.warning,
    secondaryColor: AppColors.accentPink,
    routePath: '/qr-tools',
    isAvailable: false,
  ),
  const ToolDefinition(
    id: 'notes_vault',
    title: 'Notes Vault',
    description: 'Secure encrypted notes storage',
    icon: Icons.lock_outline,
    accentColor: AppColors.accentPink,
    secondaryColor: AppColors.electricPurple,
    routePath: '/notes-vault',
    isAvailable: false,
  ),
];
