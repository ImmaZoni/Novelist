class TocEntry {
  final String title;
  final int chapterIndexForDisplayLogic; // Index for direct navigation if known
  final int depth;
  final String? targetFileHref; // Actual href, e.g., "chapter1.xhtml#section2"

  TocEntry({
    required this.title,
    required this.chapterIndexForDisplayLogic,
    this.depth = 0,
    this.targetFileHref,
  });
}