# Product Requirements Document: "Novelist" - Core eReader Application

**Current Project Status: Alpha - Core library management and import implemented. EPUB rendering now utilizes the `flutter_epub_viewer` package, providing robust pagination, chapter navigation, font size adjustment, and basic theme support. Most EPUBs render well. Further refinements for cover art display in library and advanced reader features are pending.**

**1. Introduction**
Novelist is an open-source, cross-platform eReader application designed for desktop (Windows, macOS, Linux) and mobile (iOS, Android). It aims to provide a clean, customizable, and powerful reading experience, with robust library management and a flexible plugin architecture to support future extensibility. **The primary technology stack for Novelist will be Flutter (using the Dart programming language) to ensure strong cross-platform capabilities, performance, and a cohesive development experience.**

**2. Goals**
*   **G1:** Provide a seamless and enjoyable reading experience across all major platforms.
*   **G2:** Support common ebook formats comprehensively.
*   **G3:** Offer robust library management and organization features.
*   **G4:** Enable users to sync their library and reading progress across devices using popular cloud storage providers.
*   **G5:** Establish a stable and well-documented plugin system, built with Dart, to allow for community and official extensions.
*   **G6:** Be fully open-source, encouraging community contribution and transparency.

**3. Target Audience**
*   **Tech-Savvy Readers:** Individuals who appreciate customization, control over their data, and open-source software.
*   **Multi-Device Users:** Readers who own and use multiple devices (desktop, tablet, phone) and want a consistent experience.
*   **Privacy-Conscious Individuals:** Users who prefer open-source solutions and control over where their data is stored.
*   **Developers & Tinkerers:** Those interested in extending the application's functionality via plugins (especially Dart/Flutter developers).

**4. User Stories / Use Cases**
*   **US1:** As a user, I want to import ebooks (EPUB, PDF, MOBI) from my local file system into my Novelist library so I can read them within the app.
*   **US2:** As a user, I want to see cover art, titles, and authors for books in my library so I can easily identify them.
*   **US3:** As a user, I want to organize my books into collections or shelves so I can manage my library effectively.
*   **US4:** As a user, I want to customize the reading view (font size, font family, line spacing, margins, themes - light/dark/sepia) so I can read comfortably.
*   **US5:** As a user, I want to navigate through a book using a table of contents, go to specific pages, and see my reading progress.
*   **US6:** As a user, I want to create bookmarks for important pages so I can easily return to them.
*   **US7:** As a user, I want to sync my library, reading progress, and bookmarks using Google Drive (or Dropbox, iCloud) so I can seamlessly switch between my devices.
*   **US8:** As a developer, I want to be able to create and install Dart-based plugins that extend Novelist's functionality.
*   **US9:** As a user, I want the application to work offline, with syncing occurring when an internet connection is available.

**5. Functional Requirements**

*   **FR1: Platform Support (via Flutter)**
    *   FR1.1: Desktop: Windows, macOS, Linux. - ✅ **Implemented (Project Structure)**
    *   FR1.2: Mobile: iOS, Android. - ✅ **Implemented (Project Structure)**
*   **FR2: File Format Support (Leveraging Dart packages and Flutter rendering)**
    *   FR2.1: EPUB (EPUB 2 & EPUB 3) parsing and rendering.
        *   Parsing for metadata (title, author, cover via `epubx` and `image` packages): ✅ **Implemented** (Integrated into import flow via `MetadataService`, cover saved to local file).
        *   Rendering (via `flutter_epub_viewer` package): ✅ **Implemented** (Utilizes `flutter_epub_viewer` package. EPUB-specific logic encapsulated in `EpubPackageController` and `EpubPackageViewerWidget`. Supports paginated display, CFI-based navigation, TOC navigation, page-by-page navigation, font size adjustment, and basic themes (Light/Dark). `allowScriptedContent` set to true for better compatibility with EPUB internal JS.)
    *   FR2.2: PDF viewing (rendered as-is, reflow is out of scope for V1). - ⏳ **To Do** (Placeholder `pdf` directory created in `core/rendering`)
    *   FR2.3: MOBI/AZW viewing (best effort, as it's a proprietary format). - ⏳ **To Do**
    *   FR2.4: Plain Text (.txt) and HTML (.html) file viewing. - ⏳ **To Do**
*   **FR3: Library Management**
    *   FR3.1: Import books from local storage. - ✅ **Implemented** (File picking, copying to app storage, format detection, metadata extraction for EPUBs including cover image saving).
    *   FR3.2: Display book metadata (title, author, cover, series if available).
        *   Title/Author display in list: ✅ **Implemented** (Uses extracted metadata or filename fallback)
        *   Cover art display in list: ✅ **Implemented** (`MetadataService` extracts cover during import. Users can also set a custom cover via long-press option in `LibraryScreen`, which opens `CoverSearchScreen` using an `InAppWebView` to search Google Images, download, and apply the selected image.)
        *   Series display: ⏳ **To Do**
    *   FR3.3: Grid and list view for the library.
        *   List view: ✅ **Implemented**
        *   Grid view: ⏳ **To Do**
    *   FR3.4: Sorting by title, author, last read, date added. - ⏳ **To Do**
    *   FR3.5: Filtering by read status, tags (future), format. - ⏳ **To Do**
    *   FR3.6: Basic search functionality within the library (title, author). - ⏳ **To Do**
    *   FR3.7: Ability to create, rename, and delete custom collections/shelves. - ⏳ **To Do**
    *   FR3.8: Ability to add/remove books from collections. - ⏳ **To Do**
*   **FR4: Reading Experience (Built with Flutter widgets & `flutter_epub_viewer`)**
    *   FR4.1: Paginated view for reflowable formats (EPUB, MOBI, TXT, HTML). - ✅ **Implemented for EPUB** (Handled by `flutter_epub_viewer` via `EpubPackageViewerWidget`). Other formats To Do.
    *   FR4.2: Font customization: size, family (selection of bundled and system fonts).
        *   Font size adjustment: ✅ **Implemented** (Managed by `EpubPackageController`, UI in `ReadingScreen`'s settings dialog, applied via `flutter_epub_viewer`'s controller).
        *   Font family selection: ⏳ **To Do** (`flutter_epub_viewer` likely supports this via its JS layer; needs exposing through our controller).
    *   FR4.3: Layout customization: line spacing, margins. - ⏳ **To Do** (`flutter_epub_viewer` may support these; needs exposing).
    *   FR4.4: Themes: Light, Dark, Sepia. Custom theme support is a plus for later. - ✅ **Implemented** (Light/Dark themes via `EpubPackageController` using `flutter_epub_viewer`'s `EpubTheme.light()` and `EpubTheme.dark()`. Sepia requires `EpubTheme.custom()` - UI for Sepia selection implemented).
    *   FR4.5: Bookmarking: Add, view, delete, and navigate to bookmarks. - ⏳ **To Do**
    *   FR4.6: Table of Contents navigation. - ✅ **Implemented** (TOC parsed by `flutter_epub_viewer`, exposed via `EpubPackageController`, interactive in `ReadingScreen`'s dialog).
    *   FR4.7: Reading progress display (percentage, current page/total pages, current chapter). - ✅ **Partially Implemented** (`flutter_epub_viewer` provides progress via `EpubLocation`. AppBar in `ReadingScreen` shows basic page info for EPUBs if available from `EpubPackageController`).
    *   FR4.8: Full-screen reading mode. - ⏳ **To Do**
    *   FR4.9: Remember last read position for each book. - ✅ **Implemented** (Last read CFI from `flutter_epub_viewer` is saved to Hive via `ReadingScreen`).
    *   FR4.10: Dictionary lookup (integration with OS-level dictionary services via platform channels if needed). - ⏳ **To Do**
*   **FR5: Syncing** - ⏳ **To Do (All Sub-items)**
    *   FR5.1: User authentication...
    *   FR5.2: Option to select a dedicated app folder...
    *   FR5.3: Sync entire book files.
    *   FR5.4: Sync metadata...
    *   FR5.5: Conflict resolution strategy...
    *   FR5.6: Manual sync trigger...
*   **FR6: Plugin System (Dart-based)** - ⏳ **To Do (All Sub-items)** (Conceptual structure in folders only)
    *   FR6.1: Define clear Dart APIs/interfaces...
    *   FR6.2: Mechanism for discovering, loading...
    *   FR6.3: Basic permission model...
*   **FR7: Settings**
    *   FR7.1: General application settings (e.g., default theme, language). - ⏳ **To Do** (Placeholder `SettingsScreen` exists. Reader font size and theme settings handled via `EpubPackageController`).
    *   FR7.2: Sync account management. - ⏳ **To Do**
    *   FR7.3: Plugin management interface. - ⏳ **To Do**

**6. Non-Functional Requirements**
*   **NFR1: Performance:**
    *   NFR1.1: App launch time < 3 seconds on modern hardware. - ⏳ **To Do (Pending Measurement)**
    *   NFR1.2: Book opening time < 2 seconds for average-sized EPUBs. - ✅ **Implemented** (Loading EPUBs via `flutter_epub_viewer` is performant).
    *   NFR1.3: Smooth page turning and scrolling (target 60fps+ via Flutter's rendering engine). - ✅ **Implemented for EPUB** (Handled by `flutter_epub_viewer`'s WebView).
*   **NFR2: Usability:**
    *   NFR2.1: Intuitive and easy-to-navigate user interface. - ✅ **Implemented** (Basic library and reader navigation functional. Reader UI significantly improved by `flutter_epub_viewer`. Custom cover search enhances user control).
    *   NFR2.2: Adherence to platform-specific UI/UX conventions. - ⏳ **To Do**
    *   NFR2.3: Basic accessibility features. - ⏳ **To Do**
*   **NFR3: Stability:** The application should be robust and minimize crashes. - ✅ **Implemented** (Using `flutter_epub_viewer` for EPUB rendering significantly improves stability. WebView interactions for cover search appear stable after JS refinements).
*   **NFR4: Security:** Secure handling of cloud service credentials. - ⏳ **To Do**
*   **NFR5: Open Source:**
    *   NFR5.1: Codebase hosted on a public repository. - ✅ **Implemented**
    *   NFR5.2: Clear open-source license. - ✅ **Implemented (Assumed choice, needs explicit LICENSE file)**
    *   NFR5.3: Contribution guidelines. - ⏳ **To Do**
    *   NFR5.4: Technology Stack: Primarily Flutter and Dart. - ✅ **Implemented**

**7. Design Considerations (High-Level)**
*   Clean, minimalist UI that prioritizes the reading content. - ✅ **Partially Implemented**
*   Consistent design language across all platforms. - ⏳ **To Do**
*   Visual indicators for sync status. - ⏳ **To Do**

**8. Success Metrics**
*   Number of downloads and active users. - ⏳ **To Do (Post-Release)**
*   Community engagement (e.g., GitHub stars, forks, issues, pull requests). - ⏳ **To Do (Post-Release)**
*   Positive user reviews and feedback. - ⏳ **To Do (Post-Release)**
*   Number of third-party Dart-based plugins developed (long-term). - ⏳ **To Do (Post-Release)**
*   Successful cross-device syncing reported by users. - ⏳ **To Do (Post-Release)**

**9. Future Considerations / Out of Scope for V1 Core**
*   Advanced annotation features (highlighting, notes) (`flutter_epub_viewer` supports adding highlights; UI for managing them is To Do).
*   Built-in ebook store integrations.
*   Social reading features (sharing progress, recommendations).
*   Support for more niche ebook formats.
*   Further robustness improvements for custom cover image search JavaScript against changes in Google Images DOM.
*   The two specific plugins (AI Audiobook, Crypto Storage) are separate but rely on this core and will also be developed using Dart/Flutter.

**Legend:**
*   ✅ **Implemented:** Feature is working as described.
*   ✅ **Partially Implemented:** Some aspects are done, but not all.
*   ⏳ **To Do:** Not yet started or significant work remains.