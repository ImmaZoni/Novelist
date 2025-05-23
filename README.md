> ⚠️ **Early Development Warning**  
> Novelist is in a **very early stage of development**. Many features are incomplete or experimental, and cross-platform support is still being tested. If you're trying it out, expect rough edges, and feel free to contribute!

# Novelist

**Novelist** is an open-source, cross-platform eReader application built with Flutter and Dart. It aims to provide a clean, customizable, and powerful reading experience, robust library management, and a flexible plugin architecture for future extensibility.

## 🚀 Features

- **Cross-Platform:** Runs on Windows, macOS, Linux, iOS, and Android.
- **EPUB Support:** Import, parse, and read EPUB 2/3 books with metadata extraction, cover art, and basic chapter navigation.
- **Customizable Reading Experience:** Adjust font size, and (soon) font family, line spacing, margins, and themes (light/dark/sepia).
- **Library Management:** Import books, view metadata, organize your collection, and remember your last read position.
- **Table of Contents Navigation:** Jump to chapters using the book's TOC.
- **Open Source & Extensible:** Built for community contribution and future plugin support.

## 📦 Roadmap & Status

| Feature                        | Status                |
|--------------------------------|-----------------------|
| Desktop & Mobile Support       | ✅ Implemented        |
| EPUB Parsing & Rendering       | ✅ Partially Implemented |
| PDF/MOBI/TXT/HTML Support      | ⏳ To Do              |
| Cover Art Extraction           | ✅ Partially Implemented |
| Library Grid/List View         | ✅/⏳                 |
| Sorting, Filtering, Search     | ⏳ To Do              |
| Bookmarks                      | ⏳ To Do              |
| Reading Progress Display       | ⏳ To Do              |
| Full-Screen Reading            | ⏳ To Do              |
| Sync Across Devices            | ⏳ To Do              |
| Plugin System                  | ⏳ To Do              |
| Settings (Theme, Language)     | ⏳ To Do              |

See [Docs/Development/PRD.md](Docs/Development/PRD.md) for the full product requirements and progress.


## 📱 Device & Platform Testing

| Platform      | Status             | Notes                                                                 |
|---------------|--------------------|-----------------------------------------------------------------------|
| **Android**   | ✅ Tested           | Actively tested and verified.     |
| **iOS**       | ⚠️ Untested         | Expected to work; testing needed. |
| **Windows**   | ⚠️ Untested         | Expected to work; testing needed. |
| **macOS**     | ⚠️ Untested         | Expected to work; testing needed. |
| **Linux**     | ⚠️ Untested         | Expected to work; testing needed. |

> 💡 **Help Wanted:** If you test Novelist on a platform not yet verified, please open an issue or PR with your findings! Community feedback helps us improve cross-platform support.

## 🛠️ Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart (comes with Flutter)
- A supported platform (Windows, macOS, Linux, iOS, Android)

### Installation
> Note: We are still very early in development, this is mostly meant for testing if your interested in the project. 

1. **Clone the repository:**
   ```sh
   git clone https://github.com/yourusername/novelist.git
   cd novelist
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Run the app:**
   ```sh
   flutter run
   ```
   *(Choose your target device/platform as needed.)*


## 📚 Usage

- **Import Books:** Add EPUB files to your library from local storage.
- **Read:** Open a book, adjust font size, and navigate chapters via the TOC.
- **Library Management:** View your collection, see cover art, and track your reading progress.

## 🤝 Contributing

We welcome contributions! Please see our [contribution guidelines](CONTRIBUTING.md) (coming soon) and open issues or pull requests for features, bug fixes, or ideas.

## 📝 License

This project is licensed under the GPLv3 License. See the [LICENSE](LICENSE) file for details.

## 📢 Acknowledgements

- Built with [Flutter](https://flutter.dev/) and [Dart](https://dart.dev/).
- EPUB parsing powered by [`epubx`](https://pub.dev/packages/epubx).

## 💡 Future Plans

- Advanced annotation and note-taking
- Cloud sync (Google Drive, Dropbox, iCloud)
- Plugin marketplace
- Support for more ebook formats
- Exciting official plugins to bring e-reading to the next level.

**Novelist** is made for readers, by readers.  
Happy reading! 📖
