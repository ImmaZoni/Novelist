# Product Requirements Document: "Novelist" - Core eReader Application

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
    *   FR1.1: Desktop: Windows, macOS, Linux.
    *   FR1.2: Mobile: iOS, Android.
*   **FR2: File Format Support (Leveraging Dart packages and Flutter rendering)**
    *   FR2.1: EPUB (EPUB 2 & EPUB 3) parsing and rendering.
    *   FR2.2: PDF viewing (rendered as-is, reflow is out of scope for V1).
    *   FR2.3: MOBI/AZW viewing (best effort, as it's a proprietary format).
    *   FR2.4: Plain Text (.txt) and HTML (.html) file viewing.
*   **FR3: Library Management**
    *   FR3.1: Import books from local storage.
    *   FR3.2: Display book metadata (title, author, cover, series if available).
    *   FR3.3: Grid and list view for the library.
    *   FR3.4: Sorting by title, author, last read, date added.
    *   FR3.5: Filtering by read status, tags (future), format.
    *   FR3.6: Basic search functionality within the library (title, author).
    *   FR3.7: Ability to create, rename, and delete custom collections/shelves.
    *   FR3.8: Ability to add/remove books from collections.
*   **FR4: Reading Experience (Built with Flutter widgets)**
    *   FR4.1: Paginated view for reflowable formats (EPUB, MOBI, TXT, HTML).
    *   FR4.2: Font customization: size, family (selection of bundled and system fonts).
    *   FR4.3: Layout customization: line spacing, margins.
    *   FR4.4: Themes: Light, Dark, Sepia. Custom theme support is a plus for later.
    *   FR4.5: Bookmarking: Add, view, delete, and navigate to bookmarks.
    *   FR4.6: Table of Contents navigation.
    *   FR4.7: Reading progress display (percentage, current page/total pages, current chapter).
    *   FR4.8: Full-screen reading mode.
    *   FR4.9: Remember last read position for each book.
    *   FR4.10: Dictionary lookup (integration with OS-level dictionary services via platform channels if needed).
*   **FR5: Syncing**
    *   FR5.1: User authentication via OAuth 2.0 for Google Drive, Dropbox. Platform-specific mechanism for iCloud (utilizing Flutter packages and platform channels where necessary).
    *   FR5.2: Option to select a dedicated app folder in the chosen cloud service.
    *   FR5.3: Sync entire book files.
    *   FR5.4: Sync metadata: reading progress, bookmarks, last read position, collections. (e.g., via separate .meta JSON files or a small database file like Hive/SQLite).
    *   FR5.5: Conflict resolution strategy (e.g., last write wins, or prompt user if supported by API).
    *   FR5.6: Manual sync trigger and option for automatic background sync (leveraging Dart's async capabilities and Flutter's background execution features where applicable).
*   **FR6: Plugin System (Dart-based)**
    *   FR6.1: Define clear Dart APIs/interfaces for plugins to interact with the core application (e.g., access book content, modify UI, respond to events).
    *   FR6.2: Mechanism for discovering, loading, enabling/disabling plugins (initially, plugins might be compiled in as dependencies; dynamic loading to be explored based on Flutter's capabilities).
    *   FR6.3: Basic permission model for plugins (e.g., network access, file system access, managed through Dart code and potentially platform channels for finer control).
*   **FR7: Settings**
    *   FR7.1: General application settings (e.g., default theme, language).
    *   FR7.2: Sync account management.
    *   FR7.3: Plugin management interface.

**6. Non-Functional Requirements**
*   **NFR1: Performance:**
    *   NFR1.1: App launch time < 3 seconds on modern hardware.
    *   NFR1.2: Book opening time < 2 seconds for average-sized EPUBs.
    *   NFR1.3: Smooth page turning and scrolling (target 60fps+ via Flutter's rendering engine).
*   **NFR2: Usability:**
    *   NFR2.1: Intuitive and easy-to-navigate user interface, built with Flutter's flexible widget system.
    *   NFR2.2: Adherence to platform-specific UI/UX conventions where appropriate (using Cupertino widgets on iOS, Material on Android/Desktop, or custom consistent UI), while maintaining a consistent brand identity.
    *   NFR2.3: Basic accessibility features (leveraging Flutter's built-in accessibility support).
*   **NFR3: Stability:** The application should be robust and minimize crashes. Dart's strong typing and Flutter's tooling will aid this.
*   **NFR4: Security:** Secure handling of cloud service credentials (e.g., using system keychain via packages like `flutter_secure_storage`, OAuth tokens not stored insecurely).
*   **NFR5: Open Source:**
    *   NFR5.1: Codebase hosted on a public repository (e.g., GitHub, GitLab).
    *   NFR5.2: Clear open-source license (e.g., GPLv3).
    *   NFR5.3: Contribution guidelines.
    *   **NFR5.4: Technology Stack: Primarily Flutter and Dart, facilitating easier contributions from the Flutter community.**

**7. Design Considerations (High-Level)**
*   Clean, minimalist UI that prioritizes the reading content, achievable with Flutter's custom rendering capabilities.
*   Consistent design language across all platforms, with adaptations for native feel where necessary.
*   Visual indicators for sync status.

**8. Success Metrics**
*   Number of downloads and active users.
*   Community engagement (e.g., GitHub stars, forks, issues, pull requests).
*   Positive user reviews and feedback.
*   Number of third-party Dart-based plugins developed (long-term).
*   Successful cross-device syncing reported by users.

**9. Future Considerations / Out of Scope for V1 Core**
*   Advanced annotation features (highlighting, notes).
*   Built-in ebook store integrations.
*   Social reading features (sharing progress, recommendations).
*   Support for more niche ebook formats.
*   The two specific plugins (AI Audiobook, Crypto Storage) are separate but rely on this core and will also be developed using Dart/Flutter.