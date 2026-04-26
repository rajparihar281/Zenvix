import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Abstraction over multiple image-picking strategies.
///
/// Returns file paths of selected images.
class ImagePickerService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick multiple images from the device gallery.
  Future<List<String>> pickFromGallery() async {
    final images = await _imagePicker.pickMultiImage(imageQuality: 90);
    return images.map((img) => img.path).toList();
  }

  /// Pick images via the system file manager.
  Future<List<String>> pickFromFileManager() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) {
      return [];
    }
    return result.paths.whereType<String>().toList();
  }

  /// Capture a single image from the camera.
  Future<String?> pickFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    return image?.path;
  }
}
