# Code Style and Conventions

## Language and Naming
- **Dart/Flutter conventions**: camelCase for variables/methods, PascalCase for classes
- **File naming**: snake_case for file names
- **Private members**: Prefix with underscore (_)

## Code Organization
- **Imports**: Organized with Flutter SDK first, then packages, then local imports
- **Class structure**: Fields, constructors, getters, methods
- **Method organization**: Public methods first, then private methods

## Documentation and Comments
- **Method comments**: Brief descriptions for public methods
- **Debug printing**: Uses `debugPrint()` and `kDebugMode` conditions
- **Error handling**: Try-catch blocks with descriptive error messages

## Specific Patterns
- **Singleton pattern**: Used in PersistenceService
- **Factory constructors**: Used for JSON deserialization
- **copyWith methods**: For immutable model updates
- **JSON serialization**: toJson()/fromJson() methods for data persistence

## UI Conventions
- **Constants**: All colors, text, measurements in AppConstants
- **Text styles**: Centralized in AppTextStyles
- **Thai language**: All user-facing text in Thai
- **Currency**: Thai Baht (฿) symbol used consistently

## State Management
- **Provider pattern**: ChangeNotifier for state management
- **Immutable models**: Models don't modify themselves, use copyWith
- **notifyListeners()**: Called after state changes in provider