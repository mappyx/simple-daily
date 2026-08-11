# SimpleDaily

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20Windows-blue" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

A specialized, privacy-focused productivity application built with Flutter. Beautifull designed with a dark aesthetic, SimpleDaily combines notes, project management, and focus tools into one stealthy desktop package.

## ✨ Features

- **📝 Advanced Notes**: Markdown support (Bold, Italic, Lists) with live preview.
- **📋 Kanban Board**: Manage projects with drag-and-drop tasks, Tags, and Priority levels (Low, Medium, High).
- **⏱️ Pomodoro Timer**: Integrated focus timer in the title bar to boost productivity.
- **🔄 One-Click Updates**: 
    - **Linux**: Downloads `.deb` and auto-installs via `pkexec`.
    - **Windows**: Downloads and launches `.exe` installer.
- **☁️ Git Sync**: Built-in structure to backup your data to a private Git repository.
- **🔍 Global Search**: Instantly find any note or task from the title bar.
- **👁️ Glassmorphism UI**: Modern, translucent sidebar for a premium desktop feel.
- **🔔 Daily Reminders**: Local notifications to keep you on track.
- **⬇️ System Tray**: Minimized app stays out of your way in the system tray.

## 🚀 Installation & Updates

### Automatic Updates (CI/CD)
This project uses **GitHub Actions** to automatically build and release new versions.
Simply push a tag (e.g., `v1.0.0`) to the repository, and a Release with `.deb` and `.zip` artifacts will be created automatically. The app's built-in update checker will detect this and offer a one-click update.

### Manual Build

#### Linux
Prerequisites:
```bash
./setup_linux.sh
```

Build:
```bash
./build_linux.sh
```
Artifacts:
- **AppImage** (Universal for Arch, Fedora, Ubuntu, Debian, etc.): `build/appimage/SimpleDaily-1.0.0-x86_64.AppImage`
- **Debian / Ubuntu package**: `build/deb/simple-daily-1.0.0-amd64.deb`

#### Windows
Run the batch script:
```bat
build_windows.bat
```
Artifact: `build/windows/runner/Release/simple_daily.exe` (or zip)

## 🛠️ Development

1. **Setup**:
   ```bash
   flutter pub get
   ```

2. **Run**:
   ```bash
   flutter run
   ```

3. **Test**:
   ```bash
   flutter test
   ```

## 📂 Project Structure

- `lib/models`: Data models (Task, Note, Project).
- `lib/screens`: UI Screens (Home, Notes, Kanban, Settings).
- `lib/services`:
    - `JsonDataService`: Local JSON persistence.
    - `UpdateService`: Cross-platform update logic.
    - `GitSyncService`: Data backup.
    - `PreferencesService`: Settings management.
- `lib/widgets`: Reusable components (PomodoroTimer, etc.).

## 📝 Configuration

Settings are persisted locally. You can configure:
- Daily Reminder Time.
- Launch at Startup behavior.

## License

MIT
