# 🎵 Musify - Your Personal Music Universe

[![Flutter](https://img.shields.io/badge/Flutter-3.5.2-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A beautiful, modern music player app built with Flutter that provides an immersive music listening experience with a sleek Material Design 3 interface.

## ✨ Features

### 🎼 Core Features
- **Local Music Library**: Access and play all your local music files
- **Smart Music Organization**: Automatically organizes music by artists, albums, and songs
- **Advanced Search**: Find your favorite tracks quickly with powerful search functionality
- **Favorites System**: Mark and manage your favorite songs with ease
- **Multiple Sorting Options**: Sort by name, artist, recently added, and more

### 🎮 Player Features
- **Background Playback**: Continue listening while using other apps
- **Notification Controls**: Control playback from notification panel
- **Mini Player**: Compact player that stays accessible throughout the app
- **Full-Screen Now Playing**: Immersive full-screen player with album art
- **Playback Controls**: Play, pause, next, previous, and seek functionality

### 🎨 UI/UX Features
- **Material Design 3**: Modern, adaptive design with dynamic color theming
- **Dark/Light Theme**: Automatic theme switching based on system preferences
- **Smooth Animations**: Beautiful transitions and micro-interactions
- **Responsive Design**: Optimized for different screen sizes
- **Gesture Support**: Intuitive touch gestures for navigation

### 🔧 Technical Features
- **GetX State Management**: Efficient state management and dependency injection
- **Audio Service Integration**: Robust background audio handling
- **Permission Handling**: Smart permission requests for file access
- **Cache Management**: Efficient caching for album artwork and metadata
- **Cross-Platform**: Works on Android, iOS, Web, Windows, macOS, and Linux

## 📱 Screenshots

### Main Interface
- **Home Screen**: Clean, organized view with navigation tabs
- **Songs View**: Complete library with search and sort options
- **Artists View**: Browse music by artist with album previews
- **Albums View**: Album grid with cover art and track counts
- **Favorites**: Quick access to your favorite tracks

### Player Interface
- **Mini Player**: Compact bottom player with essential controls
- **Now Playing**: Full-screen immersive player experience
- **Search**: Advanced search with real-time results
- **Splash Screen**: Beautiful animated loading screen

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.5.2 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/musify.git
   cd musify
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 📁 Project Structure

```
lib/
├── controllers/          # GetX controllers for state management
│   ├── favorite_controller.dart
│   ├── home_controller.dart
│   ├── music_controller.dart
│   ├── player_controller.dart
│   └── song_controller.dart
├── model/               # Data models
│   └── song_model.dart
├── routes/              # App routing configuration
│   └── routes.dart
├── services/            # Business logic services
│   ├── album_art_service.dart
│   └── notification_service.dart
├── theme/               # App theming
│   └── theme.dart
├── views/               # UI screens and widgets
│   ├── albums_page.dart
│   ├── all_song.dart
│   ├── artists_page.dart
│   ├── favorites_screen.dart
│   ├── home_screen.dart
│   ├── mini_player_screen.dart
│   ├── now_playing_widget.dart
│   ├── search_page.dart
│   ├── song_list_page.dart
│   └── splash_screen.dart
└── main.dart            # App entry point
```

## 🛠️ Dependencies

### Core Dependencies
- **get**: State management and dependency injection
- **just_audio**: Audio playback engine
- **audio_service**: Background audio service
- **flex_color_scheme**: Material Design 3 theming
- **permission_handler**: Permission management
- **path_provider**: File system access
- **shared_preferences**: Local data storage

### UI Dependencies
- **font_awesome_flutter**: Icon library
- **marquee**: Scrolling text widgets
- **flutter_local_notifications**: Local notifications

### Audio Processing
- **audiotags**: Audio metadata extraction
- **mp3_info**: MP3 file information
- **fftea**: Audio processing utilities

## 🎯 Key Features Explained

### 1. Smart Music Organization
The app automatically scans your device for music files and organizes them into:
- **Songs**: Complete list of all tracks
- **Artists**: Grouped by artist with album previews
- **Albums**: Album-based organization with cover art
- **Favorites**: User-curated favorite tracks

### 2. Advanced Search
- Real-time search across song titles, artists, and albums
- Fuzzy matching for better results
- Search history and suggestions
- Filter by multiple criteria

### 3. Background Playback
- Continues playing when app is minimized
- Notification controls for easy access
- Lock screen controls
- Audio focus management

### 4. Modern UI/UX
- Material Design 3 with dynamic colors
- Smooth animations and transitions
- Gesture-based navigation
- Adaptive layouts for different screen sizes

## 🔧 Configuration

### Permissions
The app requires the following permissions:
- **Storage Access**: To read music files from device
- **Notification**: For playback controls
- **Audio Focus**: For background playback

### Theme Configuration
The app uses FlexColorScheme for theming:
- **Light Theme**: Clean, bright interface
- **Dark Theme**: Eye-friendly dark mode
- **Dynamic Colors**: Adapts to system theme

## 🤝 Contributing

We welcome contributions! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Contributing Guidelines
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team**: For the amazing framework
- **GetX**: For state management solution
- **Just Audio**: For audio playback capabilities
- **Material Design**: For design guidelines
- **Open Source Community**: For various packages and inspiration

## 📞 Support

If you have any questions or need help, please:
- Open an issue on GitHub
- Check the documentation
- Join our community discussions

## 🔮 Roadmap

### Upcoming Features
- [ ] Playlist support
- [ ] Equalizer and audio effects
- [ ] Lyrics display
- [ ] Cloud music integration
- [ ] Cross-device sync
- [ ] Sleep timer
- [ ] Audio visualization
- [ ] Smart recommendations

### Version History
- **v0.1.0**: Initial release with core features
- **v0.2.0**: Enhanced UI and performance improvements
- **v0.3.0**: Added search and favorites functionality

---

**Made with ❤️ using Flutter**

*Your Personal Music Universe*
