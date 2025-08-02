# Tech Stack and Dependencies

## Framework
- **Flutter**: Cross-platform mobile app framework
- **Dart**: Programming language (SDK ^3.8.1)

## Architecture
- **Provider Pattern**: State management using provider package
- **Model-View-Provider**: Separation of concerns
- **Singleton Services**: For persistence and other services

## Key Dependencies
### State Management
- `provider: ^6.1.2` - State management

### OCR and Image Processing
- `google_mlkit_text_recognition: ^0.14.0` - Text recognition from images
- `image_cropper: ^8.0.2` - Image cropping functionality
- `image_picker: ^1.1.2` - Camera/gallery access

### UI Components
- `emoji_picker_flutter: ^3.0.0` - Emoji selection
- `google_fonts: ^6.2.1` - Custom fonts

### Storage and Permissions
- `image_gallery_saver: ^2.0.3` - Save images to gallery
- `path_provider: ^2.1.4` - File system paths
- `permission_handler: ^11.3.1` - System permissions
- `shared_preferences: ^2.3.2` - Local data persistence

### Development
- `flutter_lints: ^5.0.0` - Linting rules
- `flutter_test` - Testing framework