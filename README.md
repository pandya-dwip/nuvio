# Nuvio ✨

> A premium minimalist notes app designed to help you capture ideas, organize thoughts, and structure your life with elegance and ease. Nuvio is 100% offline — your data never leaves your device.

---

## Features

### 📝 Notes
- Rich block-based note editor (text, checklists, quotes, images, files)
- 50 premium accent colors for per-note theming
- Pin notes to the top for quick access
- Mark notes as favorites
- Duplicate notes with one tap
- Export individual notes as `.json` files
- Calendar view — see notes by the day they were last edited

### 📁 Folders
- Create nested folders with custom names and 50 color choices
- Navigate into folders and create notes directly inside them
- Edit and delete folders (notes are unlinked, not deleted)
- Pin folders for fast access

### ⭐ Favorites & Pinned Views
- Dedicated **Favorites** screen: view all starred notes at a glance
- Dedicated **Pinned Notes** screen: access all pinned notes instantly
- Both accessible from the home screen "View All" buttons

### 🎨 Appearance
- Full **dark / light mode** toggle with real-time switching
- 50 premium **accent colors** to personalize the UI
- Adaptive splash screen that respects the saved theme on startup

### 🗂 Data Management
- **Export Data** — save a full JSON backup of all notes and folders via the system file picker
- **Import Data** — load a previously exported `.json` file and merge with existing data
- **Create Backup Now** — instantly saves a timestamped backup to the app's local documents folder
- **Automated Backup Schedule** — choose Daily, Weekly, Monthly, or Never; backups run silently on app startup when due
- **Backup History** — browse, restore, or delete previous automated backups

### ℹ️ About
- Version, build number, and developer info in a clean bottom sheet

---

## Architecture

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State management | Riverpod (`StateNotifier`) |
| Persistence | SharedPreferences (notes & folders), file system (backups) |
| File I/O | `file_picker` (import/export), `path_provider` (local docs) |
| Fonts | Google Fonts – Plus Jakarta Sans, Great Vibes |
| Theme | Custom `AppTheme` with dark/light variants + 50 premium colors |

### Directory Structure
```
lib/
├── main.dart
├── models/
│   ├── note_model.dart        # Note, NoteBlock, ChecklistItem
│   └── folder_model.dart      # Folder
├── providers/
│   ├── notes_provider.dart    # CRUD + import/merge
│   ├── folders_provider.dart  # CRUD + import/merge
│   └── theme_provider.dart    # Dark/light + accent color
├── screens/
│   ├── splash_screen.dart     # Animated splash (theme-aware)
│   ├── home_screen.dart       # Main 5-tab shell (Calendar, Notes, Home, Folders, Settings)
│   ├── note_detail_screen.dart
│   ├── pinned_notes_screen.dart
│   ├── favorites_screen.dart
│   ├── accent_color_screen.dart
│   └── data_management_screen.dart
├── widgets/
│   ├── note_card.dart         # Note card with long-press options
│   └── empty_state.dart
└── themes/
    └── app_theme.dart         # AppTheme, PremiumColor, 50 colors
```

---

## Getting Started

### Prerequisites
- Flutter SDK `^3.11.5`
- Dart SDK `^3.11.5`

### Run Locally
```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Analyze code
flutter analyze
```

### Build
```bash
flutter build apk --release      # Android
flutter build ios --release       # iOS
flutter build windows --release   # Windows
```

---

## Version

| Field | Value |
|---|---|
| Version | 1.0.0 |
| Build Number | 1 |
| Developer | pandya-dwip |
