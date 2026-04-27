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

### 🗜️ PDF Compression Feature
- [x] **Domain Model**: `CompressionLevel` enum with Low / Medium / High presets (JPEG quality 75 / 50 / 25).
- [x] **Compression Service**: Rasterizes pages via `printing`, re-encodes to JPEG in an isolate (`compute`), assembles new PDF via `syncfusion_flutter_pdf`. DPI scales with quality level.
- [x] **Size Estimation**: Instant estimated output size shown before compression runs.
- [x] **Progress Indicator**: Per-page percentage progress bar during compression.
- [x] **Riverpod Provider**: `PdfCompressionNotifier` / `PdfCompressionState` with `idle → loading → compressing → done / error` lifecycle.
- [x] **Compression Screen**: File picker, level selector (animated cards), size preview card, progress bar, change-file action.
- [x] **Result Screen**: Success icon, real size comparison widget, Share / Save to Device / **Go to Folder** / Compress Another actions.

### 🔒 PDF Security Feature
- [x] **Domain Models**: `SecurityMode` enum (protect / unlock), `SecurityPermissions` (allowPrinting, allowCopying).
- [x] **Security Service**: AES-256 encryption via `syncfusion_flutter_pdf`; graceful wrong-password detection on unlock.
- [x] **Riverpod Provider**: `PdfSecurityNotifier` / `PdfSecurityState` with full lifecycle and error propagation.
- [x] **Security Screen**: Mode selector (protect / unlock), password fields with visibility toggle, owner password (optional), permission toggles (print / copy).
- [x] **Result Screen**: Mode-aware icon/colour, Share / Save to Device / **Go to Folder** / Process Another actions.

### 🎨 UX & Stability Improvements
- [x] **Progress Indicators**: Percentage-based progress bar replaces generic loaders in compression flow.
- [x] **Success Screens**: All result screens include Open (via My Files), Share, Save to Device, and Go to Folder actions.
- [x] **Error Handling**: Typed error messages for wrong password, corrupt PDF, large file, permission denial, and generic failures — surfaced via themed snackbars with optional retry.
- [x] **Router**: `/pdf-compression` and `/pdf-security` routes registered in `AppRouter`.
- [x] **Tool Registry**: Both new tools registered in `tool_registry.dart` with accent colours and icons.
- [x] **AppStrings**: All new user-facing strings centralised.

---
*Last Updated: 2026-04-25*
