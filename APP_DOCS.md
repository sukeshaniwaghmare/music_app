# WS Music App — Documentation

**Developer:** Waghmare Sukeshani  
**Version:** 1.0.0+1  
**Framework:** Flutter (Dart)

---

## APIs Used

### 1. iTunes Search API (English Songs)
- **Base URL:** `https://itunes.apple.com/search`
- **Usage:** Fetch English songs with pagination
- **Params:** `term`, `offset`, `limit`, `entity=song`
- **Free:** Yes, no API key required
- **Preview:** 30-second `.m4a` audio preview

### 2. iTunes India API (Hindi / Marathi Songs)
- **Base URL:** `https://itunes.apple.com/search`
- **Usage:** Fetch Hindi/Marathi songs using `country=IN`
- **Queries used:**
  - `ajay atul`, `aadhe rahude`, `arijit singh`
  - `shreya ghoshal marathi`, `sonu nigam hindi`
  - `kumar sanu`, `lata mangeshkar`, `kishore kumar`
  - `udit narayan`, `marathi superhit`, `bollywood hits`
- **Free:** Yes, no API key required

---

## Packages Used

| Package | Version | Purpose |
|---|---|---|
| `flutter_bloc` | ^8.1.5 | State management (BLoC pattern) |
| `http` | ^1.2.1 | API HTTP requests |
| `audioplayers` | ^6.1.0 | Audio playback |
| `connectivity_plus` | ^6.0.3 | Network connectivity check |
| `just_audio` | ^0.9.40 | (installed, not used) |
| `flutter_launcher_icons` | ^0.14.3 | App icon generation |

---

## Project Structure

```
lib/
├── main.dart                        # App entry point
│
├── models/
│   └── track.dart                   # Track model (fromJson, fromSaavn)
│
├── blocs/
│   ├── library/
│   │   ├── library_bloc.dart        # Library state management
│   │   ├── library_event.dart       # Library events
│   │   └── library_state.dart       # Library state
│   └── track_detail/
│       ├── track_detail_bloc.dart   # Track detail state
│       ├── track_detail_event.dart
│       └── track_detail_state.dart
│
├── repositories/
│   └── track_repository.dart        # iTunes API paging logic
│
├── services/
│   ├── api_service.dart             # iTunes API calls
│   ├── saavn_api_service.dart       # iTunes India API (Hindi/Marathi)
│   ├── audio_player_service.dart    # Singleton audio player
│   ├── favorites_service.dart       # Favorites management
│   ├── recently_played_service.dart # Recently played history
│   └── connectivity_service.dart    # Internet check
│
├── screens/
│   ├── library_screen.dart          # Home screen (English + Hindi/Marathi tabs)
│   ├── track_detail_screen.dart     # Now Playing screen
│   ├── favorites_screen.dart        # Favorites list
│   ├── queue_screen.dart            # Playback queue
│   ├── recently_played_screen.dart  # Recently played songs
│   └── settings_screen.dart         # App settings
│
└── widgets/
    ├── mini_player.dart             # Bottom mini player bar
    ├── track_tile.dart              # Song list item
    └── section_header.dart         # Section header widget
```

---

## Features

### Home Screen
- Two tabs — **English** (iTunes) and **Hindi / Marathi** (iTunes India)
- Infinite scroll pagination
- Search songs/artists
- Three dots menu: Favorites, Queue, Recently Played, Settings

### Song Row — Three Dots Options
- ▶️ **Play Now** — open TrackDetailScreen and play
- 🎵 **Add to Queue** — add after current song
- ❤️ **Add / Remove Favorites**

### Now Playing Screen
- Album art, title, artist
- Progress slider with time
- Play / Pause, Next, Previous, Shuffle, Repeat controls
- 🎨 **Color Theme** — 5 background themes (Dark, Blue, Purple, Green, Red)
- Favorite toggle

### Mini Player
- Visible on home screen when song is playing
- Shows album art, title, artist
- Repeat, Play/Pause, Next buttons
- Tap to open Now Playing screen

### Queue Screen
- Shows current + upcoming songs
- Reorder by drag
- Remove individual songs (×)
- Clear entire queue

### Favorites Screen
- All favorited songs listed
- Tap to play

### Recently Played Screen
- Last 50 played songs
- Tap to play again

### Settings Screen
- Audio Quality, Equalizer info
- App version, Developer info

---

## Audio Player (Singleton)

`AudioPlayerService` is a singleton `ChangeNotifier` using `audioplayers` package.

| Feature | Detail |
|---|---|
| Singleton | `AudioPlayerService.instance` |
| Background audio | Continues when screen changes |
| Repeat modes | Off / Repeat All / Repeat One |
| Shuffle | Random next track |
| Queue | Insert track after current |
| Auto next | Plays next on track complete |

---

## State Management

| BLoC | Responsibility |
|---|---|
| `LibraryBloc` | Fetch, paginate, search English songs |
| `TrackDetailBloc` | Fetch individual track details |

Hindi/Marathi songs are managed directly in `LibraryScreen` state (no BLoC).

---

## Android Permissions

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

---

## How to Run

```bash
flutter pub get
flutter run
```

---

## App Icon
- Source: `assets/Image Jun 9, 2026, 10_14_45 PM.png`
- Generated using `flutter_launcher_icons`
- Android: ✅ | iOS: ❌ | Windows: ✅
