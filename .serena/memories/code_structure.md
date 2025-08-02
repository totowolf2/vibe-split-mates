# Code Structure

## Directory Structure
```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── bill.dart               # Bill model with calculations
│   ├── person.dart             # Person model
│   └── item.dart               # Item model
├── providers/                   # State management
│   └── bill_provider.dart      # Main provider for bill and person management
├── services/                    # Business logic services
│   ├── export_service.dart     # Image export functionality
│   ├── ocr_service.dart        # OCR text recognition
│   ├── persistence_service.dart # SharedPreferences storage
│   └── image_service.dart      # Image processing
├── utils/                       # Utilities and constants
│   ├── constants.dart          # App constants, colors, text
│   └── emoji_utils.dart        # Emoji handling utilities
└── widgets/                     # UI components
    ├── add_item_dialog.dart    # Add item dialog
    ├── item_card.dart          # Item display card
    ├── ocr_results_dialog.dart # OCR results display
    ├── person_avatar.dart      # Person avatar widget
    ├── add_person_dialog.dart  # Add person dialog
    └── global_discount_dialog.dart # Global discount dialog
```

## Key Classes
- **BillProvider**: Main state manager for bills and people
- **Person**: Model for people with id, name, avatar, imagePath
- **Bill**: Model for bills with items, people, and calculations
- **Item**: Model for items with price, discount, owners
- **PersistenceService**: Handles SharedPreferences storage for people