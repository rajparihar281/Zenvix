# Project Work Done

This file tracks the progress and completed tasks for the **Zenvix** project.

## Current Status (as of 2026-04-24)

### ðŸ—ï¸ Core Infrastructure
- [x] Initial Flutter project setup.
- [x] Integration of **Riverpod** for state management.
- [x] Implementation of an **OLED-friendly Dark Theme** (high-contrast black/vibrant accents).
- [x] Custom **AppRouter** with smooth slide/fade transitions.
- [x] Centralized **AppStrings**, **AppTheme**, and **AppColors**.
- [x] **VS Code Launch Configuration** for both Debug and Release modes.
- [x] **R8/ProGuard Rules** to fix PDFBox-related release build errors.

### ðŸ  Home Module
- [x] **HomeScreen** implemented with a tool-based grid layout.
- [x] **ToolCard** shared widget for consistent UI across features.

### ðŸ–¼ï¸ Image to PDF Feature
- [x] **Image Selection**: Support for picking multiple images from gallery and camera.
- [x] **Image Preview**: Reorderable list of selected images.
- [x] **Image Editor**: Basic cropping and rotation capabilities.
- [x] **PDF Options**: Configuration for page size, orientation, and margins.
- [x] **PDF Generation**: Service to convert images into a high-quality PDF document.
- [x] **Result Screen**: Preview and sharing of the generated PDF.

### ðŸ“„ PDF Combiner Feature
- [x] Basic folder struc
ture and routing setup.
- [x] Screen and service skeletons implemented.
- [x] **File Selection**: Pick multiple PDFs and reorder them.
- [x] **Merge Logic**: Combine PDFs while maintaining order.
- [x] **Output & Export**: Save merged PDF to user-accessible directories (Downloads on Android, Documents on iOS) with custom file renaming.
- [x] **Share Option**: Share the merged PDF directly from the app.

### ðŸ“ My Files Feature
- [x] **Internal Scanning**: Fast file scanning inside the app's secure documents directory.
- [x] **OLED Dashboard**: Beautiful list UI showing file name, generated time, and size.
- [x] **Built-in PDF Viewer**: Instant PDF preview without leaving the app (using `printing` package).
- [x] **File Operations**: Seamlessly rename, delete, and share documents.
- [x] **Advanced Sorting**: Sort files by newest, oldest, name, or size.
- [x] **Quick Access**: Added quick access to the Drawer and Home screen app bar.

### 📄 PDF Page Manager Feature
- [x] **PDF Selection**: Select single PDF file for management.
- [x] **Preview & Thumbnails**: Render all pages as thumbnails in a grid layout.
- [x] **Reorder Pages**: Drag and drop support to reorder pages.
- [x] **Page Operations**: Rotate individual pages and delete specific pages.
- [x] **Extract Pages**: Select multiple pages and extract them into a new PDF.
- [x] **Export & Share**: Save the modified PDF with custom renaming and share support.

---
*Last Updated: 2026-04-24*
