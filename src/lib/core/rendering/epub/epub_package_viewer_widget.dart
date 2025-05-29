// lib/core/rendering/epub/epub_package_viewer_widget.dart
import 'package:flutter/material.dart';
import 'package:novelist/core/rendering/epub/epub_package_controller.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart'; // Package's components
import 'package:novelist/core/app_constants.dart'; // For kDefaultPadding (optional, if needed for layout here)

class EpubPackageViewerWidget extends StatelessWidget {
  final EpubPackageController controller; // Our wrapper controller
  // The scroll controller is now managed internally by flutter_epub_viewer for paginated flow
  // If you need to control scrolling for a 'scrolled' flow, the package might offer ways.

  const EpubPackageViewerWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // You can wrap EpubViewer with padding or other layout widgets if needed
    // For example, if the AppBar and system UI insets are not automatically handled
    // by the InAppWebView within the package for your target platforms.
    // Usually, a Scaffold handles this.

    return EpubViewer(
      epubController: controller.packageController, // Pass the package's controller
      epubSource: controller.epubSource,
      initialCfi: controller.initialCfi,
      onEpubLoaded: controller.onEpubLoaded,
      onChaptersLoaded: controller.onChaptersLoaded,
      onRelocated: controller.onRelocated,
      displaySettings: EpubDisplaySettings(
        allowScriptedContent: true,
      ),
      // You might want to pass through other callbacks like onTextSelected, onAnnotationClicked
      // by adding them to EpubPackageController and then here.
      
      // Example of setting initial display settings:
      // displaySettings: EpubDisplaySettings(
      //   fontSize: controller.currentFontSize.toInt(), // Example
      //   // theme: controller.currentTheme, // Example
      //   flow: EpubFlow.paginated, // Default, but can be set
      //   snap: true, // Default
      // ),
    );
  }
}