# PRP: SplitMates - Flutter Bill Splitting App

## Overview

SplitMates is a single-page Flutter mobile application designed for easy bill splitting among friends. The app features OCR receipt scanning, gesture-based interactions, emoji-centric design, and automatic calculation of per-person costs including discounts. All functionality is contained within one screen with intuitive swipe gestures and minimal UI.

## Context

### Current State
- Empty Flutter project with no existing code
- Basic project assets: README.md, INIT.md, and app icons
- No Flutter project structure yet initialized
- Target platforms: iOS and Android

### Requirements
Based on README.md analysis, the app must provide:

**Core Features:**
1. **Manual Item Entry**: Add items with name, price, multiple owners, auto-emoji assignment
2. **OCR Receipt Scanning**: Image selection, cropping, OCR text extraction, automatic item parsing
3. **Gesture-Based Item Management**: 
   - Swipe right: Add individual item discount
   - Swipe left: Delete item
4. **People Management**: Add/remove people with names and avatars (emoji/image), persistent storage
5. **Bill-Level Discounts**: Apply discount by amount or percentage, split equally or proportionally
6. **Results Summary**: Per-person totals with discount breakdown
7. **Image Export**: Save summary as PNG to device gallery

**UX Requirements:**
- Single-page application design
- Minimal, flat UI with heavy emoji usage
- Self-evident gesture interactions without tutorials
- Hint animation only on first added item
- Thai language support

### Dependencies
Required Flutter packages as specified in INIT.md:
- `google_mlkit_text_recognition` - OCR text extraction
- `image_cropper` - Image cropping before OCR
- `image_picker` - Gallery/camera image selection
- `emoji_picker_flutter` - Emoji selection interface
- `image_gallery_saver` - Save images to device gallery
- `path_provider` - Device directory access
- `permission_handler` - Camera/storage permissions
- `google_fonts` - Typography
- `shared_preferences` - Local data persistence

## Research Findings

### Codebase Analysis
- No existing Flutter patterns to follow (greenfield project)
- Must establish new conventions for:
  - State management approach
  - File organization structure
  - Widget composition patterns
  - Data model definitions

### External Research

#### OCR Implementation Patterns
**Documentation**: https://pub.dev/packages/google_mlkit_text_recognition
- Requires InputImage creation from file path
- TextRecognizer with script configuration for optimal results
- RecognizedText provides blocks with bounding boxes for parsing
- Must handle platform-specific setup (iOS: pods, Android: dependencies)

**Receipt Parsing Challenge**: OCR may not return text in logical order for receipts
- Need regex patterns to match "item + price" combinations
- Consider using `receipt_recognition` package for specialized receipt parsing
- Implement text cleaning and item extraction algorithms

#### Gesture Detection Patterns
**Documentation**: https://docs.flutter.dev/cookbook/gestures/dismissible
- `Dismissible` widget perfect for swipe-to-delete functionality
- `DismissDirection.startToEnd` for right swipe (discount)
- `DismissDirection.endToStart` for left swipe (delete)
- `confirmDismiss` for conditional actions (discount vs delete)
- Custom background widgets for visual feedback

#### Image Processing Pipeline
**Documentation**: 
- https://pub.dev/packages/image_picker
- https://pub.dev/packages/image_cropper
- https://pub.dev/packages/image_gallery_saver

**Implementation Flow**:
1. ImagePicker.pickImage() -> XFile
2. ImageCropper.cropImage() -> CroppedFile
3. Convert to InputImage for OCR
4. Process and extract text
5. Parse items and populate UI

#### Widget-to-Image Export
**Best Practice**: Use `RepaintBoundary` with `GlobalKey`
```dart
RenderRepaintBoundary boundary = globalKey.currentContext!.findRenderObject();
ui.Image image = await boundary.toImage(pixelRatio: 3.0);
ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
```

#### State Management
**Recommendation**: Provider pattern for medium-complexity app
- Single ChangeNotifier for app state
- Models: Person, Item, Discount, Bill
- Reactive UI updates with Consumer widgets

#### Local Persistence
**Documentation**: https://pub.dev/packages/shared_preferences
```dart
SharedPreferences prefs = await SharedPreferences.getInstance();
// Store people list as JSON string
await prefs.setString('people', jsonEncode(peopleList));
```

### Common Pitfalls to Avoid
1. **OCR Accuracy**: Ensure good lighting and image quality guidance
2. **Permissions**: Handle camera/storage permission failures gracefully
3. **State Management**: Avoid setState() hell with proper architecture
4. **Memory Management**: Dispose controllers and image resources
5. **Emoji Compatibility**: Test emoji rendering across devices
6. **Calculation Precision**: Use proper decimal handling for money calculations

## Implementation Plan

### Pseudocode/Algorithm

```
1. App Initialization
   - Setup Flutter project with dependencies
   - Configure platform permissions
   - Initialize SharedPreferences
   - Load saved people from storage

2. Main UI Structure
   - SingleChildScrollView with sections:
     * Header with action buttons
     * Items list (ListView.builder)
     * People chips display
     * Discount input section
     * Summary calculations
     * Export button

3. Item Management Flow
   - Manual Add: Show dialog -> collect data -> add to state
   - OCR Add: ImagePicker -> ImageCropper -> OCR -> parse -> batch add
   - Item Operations: Wrap in Dismissible -> handle swipe directions

4. Calculation Engine
   - Calculate item totals per person
   - Apply individual item discounts
   - Apply bill-level discount (equal or proportional)
   - Generate per-person summary

5. Persistence Layer
   - Save/load people list on app lifecycle events
   - Maintain current bill state during session

6. Export Functionality
   - Wrap summary in RepaintBoundary
   - Capture as image -> save to gallery
```

### Tasks (in order)

1. **Project Setup and Structure**
   - Initialize Flutter project
   - Add all required dependencies to pubspec.yaml
   - Configure platform-specific permissions (iOS: Info.plist, Android: AndroidManifest.xml)
   - Create folder structure: models/, widgets/, services/, utils/

2. **Data Models Implementation**
   - Create Person model (id, name, avatar)
   - Create Item model (id, name, price, emoji, owners, discount)
   - Create Bill model (items, people, globalDiscount)
   - Implement JSON serialization for persistence

3. **Core State Management**
   - Create BillProvider with ChangeNotifier
   - Implement CRUD operations for items and people
   - Add calculation methods for totals and splits
   - Setup reactive UI updates

4. **Basic UI Structure**
   - Create main scaffold with header
   - Implement items ListView with basic item cards
   - Add floating action buttons for main actions
   - Create people chips display section

5. **People Management Features**
   - Implement add person dialog with name and avatar selection
   - Integrate emoji_picker_flutter for avatar selection
   - Add people persistence with SharedPreferences
   - Implement people removal functionality

6. **Manual Item Entry**
   - Create add item dialog with form validation
   - Implement auto-emoji generation logic (keyword -> emoji mapping)
   - Add multiple owner selection interface
   - Integrate with state management

7. **Gesture-Based Item Interactions**
   - Wrap item cards in Dismissible widgets
   - Implement swipe right -> discount dialog
   - Implement swipe left -> delete confirmation
   - Add visual feedback with background widgets
   - Create hint animation for first item

8. **OCR Receipt Processing**
   - Implement image selection with ImagePicker
   - Add image cropping with ImageCropper
   - Integrate google_mlkit_text_recognition
   - Create receipt text parsing algorithm (item + price regex)
   - Add batch item creation from OCR results

9. **Discount Management**
   - Implement individual item discount dialog
   - Create bill-level discount input section
   - Add discount calculation logic (amount vs percentage)
   - Implement proportional vs equal split options

10. **Summary and Calculations**
    - Create summary display section
    - Implement per-person cost calculations
    - Add discount breakdown display
    - Ensure proper decimal handling for currency

11. **Image Export Functionality**
    - Wrap summary section in RepaintBoundary
    - Implement widget-to-image capture
    - Integrate with image_gallery_saver
    - Add export success feedback

12. **Animations and Polish**
    - Add hint animation for gesture discovery
    - Implement smooth transitions
    - Add loading states for async operations
    - Polish overall UI styling with Google Fonts

13. **Testing and Validation**
    - Test OCR accuracy with various receipt types
    - Validate calculations with different scenarios
    - Test persistence across app restarts
    - Verify permissions work on both platforms

### File Structure

```
splitmates/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── person.dart
│   │   ├── item.dart
│   │   └── bill.dart
│   ├── providers/
│   │   └── bill_provider.dart
│   ├── widgets/
│   │   ├── item_card.dart
│   │   ├── person_chip.dart
│   │   ├── add_item_dialog.dart
│   │   ├── add_person_dialog.dart
│   │   ├── discount_dialog.dart
│   │   └── summary_section.dart
│   ├── services/
│   │   ├── ocr_service.dart
│   │   ├── image_service.dart
│   │   ├── persistence_service.dart
│   │   └── export_service.dart
│   └── utils/
│       ├── emoji_utils.dart
│       ├── calculation_utils.dart
│       └── constants.dart
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml (permissions)
├── ios/
│   └── Runner/
│       └── Info.plist (permissions)
└── pubspec.yaml
```

## Validation Gates

### Syntax/Style Checks
```bash
# Flutter analysis and formatting
flutter analyze
flutter format --set-exit-if-changed .

# Dependencies check
flutter pub deps
```

### Testing Commands
```bash
# Unit tests for models and calculations
flutter test

# Integration tests for OCR and image processing
flutter test integration_test/

# Widget tests for UI components
flutter test test/widget_test.dart
```

### Manual Validation
- [ ] Can add items manually with emoji auto-assignment
- [ ] OCR correctly extracts items from receipt images
- [ ] Swipe gestures work for discounts and deletion
- [ ] People management persists across app restarts
- [ ] Calculations are accurate for various discount scenarios
- [ ] Image export saves summary to gallery successfully
- [ ] Hint animation appears only on first item
- [ ] App works without internet connection
- [ ] All permissions are properly requested and handled
- [ ] UI is responsive and follows flat design principles

## Error Handling

### Common Issues and Solutions

**OCR Processing Failures:**
- Issue: Poor image quality or lighting
- Solution: Add image quality guidance, implement retry mechanism

**Permission Denied:**
- Issue: User denies camera/storage access
- Solution: Show explanatory dialog, graceful degradation to manual entry only

**Calculation Precision:**
- Issue: Floating-point arithmetic errors with currency
- Solution: Use Decimal package or integer-based calculations (cents)

**State Management Bugs:**
- Issue: UI not updating when data changes
- Solution: Ensure proper notifyListeners() calls, use Consumer widgets correctly

**Memory Issues:**
- Issue: Large images causing memory pressure
- Solution: Resize images before processing, dispose resources properly

**Platform-Specific Crashes:**
- Issue: Package compatibility problems
- Solution: Test thoroughly on both platforms, implement platform checks

### Troubleshooting

**Debug Steps:**
1. Check Flutter doctor for environment issues
2. Verify all package versions are compatible
3. Test OCR with high-quality sample images first
4. Use Flutter Inspector to debug widget tree issues
5. Check device logs for native crashes

**Fallback Approaches:**
- Manual item entry if OCR fails
- Basic emoji set if emoji_picker has issues
- Local storage fallback if SharedPreferences fails
- Simple screenshot if RepaintBoundary capture fails

## Quality Checklist

- [ ] All core features implemented and tested
- [ ] Code follows Flutter best practices and conventions
- [ ] All validation gates pass successfully
- [ ] UI matches design requirements (minimal, flat, emoji-centric)
- [ ] Error handling implemented for all async operations
- [ ] Performance is acceptable on mid-range devices
- [ ] Accessibility considerations addressed
- [ ] Memory usage is optimized
- [ ] Platform-specific features work correctly
- [ ] Thai language support verified

## Confidence Score

**9/10** - Very high confidence for one-pass implementation success

**Rationale:**
- All required packages are well-documented with clear implementation patterns
- Flutter provides excellent built-in support for gestures and animations
- OCR and image processing have established implementation patterns
- State management approach is straightforward for app complexity
- Comprehensive research conducted on all technical challenges
- Clear implementation roadmap with specific tasks
- Detailed error handling and troubleshooting guidance provided

**Potential Risk Areas:**
- OCR accuracy with diverse receipt formats (mitigation: thorough testing)
- Complex gesture interactions (mitigation: incremental implementation)

## References

### Package Documentation
- [google_mlkit_text_recognition](https://pub.dev/packages/google_mlkit_text_recognition)
- [image_cropper](https://pub.dev/packages/image_cropper)  
- [image_picker](https://pub.dev/packages/image_picker)
- [emoji_picker_flutter](https://pub.dev/packages/emoji_picker_flutter)
- [image_gallery_saver](https://pub.dev/packages/image_gallery_saver)
- [path_provider](https://pub.dev/packages/path_provider)
- [permission_handler](https://pub.dev/packages/permission_handler)
- [shared_preferences](https://pub.dev/packages/shared_preferences)

### Flutter Documentation
- [Flutter Fundamentals](https://docs.flutter.dev/get-started/fundamentals)
- [Dismissible Widget](https://docs.flutter.dev/cookbook/gestures/dismissible)
- [Animation Tutorial](https://docs.flutter.dev/ui/animations/tutorial)
- [Key-Value Storage](https://docs.flutter.dev/cookbook/persistence/key-value)

### Implementation Examples
- [OCR Receipt Reading Tutorial](https://teresa-wu.medium.com/googles-ml-kit-text-recognition-with-sample-app-of-receipts-reading-7fe6dc68ada3)
- [Flutter Swipe Actions](https://dartling.dev/swipe-actions-flutter-dismissible-widget)
- [Widget to Image Export](https://batcat.medium.com/download-a-widget-as-an-image-to-the-users-device-using-flutter-859118611ce8)
- [SharedPreferences Best Practices](https://blog.logrocket.com/using-sharedpreferences-in-flutter-to-store-data-locally/)