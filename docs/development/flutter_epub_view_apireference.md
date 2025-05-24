Okay, thank you for your patience and for providing all the code! I've gone through it.

Here is the comprehensive API reference for the `flutter_epub_viewer` package, derived directly from the source code you provided.

---

# `flutter_epub_viewer` API Reference (Code-Based)

This document provides a detailed API reference for the `flutter_epub_viewer` package, version 1.2.1. All information is sourced directly from the provided Dart and supporting files.

## Table of Contents

1.  [Overview](#1-overview)
2.  [Main Package Exports (`lib/flutter_epub_viewer.dart`)](#2-main-package-exports)
3.  [Widgets](#3-widgets)
    *   [`EpubViewer`](#31-epubviewer)
4.  [Controllers](#4-controllers)
    *   [`EpubController`](#41-epubcontroller)
    *   [`LocalServerController`](#42-localservercontroller) (Likely internal utility)
5.  [Data Models & Types (`lib/src/helper.dart`)](#5-data-models--types)
    *   [`EpubChapter`](#51-epubchapter)
    *   [`EpubSearchResult`](#52-epubsearchresult)
    *   [`EpubLocation`](#53-epublocation)
    *   [`EpubDisplaySettings`](#54-epubdisplaysettings)
    *   [`EpubTextSelection`](#55-epubtextselection)
    *   [`EpubSource`](#56-epubsource)
    *   [`EpubTheme`](#57-epubtheme)
    *   [`EpubTextExtractRes`](#58-epubtextextractres)
    *   [`EpubDataLoader` (Abstract)](#59-epubdataloader-abstract)
    *   [`FileEpubLoader`](#510-fileepubloader)
    *   [`UrlEpubLoader`](#511-urlepubloader)
    *   [`AssetEpubLoader`](#512-assetepubloader)
6.  [Enums (`lib/src/helper.dart`)](#6-enums)
    *   [`EpubSpread`](#61-epubspread)
    *   [`EpubFlow`](#62-epubflow)
    *   [`EpubDefaultDirection`](#63-epubdefaultdirection)
    *   [`EpubManager`](#64-epubmanager)
    *   [`EpubThemeType`](#65-epubthemetype)
7.  [Utilities (`lib/src/utils.dart`)](#7-utilities)
    *   [`ColorToHex` (Extension on `Color`)](#71-colortohex-extension)
8.  [JavaScript Bridge (`lib/assets/webpage/html/epubView.js`)](#8-javascript-bridge)
    *   [JavaScript Functions Called by Dart](#81-javascript-functions-called-by-dart)
    *   [JavaScript Handlers Registered by Dart](#82-javascript-handlers-registered-by-dart)
9.  [Dependencies (`pubspec.yaml`)](#9-dependencies)
10. [Assets (`pubspec.yaml`)](#10-assets)

---

## 1. Overview

The `flutter_epub_viewer` package provides a Flutter widget and controller for displaying and interacting with EPUB documents. It leverages `flutter_inappwebview` to render EPUB content using the `Epub.js` JavaScript library.

---

## 2. Main Package Exports (`lib/flutter_epub_viewer.dart`)

When importing `package:flutter_epub_viewer/flutter_epub_viewer.dart`, the following are directly available:

*   `EpubViewer` (Widget)
*   `EpubController` (Controller)
*   All public classes and enums from `lib/src/helper.dart`:
    *   `EpubChapter`
    *   `EpubSearchResult`
    *   `EpubLocation`
    *   `EpubDisplaySettings`
    *   `EpubTextSelection`
    *   `EpubSource`
    *   `EpubTheme`
    *   `EpubTextExtractRes`
    *   `EpubDataLoader`
    *   `FileEpubLoader`
    *   `UrlEpubLoader`
    *   `AssetEpubLoader`
    *   `EpubSpread` (Enum)
    *   `EpubFlow` (Enum)
    *   `EpubDefaultDirection` (Enum)
    *   `EpubManager` (Enum)
    *   `EpubThemeType` (Enum)
*   From `package:flutter_inappwebview/flutter_inappwebview.dart`:
    *   `ContextMenu`
    *   `ContextMenuSettings`
    *   `ContextMenuItem`

---

## 3. Widgets

### 3.1. `EpubViewer`

A `StatefulWidget` that displays the EPUB content within an `InAppWebView`.

**Constructor:**

```dart
const EpubViewer({
  super.key,
  required this.epubController,
  required this.epubSource,
  this.initialCfi,
  this.onChaptersLoaded,
  this.onEpubLoaded,
  this.onRelocated,
  this.onTextSelected,
  this.displaySettings,
  this.selectionContextMenu,
  this.onAnnotationClicked,
})
```

**Parameters:**

*   `key`: `Key?` (Inherited from `Widget`)
*   `epubController`: `EpubController` **(required)**
    *   The controller to manage and interact with this EPUB viewer.
*   `epubSource`: `EpubSource` **(required)**
    *   Defines the source of the EPUB file (URL, local file, or Flutter asset).
*   `initialCfi`: `String?`
    *   An EPUB Canonical Fragment Identifier (CFI) string. If provided, the viewer will attempt to navigate to this location upon loading the EPUB. If `null`, the EPUB loads from the beginning.
*   `onChaptersLoaded`: `ValueChanged<List<EpubChapter>>?`
    *   Callback invoked when the EPUB's chapters (Table of Contents) have been parsed and are available.
*   `onEpubLoaded`: `VoidCallback?`
    *   Callback invoked when the EPUB has been successfully loaded and the initial display is rendered.
*   `onRelocated`: `ValueChanged<EpubLocation>?`
    *   Callback invoked when the current view location within the EPUB changes (e.g., page turn, navigation).
*   `onTextSelected`: `ValueChanged<EpubTextSelection>?`
    *   Callback invoked when text is selected by the user within the EPUB.
*   `displaySettings`: `EpubDisplaySettings?`
    *   Initial display settings for the EPUB viewer. If `null`, default settings from `EpubDisplaySettings` constructor are used.
*   `selectionContextMenu`: `ContextMenu?` (from `flutter_inappwebview`)
    *   Custom context menu to display when text is selected. If `null`, the default WebView context menu is used.
*   `onAnnotationClicked`: `ValueChanged<String>?`
    *   Callback invoked when an annotation (e.g., highlight) is clicked. The argument is the CFI string of the clicked annotation.

**Internal State & Behavior:**

*   Manages an `InAppWebViewController`.
*   Initializes JavaScript handlers to communicate between Flutter and the WebView (`epubView.js`).
*   Loads the EPUB book by calling the `loadBook` JavaScript function with data from `epubSource` and `displaySettings`.
*   The `InAppWebViewSettings` used are:
    *   `isInspectable`: `kDebugMode`
    *   `javaScriptEnabled`: `true`
    *   `mediaPlaybackRequiresUserGesture`: `false`
    *   `transparentBackground`: `true`
    *   `supportZoom`: `false`
    *   `allowsInlineMediaPlayback`: `true`
    *   `disableLongPressContextMenuOnLinks`: `false`
    *   `iframeAllowFullscreen`: `true`
    *   `allowsLinkPreview`: `false`
    *   `verticalScrollBarEnabled`: `false`
    *   `selectionGranularity`: `SelectionGranularity.CHARACTER`
    *   `disableVerticalScroll`: Value from `widget.displaySettings?.snap ?? false`.

---

## 4. Controllers

### 4.1. `EpubController`

Manages the state and programmatic interactions with an `EpubViewer`.

**Constructor:**

```dart
EpubController()
```

**Public Fields:**

*   `InAppWebViewController? webViewController`
    *   The underlying web view controller. Set via `setWebViewController`. Direct manipulation is generally not recommended; use controller methods.
*   `Completer searchResultCompleter = Completer<List<EpubSearchResult>>();`
    *   Used internally to complete the future returned by the `search` method.
*   `Completer<EpubTextExtractRes> pageTextCompleter = Completer<EpubTextExtractRes>();`
    *   Used internally to complete the future returned by text extraction methods.

**Public Methods:**

*   `void setWebViewController(InAppWebViewController controller)`
    *   Sets the internal `webViewController`. Typically called by `EpubViewer`.
*   `void display({required String cfi})`
    *   Navigates the EPUB view to a specific location identified by the `cfi` string (can be a chapter href or a precise CFI).
    *   Throws an `Exception` if the EPUB viewer is not loaded.
*   `void next()`
    *   Moves to the next page in the EPUB view.
    *   Throws an `Exception` if the EPUB viewer is not loaded.
*   `void prev()`
    *   Moves to the previous page in the EPUB view.
    *   Throws an `Exception` if the EPUB viewer is not loaded.
*   `Future<EpubLocation> getCurrentLocation()`
    *   Returns an `EpubLocation` object representing the current viewing position.
    *   Throws an `Exception` if EPUB locations are not loaded or if the viewer is not loaded.
*   `List<EpubChapter> getChapters()`
    *   Returns the list of parsed `EpubChapter` objects.
    *   Relies on `parseChapters` having been called (usually triggered by `onChaptersLoaded`).
    *   Throws an `Exception` if the EPUB viewer is not loaded.
*   `Future<List<EpubChapter>> parseChapters()`
    *   Parses the chapter list from the EPUB via JavaScript. Caches the result.
    *   Returns the list of `EpubChapter` objects.
    *   Throws an `Exception` if the EPUB viewer is not loaded.
*   `Future<List<EpubSearchResult>> search({required String query})`
    *   Searches the EPUB content for the given `query` string.
    *   Returns a `Future` that completes with a list of `EpubSearchResult` objects.
    *   Returns an empty list if `query` is empty.
    *   Throws an `Exception` if the EPUB viewer is not loaded.
*   `void addHighlight({required String cfi, Color color = Colors.yellow, double opacity = 0.3})`
    *   Adds a highlight annotation to the EPUB content at the specified `cfi` range.
    *   `cfi`: The CFI string defining the text range.
    *   `color`: The `Color` of the highlight (default: `Colors.yellow`).
    *   `opacity`: The opacity of the highlight (default: `0.3`).
    *   Throws an `Exception` if the EPUB viewer is not loaded.
*   `void addUnderline({required String cfi})`
    *   Adds an underline annotation at the specified `cfi`.
    *   Throws an `Exception` if the EPUB viewer is not loaded.
*   `void removeHighlight({required String cfi})`
    *   Removes a highlight annotation identified by its `cfi` string.
    *   Throws an `Exception` if the EPUB viewer is not loaded.
*   `void removeUnderline({required String cfi})`
    *   Removes an underline annotation identified by its `cfi` string.
    *   Throws an `Exception` if the EPUB viewer is not loaded.
*   `Future<void> setSpread({required EpubSpread spread})`
    *   Sets the spread mode for the EPUB display (e.g., `EpubSpread.auto`).
*   `Future<void> setFlow({required EpubFlow flow})`
    *   Sets the flow mode for the EPUB display (e.g., `EpubFlow.paginated`).
*   `Future<void> setManager({required EpubManager manager})`
    *   Sets the rendering manager type (e.g., `EpubManager.continuous`).
*   `Future<void> setFontSize({required double fontSize})`
    *   Adjusts the font size of the EPUB content. `fontSize` is a `double` but passed as a string to JS.
*   `Future<void> updateTheme({required EpubTheme theme})`
    *   Applies the specified `EpubTheme` (background and foreground colors) to the reader.
*   `Future<EpubTextExtractRes> extractText({required String startCfi, required String endCfi})`
    *   Extracts the plain text content from the EPUB within the given CFI range.
    *   Returns an `EpubTextExtractRes` object containing the text and CFI range.
    *   Throws an `Exception` if the EPUB viewer is not loaded.
*   `Future<EpubTextExtractRes> extractCurrentPageText()`
    *   Extracts the plain text content from the currently visible page(s).
    *   Returns an `EpubTextExtractRes` object.
    *   Throws an `Exception` if the EPUB viewer is not loaded.
*   `void toProgressPercentage(double progressPercent)`
    *   Navigates to a location corresponding to `progressPercent` (0.0 to 1.0).
    *   Asserts `progressPercent` is within range.
    *   Throws an `Exception` if the EPUB viewer is not loaded.
*   `void moveToFirstPage()`
    *   Navigates to the beginning of the EPUB (progress 0.0).
*   `void moveToLastPage()`
    *   Navigates to the end of the EPUB (progress 1.0).
*   `void checkEpubLoaded()`
    *   Utility method that throws an `Exception` if `webViewController` is `null`.

### 4.2. `LocalServerController`

A controller for managing an `InAppLocalhostServer`. This seems to be an internal utility for serving the web assets (`swipe.html`, `epubView.js`, etc.) required by the `InAppWebView`. It is not directly used in the provided `EpubViewer` or `EpubController` code but is present in `epub_controller.dart`.

**Constructor:**

```dart
LocalServerController()
```

**Public Methods:**

*   `Future<void> initServer()`
    *   Starts the `InAppLocalhostServer` if it's not already running. The server's document root is 'packages/flutter_epub_viewer/lib/assets/webpage'.
*   `Future<void> disposeServer()`
    *   Closes the `InAppLocalhostServer` if it is running.

---

## 5. Data Models & Types (`lib/src/helper.dart`)

These classes define the structure of data exchanged with the JavaScript layer and used within the Flutter application. Most are annotated with `@JsonSerializable`.

### 5.1. `EpubChapter`

Represents a chapter in the EPUB's Table of Contents.

**Constructor:**

```dart
EpubChapter({
  required this.title,
  required this.href,
  required this.id,
  required this.subitems,
})
```

**Fields:**

*   `final String title`: The title of the chapter.
*   `final String href`: The hyperlink reference (or CFI fragment) to the chapter's content.
*   `final String id`: The ID of the chapter.
*   `final List<EpubChapter> subitems`: A list of nested sub-chapters.

**JSON Serialization:**

*   `factory EpubChapter.fromJson(Map<String, dynamic> json)`
*   `Map<String, dynamic> toJson()`

### 5.2. `EpubSearchResult`

Represents a single search result.

**Constructor:**

```dart
EpubSearchResult({
  required this.cfi,
  required this.excerpt,
})
```

**Fields:**

*   `String cfi`: The CFI string pointing to the location of the search result.
*   `String excerpt`: A snippet of text showing the context of the search result.

**JSON Serialization:**

*   `factory EpubSearchResult.fromJson(Map<String, dynamic> json)`
*   `Map<String, dynamic> toJson()`

### 5.3. `EpubLocation`

Represents a specific location within the EPUB.

**Constructor:**

```dart
EpubLocation({
  required this.startCfi,
  required this.endCfi,
  required this.progress,
})
```

**Fields:**

*   `String startCfi`: Start CFI string of the current view/page.
*   `String endCfi`: End CFI string of the current view/page.
*   `double progress`: Reading progress as a percentage (0.0 to 1.0).

**JSON Serialization:**

*   `factory EpubLocation.fromJson(Map<String, dynamic> json)`
*   `Map<String, dynamic> toJson()`

### 5.4. `EpubDisplaySettings`

Defines display settings for the EPUB viewer.

**Constructor:**

```dart
EpubDisplaySettings({
  this.fontSize = 15,
  this.spread = EpubSpread.auto,
  this.flow = EpubFlow.paginated,
  this.allowScriptedContent = false,
  this.defaultDirection = EpubDefaultDirection.ltr,
  this.snap = true,
  this.useSnapAnimationAndroid = false,
  this.manager = EpubManager.continuous,
  this.theme,
})
```

**Fields:**

*   `int fontSize`: Font size (default: `15`).
*   `EpubSpread spread`: Page spread mode (default: `EpubSpread.auto`).
*   `EpubFlow flow`: Content flow mode (default: `EpubFlow.paginated`).
*   `EpubDefaultDirection defaultDirection`: Default reading direction (default: `EpubDefaultDirection.ltr`).
*   `bool allowScriptedContent`: Whether to allow scripted content in the EPUB (default: `false`).
*   `EpubManager manager`: Rendering manager type (default: `EpubManager.continuous`).
*   `bool snap`: Enables swipe between pages in paginated flow (default: `true`).
*   `final bool useSnapAnimationAndroid`: Uses animation for page snapping on Android if `snap` is true. **Warning:** May break `onRelocated` callback (default: `false`).
*   `final EpubTheme? theme`: Theme for the reader (background/foreground colors). If `null`, the book's default theme or a system theme is used (default: `null`).

**JSON Serialization:**

*   `factory EpubDisplaySettings.fromJson(Map<String, dynamic> json)`
*   `Map<String, dynamic> toJson()`

### 5.5. `EpubTextSelection`

Represents a piece of text selected by the user.

**Constructor:**

```dart
EpubTextSelection({
  required this.selectedText,
  required this.selectionCfi,
})
```

**Fields:**

*   `final String selectedText`: The actual text content that was selected.
*   `final String selectionCfi`: The CFI string range representing the selection.

### 5.6. `EpubSource`

Represents the source from which an EPUB will be loaded.

**Private Constructor:**

```dart
EpubSource._({required this.epubData})
```

**Factory Constructors:**

*   `factory EpubSource.fromFile(File file)`
    *   Loads EPUB data from a local `File`.
*   `factory EpubSource.fromUrl(String url, {Map<String, String>? headers})`
    *   Loads EPUB data from a network `url`, with optional HTTP `headers`.
*   `factory EpubSource.fromAsset(String assetPath)`
    *   Loads EPUB data from a Flutter asset specified by `assetPath`.

**Fields:**

*   `final Future<Uint8List> epubData`: A future that completes with the EPUB's byte data.

### 5.7. `EpubTheme`

Defines theming for the EPUB content (background and foreground colors).

**Private Constructor:**

```dart
EpubTheme._({
  this.backgroundColor,
  this.foregroundColor,
  required this.themeType,
})
```

**Factory Constructors:**

*   `factory EpubTheme.dark()`
    *   Creates a dark theme (black background `0xff121212`, white foreground). `themeType` is `EpubThemeType.dark`.
*   `factory EpubTheme.light()`
    *   Creates a light theme (white background, black foreground). `themeType` is `EpubThemeType.light`.
*   `factory EpubTheme.custom({required Color backgroundColor, required Color foregroundColor})`
    *   Creates a custom theme with specified `backgroundColor` and `foregroundColor`. `themeType` is `EpubThemeType.custom`.

**Fields:**

*   `Color? backgroundColor`: The background color.
*   `Color? foregroundColor`: The foreground (text) color.
*   `EpubThemeType themeType`: The type of the theme.

### 5.8. `EpubTextExtractRes`

Represents the result of a text extraction operation.

**Constructor:**

```dart
EpubTextExtractRes({
  this.text,
  this.cfiRange,
})
```

**Fields:**

*   `String? text`: The extracted text content.
*   `String? cfiRange`: The CFI range from which the text was extracted.

**JSON Serialization:**

*   `factory EpubTextExtractRes.fromJson(Map<String, dynamic> json)`
*   `Map<String, dynamic> toJson()`

### 5.9. `EpubDataLoader` (Abstract)

Abstract interface for loading EPUB data.

**Abstract Method:**

*   `Future<Uint8List> loadData()`

### 5.10. `FileEpubLoader`

Implementation of `EpubDataLoader` for loading from the file system.

**Constructor:**

```dart
FileEpubLoader(this.file)
```

**Fields:**

*   `final File file`: The file to load.

**Methods:**

*   `@override Future<Uint8List> loadData()`: Reads and returns the file's content as bytes.

### 5.11. `UrlEpubLoader`

Implementation of `EpubDataLoader` for loading from a URL.

**Constructor:**

```dart
UrlEpubLoader(this.url, {this.headers})
```

**Fields:**

*   `final String url`: The URL to load from.
*   `final Map<String, String>? headers`: Optional HTTP headers.

**Methods:**

*   `@override Future<Uint8List> loadData()`: Downloads and returns the URL's content as bytes. Throws an `Exception` on failure (e.g., non-200 status code).

### 5.12. `AssetEpubLoader`

Implementation of `EpubDataLoader` for loading from Flutter assets.

**Constructor:**

```dart
AssetEpubLoader(this.assetPath)
```

**Fields:**

*   `final String assetPath`: The path to the asset.

**Methods:**

*   `@override Future<Uint8List> loadData()`: Loads and returns the asset's content as bytes.

---

## 6. Enums (`lib/src/helper.dart`)

### 6.1. `EpubSpread`

Defines how pages are spread in the viewer.

*   `none`: Displays a single page.
*   `always`: Displays two pages.
*   `auto`: Displays single or two pages based on device size.

### 6.2. `EpubFlow`

Defines how EPUB content flows.

*   `paginated`: Content is divided into discrete pages.
*   `scrolled`: Content is presented as a continuous scroll.

### 6.3. `EpubDefaultDirection`

Defines the default reading direction.

*   `ltr`: Left-to-right.
*   `rtl`: Right-to-left.

### 6.4. `EpubManager`

Defines the manager type used by Epub.js for rendering.

*   `continuous`
    *(Note: The `epubView.js` refers to this as `manager` parameter in `rendition = book.renderTo(...)`. The enum in Dart only has `continuous`. Epub.js itself supports "default" and "continuous" managers.)*

### 6.5. `EpubThemeType`

Identifies the type of `EpubTheme`.

*   `dark`
*   `light`
*   `custom`

---

## 7. Utilities (`lib/src/utils.dart`)

### 7.1. `ColorToHex` (Extension on `Color`)

**Extension Method:**

*   `String toHex({bool includeAlpha = false})`
    *   Converts the `Color` to a hex string.
    *   Format: `#RRGGBB` if `includeAlpha` is `false` (default).
    *   Format: `#AARRGGBB` if `includeAlpha` is `true`.

---

## 8. JavaScript Bridge (`lib/assets/webpage/html/epubView.js`)

The Dart code communicates with `epubView.js` running inside the `InAppWebView`.

### 8.1. JavaScript Functions Called by Dart (`EpubController` via `evaluateJavascript`)

*   `loadBook(data, cfi, manager, flow, spread, snap, allowScriptedContent, direction, useCustomSwipe, backgroundColor, foregroundColor)`: Initializes and renders the EPUB.
*   `toCfi(cfi)`: Navigates to a specific CFI.
*   `next()`: Goes to the next page.
*   `previous()`: Goes to the previous page.
*   `getCurrentLocation()`: Returns current location object (`{startCfi, endCfi, progress}`).
*   `getChapters()`: Returns the array of chapter objects.
*   `searchInBook(query)`: Initiates a search.
*   `addHighlight(cfiRange, color, opacity)`: Adds a highlight.
*   `addUnderLine(cfiString)`: Adds an underline.
    *   (`addMark(cfiString)` exists in JS but is commented out in Dart controller).
*   `removeHighlight(cfiString)`: Removes a highlight.
*   `removeUnderLine(cfiString)`: Removes an underline.
    *   (`removeMark(cfiString)` exists in JS but is commented out in Dart controller).
*   `setSpread(spread)`: Sets the spread mode.
*   `setFlow(flow)`: Sets the flow mode.
*   `setManager(manager)`: Sets the manager.
*   `setFontSize(fontSize)`: Sets the font size.
*   `updateTheme(backgroundColor, foregroundColor)`: Applies theme colors.
*   `getTextFromCfi(startCfi, endCfi)`: Extracts text from a CFI range.
*   `getCurrentPageText()`: Extracts text from the current page.
*   `toProgress(progressPercent)`: Navigates to a progress percentage.

### 8.2. JavaScript Handlers Registered by Dart (`EpubViewer` via `addJavaScriptHandler`)

These functions in `epubView.js` call `window.flutter_inappwebview.callHandler(...)` which are received by Dart:

*   `readyToLoad`: Called when `flutterInAppWebViewPlatformReady` event fires in JS. Triggers `loadBook()` in Dart.
*   `displayed`: Called when `rendition.display()` promise resolves. Triggers `onEpubLoaded` in Dart.
*   `rendered`: Called when `rendition.on("rendered", ...)` fires. (No direct callback in `EpubViewer` for this specific handler, but it's registered).
*   `chapters`: Called when `book.loaded.navigation` promise resolves. Triggers `parseChapters()` and `onChaptersLoaded` in Dart.
*   `selection`: Called when `rendition.on("selected", ...)` fires. Triggers `onTextSelected` in Dart with `EpubTextSelection`.
*   `search`: Called when JS `search(query).then(...)` resolves. Completes `epubController.searchResultCompleter` in Dart.
*   `relocated`: Called when `rendition.on("relocated", ...)` fires. Triggers `onRelocated` in Dart with `EpubLocation`.
*   `displayError`: Called when `rendition.on('displayError', ...)` fires. (No direct callback in `EpubViewer` for this, but it's registered).
*   `markClicked`: Called when `rendition.on('markClicked', ...)` fires. Triggers `onAnnotationClicked` in Dart.
*   `epubText`: Called when JS `getTextFromCfi` or `getCurrentPageText` promise resolves. Completes `epubController.pageTextCompleter` in Dart.

---

## 9. Dependencies (`pubspec.yaml`)

**Main Dependencies:**

*   `flutter` (SDK)
*   `flutter_inappwebview: ^6.1.5`
*   `http: ^1.3.0`
*   `json_annotation: ^4.9.0`

**Dev Dependencies:**

*   `flutter_test`
*   `flutter_lints: ^3.0.0`
*   `build_runner: ^2.3.3`
*   `json_serializable: ^6.6.0`

---

## 10. Assets (`pubspec.yaml`)

*   `lib/assets/webpage/dist/` (This directory is listed but its contents like `epub.js`, `jszip.min.js` are referenced from `swipe.html` but not explicitly detailed in `pubspec.yaml` listing. It implies all contents of `dist/` are assets.)
    *   `jszip.min.js` (Referenced in `swipe.html`)
    *   `epub.js` (Referenced in `swipe.html`)
*   `lib/assets/webpage/html/`
    *   `ajax-loader.gif` (Not directly used by `swipe.html` but present)
    *   `epubView.js`
    *   `examples.css`
    *   `swipe.html` (Initial file loaded by `InAppWebView`)
    *   `themes.css`

---

This concludes the code-based API reference for `flutter_epub_viewer` v1.2.1.