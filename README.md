<div align="center">
  <!-- TODO: Replace with actual logo once created -->
  <h1>🔨 Zenvix</h1>
  <p><strong>A powerful and intuitive Swiss Army Knife for your PDF manipulation needs.</strong></p>
  
  <p>
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Made%20with-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Made with Flutter" /></a>
    <a href="https://dart.dev"><img src="https://img.shields.io/badge/Language-Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" /></a>
  </p>
</div>

---

##  Overview

**Zenvix** is a modern, offline-first Flutter application designed to make managing and manipulating PDF files incredibly simple. Whether you need to quickly convert images into a polished PDF document or combine multiple PDFs into a single file, Zenvix handles it seamlessly entirely on your device.

##  Features

-  **Image to PDF Converter**
  - Select multiple images from your gallery.
  - Preview, edit, and reorder images before conversion.
  - Generate high-quality PDFs instantly.
-  **PDF Combiner**
  - Select multiple PDF files from your device.
  - Intuitive drag-and-drop interface to reorder files.
  - Merge PDFs safely without uploading sensitive data to the cloud.
-  **My Files Manager**
  - Access all your generated documents in one place.
  - Built-in PDF viewer for immediate previews.
  - Easy sharing and file management directly from the app.

##  Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.19.0 or higher recommended)
- Android Studio / Xcode for emulators and building.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/eventhon-codebase/Zenvix.git
   ```
2. Navigate to the project directory:
   ```bash
   cd Zenvix
   ```
3. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

##  Built With

- **[Flutter](https://flutter.dev/)** - UI Toolkit for building natively compiled applications.
- **[Dart](https://dart.dev/)** - The programming language used by Flutter.
- **State Management:** Provider (or Riverpod/Bloc depending on your architecture).
- **Core Packages:** `pdf`, `image_picker`, `file_picker`.

##  Building for Release

### Android
To build a release APK or AppBundle:
```bash
flutter build apk --release
# OR
flutter build appbundle --release
```

### iOS
To build for iOS, ensure you have an Apple Developer account and Xcode installed:
```bash
flutter build ios --release
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to check the [issues page](https://github.com/eventhon-codebase/Zenvix/issues).

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat(scope): add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is proprietary and confidential. Unauthorized copying of this file, via any medium, is strictly prohibited. 
*(Update this section if you plan to open-source the project!)*

---
