# UniFlow - Student App

A comprehensive Flutter application designed for university students, focusing on offline file management, PDF viewing, note-taking, and a modern dashboard.

## Features

### 🗂️ File Management System
- Create folders and subfolders
- Import PDFs, images, and documents from local storage
- Rename, move, and delete files/folders
- List and grid view toggle
- All files stored locally using Hive database

### 📄 PDF Viewer
- Integrated PDF viewer with scroll and zoom functionality
- Text highlighting and annotation capabilities
- Annotations stored locally and linked to file ID
- Page navigation and zoom controls

### 📝 Notes Section
- Rich-text note editor with formatting options
- Create, edit, delete, and auto-save functionality
- Pin important notes
- Tag system for organization
- Notes stored locally in Hive database

### 🧭 Dashboard
- Recently opened files and notes display
- Storage usage summary
- Motivational quotes and study tips
- Quick action FABs for creating new files and notes

### ⚙️ Settings
- Light/Dark theme toggle
- Customizable color schemes
- Data management options
- Auto-save configuration
- App information and version details

## Design System

### Colors
- Primary: #3D5AFE (Indigo Blue)
- Secondary: #00BFA5 (Teal)
- Light Background: #F8F9FB
- Dark Background: #121212

### Typography
- Headings: Poppins/Roboto Slab (18-22sp, bold)
- Body: Inter/Roboto (14-16sp, medium)
- Quotes: Italic with accent colors

### Components
- Material 3 design system
- Rounded corners (20px radius)
- Card-based layouts
- Floating Action Buttons
- Bottom navigation bar

## Architecture

### Tech Stack
- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Provider
- **Local Storage**: Hive
- **PDF Viewing**: flutter_pdfview
- **File Picker**: file_picker
- **Rich Text Editor**: flutter_quill

### Project Structure
```
lib/
├── models/          # Data models with Hive annotations
├── services/        # Business logic and data access
├── providers/       # State management
├── screens/         # UI screens
├── widgets/         # Reusable UI components
├── utils/           # Utility functions and themes
└── main.dart        # App entry point
```

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd uniflow
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate Hive adapters:
```bash
flutter packages pub run build_runner build
```

4. Run the app:
```bash
flutter run
```

## Offline-First Design

UniFlow is designed to work completely offline:
- All data is stored locally using Hive database
- No internet connection required
- Files are imported and stored on device
- Annotations and notes persist locally
- Settings and preferences stored locally

## Features Implementation Status

### ✅ Completed
- [x] Project setup with Flutter and dependencies
- [x] Material 3 theme with light/dark mode
- [x] File management system with Hive storage
- [x] PDF viewer with basic functionality
- [x] Rich-text note editor with auto-save
- [x] Dashboard with recent items and storage summary
- [x] Settings page with theme and data management
- [x] Bottom navigation and screen routing
- [x] Responsive UI components

### 🔄 In Progress
- [ ] PDF annotation system (basic structure in place)
- [ ] File sharing functionality
- [ ] Advanced search and filtering
- [ ] Backup and restore functionality

### 📋 Future Enhancements
- [ ] Cloud sync capabilities
- [ ] Advanced PDF annotation tools
- [ ] File encryption
- [ ] Study timer and productivity tracking
- [ ] Collaboration features

## Testing

The app includes comprehensive testing for:
- File import and management
- Note creation and editing
- PDF viewing and navigation
- Theme switching
- Data persistence
- Error handling

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the repository or contact the development team.

---

**UniFlow** - Empowering students with offline-first productivity tools.