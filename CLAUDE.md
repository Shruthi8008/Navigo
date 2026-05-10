# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application called "Navigo" (also referenced as "secmap") - a location-based safety/mapping app with SOS functionality. The app uses OpenStreetMap for mapping and geolocator for GPS positioning.

## Build Commands

```bash
# Flutter commands (run from frontend directory)
cd frontend
flutter pub get          # Install dependencies
flutter analyze          # Run static analysis/linting
flutter build apk        # Build Android APK
flutter build ios        # Build iOS app
flutter run              # Run on connected device/emulator
```

## Architecture

### Frontend (Flutter)

The app uses **Provider** for state management with two main providers:

- `ThemeProvider` - Manages light/dark theme switching using Material 3
- `AuthProvider` - Mock authentication state (currently not connected to any backend)

### Navigation Structure

The app uses a `PageView` with `PageController` for swipe-based navigation between three screens:

1. **SosScreen** (`screens/sos_screen.dart`) - SOS emergency screen
2. **MapScreen** (`screens/map_screen.dart`) - Main map view using flutter_map with OpenStreetMap tiles
3. **ProfileScreen** (`screens/profile_screen.dart`) - User profile with settings navigation

Navigation is controlled via a centered `FloatingActionButton` and a custom `BottomAppBar` with notched design.

### Key Dependencies

- `provider: ^6.1.5+1` - State management
- `flutter_map: ^8.3.0` - OpenStreetMap integration
- `latlong2: ^0.9.1` - Geographic coordinates
- `geolocator: ^14.0.2` - Device location services

### Code Patterns

- Screens are in `lib/screens/` directory
- Providers are in `lib/providers/` directory
- Theme uses Material 3 (`useMaterial3: true`)
- Map tiles served from `tile.openstreetmap.org`
- Default map center: Bangalore (12.9716, 77.5946)

### Android Permissions

The Android manifest requires location permissions (configured in `android/app/src/main/AndroidManifest.xml`).