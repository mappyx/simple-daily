# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-01-26

### 🚀 New Features
- **Cross-Platform Support**: Full support for Linux and Windows.
- **Markdown Notes**: Rich text editing for notes.
- **Kanban Board**:
    - Priority Levels (Low, Medium, High).
    - Tags support.
    - Drag and drop columns and tasks.
- **Pomodoro Timer**: Minimalist focus timer integrated into the window title bar.
- **Global Search**: Filter notes and tasks instantly.
- **Settings Screen**: Configure daily reminders and startup behavior.
- **Git Sync Service**: Infrastructure for backing up data to Git.
- **Glassmorphism UI**: Translucent sidebar design.

### 🛠️ Technical
- **CI/CD**: GitHub Actions workflow (`release.yml`) for automated multi-platform builds.
- **Auto-Update**:
    - **Linux**: `pkexec` integration for seamless `.deb` installation.
    - **Windows**: Shell execution for installer.
- **Architecture**: Provider-based state management with Service-Repository pattern.
- **Persistence**: JSON-based local storage.

### 📦 Build System
- Added `build_linux.sh` for Debian package generation.
- Added `build_windows.bat` for Windows release building.
- Added `setup_linux.sh` for dependency installation.
