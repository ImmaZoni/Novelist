// lib/core/rendering/epub/epub_viewer_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:novelist/core/app_constants.dart';
import 'package:novelist/core/error_handler.dart';
import 'package:novelist/core/rendering/epub/epub_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class EpubViewerWidget extends StatefulWidget {
  final EpubController controller;
  final ScrollController scrollController; // Pass scroll controller from ReadingScreen

  const EpubViewerWidget({
    super.key,
    required this.controller,
    required this.scrollController,
  });

  @override
  State<EpubViewerWidget> createState() => _EpubViewerWidgetState();
}

class _EpubViewerWidgetState extends State<EpubViewerWidget> {
  @override
  void initState() {
    super.initState();
    // Listen to controller changes to rebuild the widget
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant EpubViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      widget.controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    // This is called when notifyListeners() is called in the controller
    if (mounted) {
      setState(() {
        // The widget will rebuild with new data from the controller
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller; // Convenience

    if (controller.isLoading && controller.currentChapterHtmlContent == null) {
      // Show loading indicator only if content isn't already available (e.g., initial load)
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.loadingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Text(
            "Error: ${controller.loadingError}",
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (controller.currentChapterHtmlContent == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(kDefaultPadding),
          child: Text("No content available for this chapter."),
        ),
      );
    }

    // If loading a new chapter but old content exists, show old content with an overlay indicator.
    // This provides a smoother experience than a blank screen.
    // However, for simplicity now, we'll just rebuild. A more advanced version might use a Stack.

    return SingleChildScrollView(
      controller: widget.scrollController, // Use the passed ScrollController
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Html(
        data: controller.currentChapterHtmlContent!,
        style: {
          "body": Style(
            fontSize: FontSize(controller.currentFontSize),
            lineHeight: LineHeight.em(1.5),
            // Potentially add theme-based text color here later
          ),
          "p": Style(margin: Margins.only(bottom: controller.currentFontSize * 0.5)),
          "h1": Style(fontSize: FontSize(controller.currentFontSize * 1.8), fontWeight: FontWeight.bold),
          "h2": Style(fontSize: FontSize(controller.currentFontSize * 1.5), fontWeight: FontWeight.bold),
          "h3": Style(fontSize: FontSize(controller.currentFontSize * 1.3), fontWeight: FontWeight.bold),
          // Add more styles as needed
        },
        onLinkTap: (url, attributes, element) async {
          ErrorHandler.logInfo("Link tapped: $url", scope: "EpubViewerWidget");
          if (url != null) {
            final uri = Uri.tryParse(url);
            if (uri != null && (uri.isScheme("HTTP") || uri.isScheme("HTTPS"))) {
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Could not launch $url';
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not launch $url: $e')),
                  );
                }
              }
            } else {
              // Handle internal EPUB links (e.g., footnotes, cross-references)
              // This is more complex and might involve parsing the href to find a target
              // within the current EPUB document or another spine item.
              // For now, just log and show a message.
              ErrorHandler.logInfo("Internal EPUB link tapped: $url. Navigation not yet implemented.", scope: "EpubViewerWidget");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Internal link navigation not yet implemented: $url')),
                );
              }
            }
          }
        },
      ),
    );
  }
}