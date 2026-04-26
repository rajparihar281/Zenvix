<div align="center">

<h1>Zenvix</h1>

<p>A focused, offline-first toolkit for efficient PDF and image processing.</p>

<p>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Framework-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  </a>
  <a href="https://dart.dev">
    <img src="https://img.shields.io/badge/Language-Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  </a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-black?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Architecture-Feature--First-informational?style=for-the-badge" />
</p>

</div>

---

## Overview

Zenvix is an offline-first Flutter application designed for efficient document workflows. It enables users to create, modify, and manage PDF files directly on-device, eliminating dependency on external services.

---

## Core Capabilities

### Image to PDF

* Multi-image selection from gallery or camera
* Reordering and preview before conversion
* Basic image editing (crop, rotate)
* Configurable output (page size, orientation, margins)
* High-quality PDF generation and export

### PDF Combination

* Multi-file selection
* Drag-and-drop reordering
* Deterministic merge preserving order
* Export with custom naming and sharing

### PDF Page Management

* Thumbnail-based page preview (grid)
* Drag-and-drop reordering
* Page rotation and deletion
* Selective extraction into new PDFs
* Rebuild and export workflows

### File Management

* Centralized access to generated documents
* Built-in PDF preview
* Rename, delete, and share operations
* Sorting by date, name, and size

---

## Architecture

Zenvix follows a modular, feature-based architecture:

```id="k3k2pq"
lib/
├── core/
├── features/
│   ├── image_to_pdf/
│   ├── pdf_combiner/
│   ├── pdf_page_manager/
├── home/
├── shared/
```

### Principles

* Clear separation of concerns
* Feature isolation for scalability
* Reusable UI and services

### State Management

* Riverpod for predictable and testable state handling

---

## Technical Implementation

* **Rendering:** `printing` package for efficient PDF rasterization
* **Processing:** `syncfusion_flutter_pdf` for document manipulation
* **File Handling:** `path_provider` for platform-aware storage
* **Input:** `image_picker` and `file_picker`

All operations are optimized for local execution and memory efficiency.

---

## Getting Started

### Prerequisites

* Flutter SDK (3.19+)
* Android Studio or Xcode

### Setup

```bash id="h3s9f0"
git clone https://github.com/rajparihar281/Zenvix.git
cd Zenvix
flutter pub get
flutter run
```

---

## Build Instructions

### Android

```bash id="u2p0gh"
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS

```bash id="g9k8hd"
flutter build ios --release
```

---

## Development Workflow

* `main` – production-ready code
* `develop` – active development
* `feature/*` – feature branches
* `release/*` – release preparation

Commit conventions:

* `feat:` feature
* `fix:` bug fix
* `refactor:` improvements
* `chore:` maintenance

---

## Roadmap

* PDF compression
* Password protection
* OCR support
* QR scanning
* Watermarking

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit using conventional commits
4. Open a pull request

---

## License

This project is currently proprietary. Licensing terms may change in the future.
