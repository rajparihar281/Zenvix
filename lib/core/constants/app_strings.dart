/// Centralized string constants for Zenvix.
///
/// Keeping all user-facing text here simplifies future localization.
class AppStrings {
  AppStrings._();

  // â”€â”€ App â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String appName = 'Zenvix';
  static const String appTagline = 'Your pocket toolkit,\nforged for power.';
  static const String appVersion = '1.0.0';

  // â”€â”€ Drawer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String drawerHome = 'Home';
  static const String drawerAllTools = 'All Tools';
  static const String drawerFavorites = 'Favorites';
  static const String drawerSettings = 'Settings';
  static const String drawerAbout = 'About';
  static const String myFiles = 'My Files';
  static const String comingSoon = 'Coming Soon';

  // â”€â”€ Image to PDF â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String imageToPdf = 'Image To PDF';
  static const String imageToPdfDesc =
      'Convert images to polished PDF documents';
  static const String addImages = 'Add Images';
  static const String pickFromGallery = 'Gallery';
  static const String pickFromFiles = 'File Manager';
  static const String pickFromCamera = 'Camera';
  static const String emptyImagesTitle = 'No images selected';
  static const String emptyImagesSubtitle =
      'Tap + to add images from gallery, files, or camera';
  static const String convertToPdf = 'Convert to PDF';
  static const String pdfOptions = 'PDF Options';
  static const String pageSize = 'Page Size';
  static const String orientation = 'Orientation';
  static const String portrait = 'Portrait';
  static const String landscape = 'Landscape';
  static const String margin = 'Margin';
  static const String imageScaling = 'Image Scaling';
  static const String fit = 'Fit';
  static const String fill = 'Fill';
  static const String generatePdf = 'Generate PDF';
  static const String pdfGenerated = 'PDF Generated Successfully!';
  static const String saveToDisk = 'Save to Device';
  static const String share = 'Share';
  static const String convertAnother = 'Convert Another';

  // â”€â”€ Image Editor â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String editImage = 'Edit Image';
  static const String rotate = 'Rotate';
  static const String flipH = 'Flip H';
  static const String flipV = 'Flip V';
  static const String brightness = 'Brightness';
  static const String contrast = 'Contrast';
  static const String grayscale = 'Grayscale';
  static const String crop = 'Crop';
  static const String apply = 'Apply';
  static const String reset = 'Reset';

  // â”€â”€ PDF Combiner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String pdfCombiner = 'PDF Combiner';
  static const String pdfCombinerDesc =
      'Merge multiple PDFs into a single document';
  static const String selectPdfs = 'Select PDFs';
  static const String emptyPdfsTitle = 'No PDFs selected';
  static const String emptyPdfsSubtitle = 'Tap + to select PDF files to merge';
  static const String mergePdfs = 'Merge PDFs';
  static const String mergeSuccess = 'PDFs Merged Successfully!';
  static const String mergeAnother = 'Merge Another';

  // â”€â”€ My Files â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String emptyFilesTitle = 'No files found';
  static const String emptyFilesSubtitle =
      'Documents you generate will appear here.';

  // â”€â”€ Errors â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorPermission =
      'Permission denied. Please grant access in Settings.';
  static const String errorInvalidFile =
      'Invalid file. Please select a supported format.';
  static const String errorNoImages = 'Please select at least one image.';
  static const String errorNoPdfs = 'Please select at least two PDFs to merge.';
  static const String errorProcessing =
      'Error during processing. Please try again.';

  // â”€â”€ About â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String aboutDescription =
      'Zenvix is a premium multi-tool utility app designed for power users. '
      'Built with â¤ï¸ using Flutter.';
}
