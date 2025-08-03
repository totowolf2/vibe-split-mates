import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'SplitMates';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color backgroundColor = Color(0xFFFAFAFA);

  // Discount Colors
  static const Color discountColor = Color(
    0xFFE53935,
  ); // Red for discounted price
  static const Color originalPriceColor = Color(
    0xFF9E9E9E,
  ); // Gray for crossed out price

  // Animation durations
  static const Duration hintAnimationDuration = Duration(milliseconds: 1500);
  static const Duration cardAnimationDuration = Duration(milliseconds: 300);
  static const Duration swipeAnimationDuration = Duration(milliseconds: 200);

  // UI Measurements
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double iconSize = 24.0;
  static const double largeIconSize = 32.0;

  // Swipe thresholds
  static const double swipeThreshold = 0.4; // 40% of card width
  static const double maxSwipeDistance = 100.0;

  // Currency formatting
  static const String currencySymbol = '฿'; // Thai Baht (for internal use)
  static const String currencyText = 'บาท'; // Thai text for display
  static const String currencyCode = 'THB';

  // Shared Preferences Keys
  static const String savedPeopleKey = 'saved_people';
  static const String appSettingsKey = 'app_settings';

  // OCR Settings
  static const double maxImageSize =
      1024.0; // Max width/height for OCR processing
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];

  // Validation Rules
  static const double minItemPrice = 0.01;
  static const double maxItemPrice = 999999.99;
  static const double minDiscountAmount = 0.01;
  static const double maxDiscountPercentage = 100.0;
  static const int maxItemNameLength = 50;
  static const int maxPersonNameLength = 30;

  // UI Text
  static const String addItemHint = 'เลื่อนขวาเพื่อลด หรือซ้ายเพื่อลบ';
  static const String noItemsMessage = 'ยังไม่มีรายการ กดเพิ่มรายการด้านบน';
  static const String noPeopleMessage = 'กรุณาเพิ่มคนก่อนเพื่อแชร์ค่าใช้จ่าย';

  // Error Messages
  static const String genericError = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
  static const String permissionDeniedError = 'ไม่ได้รับอนุญาตเข้าถึง';
  static const String ocrProcessingError = 'ไม่สามารถอ่านข้อความจากรูปได้';
  static const String imageProcessingError = 'ไม่สามารถประมวลผลรูปภาพได้';
  static const String exportError = 'ไม่สามารถบันทึกรูปภาพได้';

  // Success Messages
  static const String itemAddedSuccess = 'เพิ่มรายการเรียบร้อย';
  static const String itemDeletedSuccess = 'ลบรายการเรียบร้อย';
  static const String discountAppliedSuccess = 'ใส่ส่วนลดเรียบร้อย';
  static const String personAddedSuccess = 'เพิ่มคนเรียบร้อย';
  static const String exportSuccess = 'บันทึกรูปภาพเรียบร้อย';

  // Thai Text Labels
  static const String addFromReceiptLabel = '📷 เพิ่มจากสลิป';
  static const String addItemLabel = '➕ เพิ่มของ';
  static const String addPersonLabel = '👥 เพิ่มคน';
  static const String itemsLabel = '📋 รายการของ';
  static const String participantsLabel = '👥 ผู้เข้าร่วม';
  static const String globalDiscountLabel = '💸 ส่วนลดรวมทั้งบิล';
  static const String summaryLabel = '📊 สรุปผล';
  static const String resetLabel = '🔄 Reset';
  static const String saveImageLabel = '📸 Save Result as Image';
  static const String totalLabel = 'รวม';
  static const String discountLabel = 'ลด';
  static const String amountLabel = 'จำนวน';
  static const String percentageLabel = 'เปอร์เซ็นต์';
  static const String equalSplitLabel = 'หารเท่ากัน';
  static const String proportionalSplitLabel = 'หารตามยอดจ่าย';
  static const String mustPayLabel = 'ต้องจ่าย';
  static const String discountReceivedLabel = 'ลดไป';
}

class AppTextStyles {
  static const TextStyle headerStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle subHeaderStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    color: Colors.black54,
  );

  static const TextStyle priceStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle discountedPriceStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppConstants.discountColor,
  );

  static const TextStyle originalPriceStyle = TextStyle(
    fontSize: 12,
    color: AppConstants.originalPriceColor,
    decoration: TextDecoration.lineThrough,
  );

  static const TextStyle emojiStyle = TextStyle(fontSize: 24);

  static const TextStyle buttonStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
