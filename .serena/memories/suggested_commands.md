# Suggested Development Commands

## Flutter Development Commands

### Setup and Dependencies
```bash
# Install dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

### Development and Testing
```bash
# Run the app in debug mode
flutter run

# Run on specific device
flutter run -d <device_id>

# Hot reload (during development)
# Press 'r' in terminal or use IDE hot reload

# Hot restart (during development)
# Press 'R' in terminal or use IDE hot restart
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
flutter format .

# Run tests
flutter test
```

### Build Commands
```bash
# Build for Android (APK)
flutter build apk

# Build for Android (App Bundle)
flutter build appbundle

# Build for iOS
flutter build ios

# Clean build artifacts
flutter clean
```

### Device and Emulator Management
```bash
# List available devices
flutter devices

# Create Android emulator
flutter emulators --create

# Launch emulator
flutter emulators --launch <emulator_id>
```

## Git Commands
```bash
# Standard git workflow
git status
git add .
git commit -m "message"
git push
```

## System Commands (Linux)
- Standard Linux commands: `ls`, `cd`, `grep`, `find`, `cat`, etc.
- File management: `mkdir`, `rm`, `cp`, `mv`
- Permissions: `chmod`, `chown` (if needed for Flutter/Android development)