# ProGuard rules for ToolForge

# PDFBox / JPXFilter related warnings
# These classes are missing from the runtime and are only needed for JPEG 2000 support.
# If you don't use JPEG 2000 in your PDFs, you can safely ignore these.
-dontwarn com.gemalto.jp2.**

# Preserve PDFBox classes
-keep class com.tom_roush.pdfbox.** { *; }
-dontwarn com.tom_roush.pdfbox.filter.JPXFilter
