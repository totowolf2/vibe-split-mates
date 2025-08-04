import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/bill_provider.dart';
import 'utils/constants.dart';
import 'widgets/add_person_dialog.dart';
import 'widgets/edit_person_dialog.dart';
import 'widgets/add_item_dialog.dart';
import 'widgets/item_card.dart';
import 'widgets/person_avatar.dart';
import 'widgets/animated_logo.dart';

import 'widgets/global_discount_dialog.dart';
import 'widgets/ocr_results_dialog.dart';
import 'services/export_service.dart';
import 'services/image_service.dart';
import 'services/ocr_service.dart';
import 'models/person.dart';
import 'models/item.dart';
import 'models/bill.dart';

void main() {
  runApp(const SplitMatesApp());
}

class SplitMatesApp extends StatelessWidget {
  const SplitMatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BillProvider(),
      child: MaterialApp(
        title: AppConstants.appName,
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(
                seedColor: AppConstants.primaryColor,
                surface: AppConstants.backgroundColor,
                brightness: Brightness.light,
              ).copyWith(
                primary: AppConstants.primaryColor,
                surface: AppConstants.backgroundColor,
                onSurface: AppConstants.primaryText,
                onSurfaceVariant: AppConstants.secondaryText,
                outline: AppConstants.dividerColor,
              ),
          textTheme: GoogleFonts.notoSansThaiTextTheme(),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: AppConstants.backgroundColor,
            elevation: 0,
          ),
        ),
        home: const SplitMatesHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class SplitMatesHomePage extends StatefulWidget {
  const SplitMatesHomePage({super.key});

  @override
  State<SplitMatesHomePage> createState() => _SplitMatesHomePageState();
}

class _SplitMatesHomePageState extends State<SplitMatesHomePage> {
  final GlobalKey _summaryKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  double _toolbarHeight = 130.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        toolbarHeight: _toolbarHeight,
        leading: Padding(
          padding: const EdgeInsets.all(1.0),
          child: AnimatedLogo(
            scrollController: _scrollController,
            onHeightChanged: (height) {
              setState(() {
                _toolbarHeight = height;
              });
            },
          ),
        ),
        leadingWidth: 380,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Items section
            const _ItemsSection(),

            const SizedBox(height: AppConstants.largePadding),

            // People section
            const _PeopleSection(),

            const SizedBox(height: AppConstants.largePadding),

            // Global discount section
            const _GlobalDiscountSection(),

            const SizedBox(height: AppConstants.largePadding),

            // Summary section with RepaintBoundary for export
            RepaintBoundary(key: _summaryKey, child: const _SummarySection()),

            const SizedBox(height: AppConstants.largePadding),

            // Bottom buttons
            _BottomButtonsSection(summaryKey: _summaryKey),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActionBottomSheet(context),
        backgroundColor: AppConstants.accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showActionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('เลือกการดำเนินการ', style: AppTextStyles.subHeaderStyle),
            const SizedBox(height: 20),
            _BottomSheetOption(
              icon: '📷',
              title: 'เพิ่มจากสลิป',
              subtitle: 'สแกนใบเสร็จเพื่อเพิ่มรายการ',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _scanReceipt(context);
              },
            ),
            _BottomSheetOption(
              icon: '➕',
              title: 'เพิ่มของ',
              subtitle: 'เพิ่มรายการใหม่ด้วยตนเอง',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showAddItemDialog(context);
              },
            ),
            _BottomSheetOption(
              icon: '👥',
              title: 'เพิ่มคน',
              subtitle: 'เพิ่มคนเข้าร่วมแชร์ค่าใช้จ่าย',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showAddPersonDialog(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddPersonDialog(BuildContext context) async {
    final billProvider = context.read<BillProvider>();

    final person = await showDialog<Person>(
      context: context,
      builder: (context) =>
          AddPersonDialog(existingPeople: billProvider.savedPeople),
    );

    if (person != null) {
      // Check if this is an existing person or a new one
      final isExistingPerson = billProvider.savedPeople.any(
        (p) => p.id == person.id,
      );

      bool success = true;
      if (!isExistingPerson) {
        // Only try to save if it's a new person
        success = await billProvider.addSavedPerson(person);
      }

      if (success) {
        // Add to current bill (works for both new and existing people)
        billProvider.addPersonToBill(person);

        if (context.mounted) {
          AppHelpers.showSnackBar(
            context,
            isExistingPerson
                ? 'เพิ่ม ${person.name} เข้าร่วมแล้ว'
                : 'เพิ่ม ${person.name} เรียบร้อย',
            backgroundColor: Colors.green,
          );
        }
      } else {
        if (context.mounted) {
          AppHelpers.showSnackBar(
            context,
            'ไม่สามารถเพิ่มคนได้ อาจมีชื่อซ้ำ',
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  void _scanReceipt(BuildContext context) async {
    final billProvider = context.read<BillProvider>();

    try {
      // Show image source selection
      final imageSource = await ImageService.showImageSourceDialog(context);
      if (imageSource == null) return;

      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังประมวลผลรูปภาพ...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Show crop instruction
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        // Show brief tip as snackbar instead of blocking dialog
        AppHelpers.showSnackBar(
          context,
          '💡 วาดกรอบรอบส่วนของใบเสร็จ เพื่อสแกนได้แม่นยำ',
          duration: Duration(seconds: 3),
        );

        // Show loading again
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('กำลังเตรียมรูปภาพ...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }

      // Check if context is still mounted before proceeding
      if (!context.mounted) return;

      // Pick and crop image
      final imageFile = await ImageService.pickAndCropImage(
        source: imageSource,
        context: context,
      );

      if (imageFile == null) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      // Validate image
      if (!ImageService.validateImageFile(imageFile)) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading
          AppHelpers.showSnackBar(
            context,
            'รูปภาพไม่ถูกต้องหรือไฟล์ใหญ่เกินไป',
            backgroundColor: Colors.red,
          );
        }
        return;
      }

      // Extract text using OCR
      final extractedText = await OCRService.extractTextFromImage(
        imageFile.path,
      );

      if (extractedText == null || extractedText.trim().isEmpty) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading
          AppHelpers.showSnackBar(
            context,
            'ไม่พบข้อความในรูปภาพ กรุณาลองใหม่',
            backgroundColor: Colors.red,
          );
        }
        // Clean up image file
        await ImageService.cleanupTempFiles([imageFile.path]);
        return;
      }

      // Parse items from text
      final detectedItems = OCRService.parseItemsFromText(extractedText);

      // Validate results
      final validationResult = OCRService.validateOCRResults(
        detectedItems,
        rawText: extractedText,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show results dialog
      if (context.mounted) {
        final selectedItems = await showDialog<List<Item>>(
          context: context,
          builder: (context) => OCRResultsDialog(
            detectedItems: validationResult['items'],
            availablePeople: billProvider.people,
            confidence: validationResult['confidence'],
            issues: validationResult['issues'],
            suggestions: validationResult['suggestions'],
          ),
        );

        if (selectedItems != null && selectedItems.isNotEmpty) {
          billProvider.addItems(selectedItems);

          if (context.mounted) {
            AppHelpers.showSnackBar(
              context,
              'เพิ่ม ${selectedItems.length} รายการจากการสแกนเรียบร้อย',
              backgroundColor: Colors.green,
            );
          }
        }
      }

      // Clean up image file
      await ImageService.cleanupTempFiles([imageFile.path]);
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        AppHelpers.showSnackBar(
          context,
          'เกิดข้อผิดพลาด: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _showAddItemDialog(BuildContext context) async {
    final billProvider = context.read<BillProvider>();

    final item = await showDialog<Item>(
      context: context,
      builder: (context) => AddItemDialog(availablePeople: billProvider.people),
    );

    if (item != null) {
      billProvider.addItem(item);

      if (context.mounted) {
        AppHelpers.showSnackBar(
          context,
          'เพิ่ม ${item.name} เรียบร้อย',
          backgroundColor: Colors.green,
        );
      }
    }
  }
}

class _BottomSheetOption extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BottomSheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppConstants.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyStyle.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: AppTextStyles.captionStyle),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.itemsLabel,
                  style: AppTextStyles.subHeaderStyle,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                if (billProvider.items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.largePadding),
                    child: Text(
                      AppConstants.noItemsMessage,
                      style: AppTextStyles.captionStyle,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Column(
                    children: [
                      // Hint text for gestures
                      if (billProvider.items.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                            AppConstants.smallPadding,
                          ),
                          margin: const EdgeInsets.only(
                            bottom: AppConstants.smallPadding,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadius,
                            ),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            AppConstants.addItemHint,
                            style: AppTextStyles.captionStyle.copyWith(
                              color: Colors.blue.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Items list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: billProvider.items.length,
                        itemBuilder: (context, index) {
                          final item = billProvider.items[index];
                          return ItemCard(
                            item: item,
                            people: billProvider.people,
                            showHintAnimation:
                                billProvider.isFirstItem && index == 0,
                            onDelete: () {
                              billProvider.removeItem(item.id);
                              AppHelpers.showSnackBar(
                                context,
                                'ลบ ${item.name} เรียบร้อย',
                                backgroundColor: Colors.red.shade600,
                              );
                            },
                            onDiscount: (discount) {
                              billProvider.addDiscountToItem(item.id, discount);
                              if (discount > 0) {
                                AppHelpers.showSnackBar(
                                  context,
                                  'ใส่ส่วนลด ${AppConstants.currencySymbol}${discount.toStringAsFixed(2)} ให้ ${item.name}',
                                  backgroundColor: Colors.green.shade600,
                                );
                              } else {
                                AppHelpers.showSnackBar(
                                  context,
                                  'ลบส่วนลดของ ${item.name} เรียบร้อย',
                                );
                              }
                            },
                            onOwnersChanged: (ownerIds) {
                              final updatedItem = item.copyWith(
                                ownerIds: ownerIds,
                              );
                              billProvider.updateItem(item.id, updatedItem);
                              AppHelpers.showSnackBar(
                                context,
                                ownerIds.isEmpty
                                    ? 'ลบคนที่แชร์ ${item.name} เรียบร้อย'
                                    : 'อัปเดตคนที่แชร์ ${item.name} เรียบร้อย',
                                backgroundColor: Colors.blue.shade600,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PeopleSection extends StatelessWidget {
  const _PeopleSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.participantsLabel,
                  style: AppTextStyles.subHeaderStyle,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                if (billProvider.savedPeople.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.largePadding),
                    child: Text(
                      AppConstants.noPeopleMessage,
                      style: AppTextStyles.captionStyle,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // All saved people
                      Row(
                        children: [
                          Text(
                            'คนที่บันทึกไว้:',
                            style: AppTextStyles.captionStyle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          // Select All / Clear buttons
                          if (billProvider.savedPeople.isNotEmpty) ...[
                            TextButton(
                              onPressed: () {
                                // Add all saved people to bill
                                for (final person in billProvider.savedPeople) {
                                  if (!billProvider.people.any((p) => p.id == person.id)) {
                                    billProvider.addPersonToBill(person);
                                  }
                                }
                                AppHelpers.showSnackBar(
                                  context,
                                  'เพิ่มทุกคนเข้าบิลแล้ว',
                                  backgroundColor: Colors.green,
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppConstants.primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'เลือกทั้งหมด',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Remove all people from bill
                                final peopleToRemove = List<String>.from(
                                  billProvider.people.map((p) => p.id),
                                );
                                for (final personId in peopleToRemove) {
                                  billProvider.removePersonFromBill(personId);
                                }
                                AppHelpers.showSnackBar(
                                  context,
                                  'ลบทุกคนออกจากบิลแล้ว',
                                  backgroundColor: Colors.orange,
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade600,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'ล้าง',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Wrap(
                        spacing: AppConstants.smallPadding,
                        runSpacing: AppConstants.smallPadding,
                        children: billProvider.savedPeople.map((person) {
                          final isInBill = billProvider.people.any(
                            (p) => p.id == person.id,
                          );
                          return GestureDetector(
                            onTap: () {
                              if (isInBill) {
                                billProvider.removePersonFromBill(person.id);
                                AppHelpers.showSnackBar(
                                  context,
                                  'ลบ ${person.name} ออกจากบิล',
                                );
                              } else {
                                billProvider.addPersonToBill(person);
                                AppHelpers.showSnackBar(
                                  context,
                                  'เพิ่ม ${person.name} เข้าบิล',
                                );
                              }
                            },
                            onLongPress: () {
                              _showPersonOptions(context, person, billProvider);
                            },
                            child: FilterChip(
                              avatar: PersonAvatar(
                                person: person,
                                size: 32,
                                showBorder: false,
                              ),
                              label: Text(person.name),
                              selected: isInBill,
                              onSelected: (selected) {
                                if (selected) {
                                  billProvider.addPersonToBill(person);
                                  AppHelpers.showSnackBar(
                                    context,
                                    'เพิ่ม ${person.name} เข้าบิล',
                                  );
                                } else {
                                  billProvider.removePersonFromBill(person.id);
                                  AppHelpers.showSnackBar(
                                    context,
                                    'ลบ ${person.name} ออกจากบิล',
                                  );
                                }
                              },
                              selectedColor: AppConstants.primaryColor
                                  .withValues(alpha: 0.3),
                              checkmarkColor: AppConstants.primaryColor,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        'แตะเพื่อเพิ่ม/ลบจากบิล • กดค้างเพื่อแก้ไขหรือลบ',
                        style: AppTextStyles.captionStyle.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPersonOptions(
    BuildContext context,
    Person person,
    BillProvider billProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: PersonAvatar(person: person, size: 40),
              title: Text(person.name, style: AppTextStyles.subHeaderStyle),
              subtitle: Text('ตัวเลือก', style: AppTextStyles.captionStyle),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('แก้ไขข้อมูล'),
              onTap: () async {
                Navigator.pop(context);
                await _editPerson(context, person, billProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('ลบ', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _deletePerson(context, person, billProvider);
              },
            ),
            const SizedBox(height: AppConstants.smallPadding),
          ],
        ),
      ),
    );
  }

  Future<void> _editPerson(
    BuildContext context,
    Person person,
    BillProvider billProvider,
  ) async {
    final updatedPerson = await showDialog<Person>(
      context: context,
      builder: (context) => EditPersonDialog(
        person: person,
        existingPeople: billProvider.savedPeople,
      ),
    );

    if (updatedPerson != null) {
      final success = await billProvider.updateSavedPerson(updatedPerson);
      if (context.mounted) {
        AppHelpers.showSnackBar(
          context,
          success
              ? 'แก้ไขข้อมูล ${updatedPerson.name} เรียบร้อย'
              : 'ไม่สามารถแก้ไขข้อมูลได้ อาจมีชื่อซ้ำ',
          backgroundColor: success ? Colors.green : Colors.red,
        );
      }
    }
  }

  Future<void> _deletePerson(
    BuildContext context,
    Person person,
    BillProvider billProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบข้อมูลส่วนตัว'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PersonAvatar(person: person, size: 60),
            const SizedBox(height: AppConstants.defaultPadding),
            Text('ต้องการลบ "${person.name}" หรือไม่?'),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'การลบจะส่งผลต่อรายการที่ ${person.name} เป็นคนแชร์',
              style: AppTextStyles.captionStyle.copyWith(
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await billProvider.removeSavedPerson(person.id);
      if (context.mounted) {
        AppHelpers.showSnackBar(
          context,
          success ? 'ลบ ${person.name} เรียบร้อย' : 'ไม่สามารถลบได้',
          backgroundColor: success ? Colors.green : Colors.red,
        );
      }
    }
  }
}

class _GlobalDiscountSection extends StatelessWidget {
  const _GlobalDiscountSection();

  void _showGlobalDiscountDialog(BuildContext context) async {
    final billProvider = context.read<BillProvider>();

    if (billProvider.subtotal <= 0) {
      AppHelpers.showSnackBar(
        context,
        'กรุณาเพิ่มรายการก่อนเพื่อใส่ส่วนลด',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => GlobalDiscountDialog(
        currentDiscount: billProvider.currentBill?.globalDiscount,
        billSubtotal: billProvider.subtotal,
      ),
    );

    if (result != null) {
      if (result == 'remove') {
        billProvider.removeGlobalDiscount();
        if (context.mounted) {
          AppHelpers.showSnackBar(context, 'ลบส่วนลดรวมเรียบร้อย');
        }
      } else if (result is BillDiscount) {
        billProvider.setGlobalDiscount(result);
        if (context.mounted) {
          AppHelpers.showSnackBar(
            context,
            'ใส่ส่วนลดรวม ${AppConstants.currencySymbol}${billProvider.globalDiscountAmount.toStringAsFixed(2)} เรียบร้อย',
            backgroundColor: Colors.green,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        return Card(
          child: InkWell(
            onTap: () => _showGlobalDiscountDialog(context),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppConstants.globalDiscountLabel,
                        style: AppTextStyles.subHeaderStyle,
                      ),
                      const Spacer(),
                      Icon(Icons.edit, size: 16, color: Colors.grey.shade600),
                    ],
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  if (billProvider.currentBill?.globalDiscount == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: Colors.blue.shade600,
                            size: 32,
                          ),
                          const SizedBox(height: AppConstants.smallPadding),
                          Text(
                            'กดเพื่อเพิ่มส่วนลดรวม',
                            style: AppTextStyles.captionStyle.copyWith(
                              color: Colors.blue.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ส่วนลดรวม:',
                                style: AppTextStyles.captionStyle.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${AppConstants.currencySymbol}${billProvider.globalDiscountAmount.toStringAsFixed(2)}',
                                style: AppTextStyles.priceStyle.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.smallPadding),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'ประเภท: ${billProvider.currentBill!.globalDiscount!.type == DiscountType.amount ? "จำนวนเงิน" : "เปอร์เซ็นต์"}',
                                  style: AppTextStyles.captionStyle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'วิธีแบ่ง: ${billProvider.currentBill!.globalDiscount!.splitType == DiscountSplitType.equal ? "เท่ากัน" : "ตามสัดส่วน"}',
                                  style: AppTextStyles.captionStyle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        final shares = billProvider.personShares;
        final discounts = billProvider.personDiscounts;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.summaryLabel,
                  style: AppTextStyles.subHeaderStyle,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                if (billProvider.people.isEmpty || billProvider.items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.largePadding),
                    child: Text(
                      'เพิ่มรายการและคนเพื่อดูสรุป',
                      style: AppTextStyles.captionStyle,
                      textAlign: TextAlign.center,
                    ),
                  )
                else ...[
                  // Bill totals summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ยอดรวมก่อนลด:',
                              style: AppTextStyles.bodyStyle,
                            ),
                            Text(
                              '${billProvider.subtotal.toStringAsFixed(2)} ${AppConstants.currencyText}',
                              style: AppTextStyles.bodyStyle,
                            ),
                          ],
                        ),
                        if (billProvider.globalDiscountAmount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ส่วนลดรวม:',
                                style: AppTextStyles.captionStyle.copyWith(
                                  color: Colors.red.shade600,
                                ),
                              ),
                              Text(
                                '-${billProvider.globalDiscountAmount.toStringAsFixed(2)} ${AppConstants.currencyText}',
                                style: AppTextStyles.captionStyle.copyWith(
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ยอดสุทธิ:',
                              style: AppTextStyles.priceStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${billProvider.total.toStringAsFixed(2)} ${AppConstants.currencyText}',
                              style: AppTextStyles.priceStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.defaultPadding),

                  // Per-person breakdown
                  Text(
                    'แยกตามคน:',
                    style: AppTextStyles.captionStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),

                  ...billProvider.people.map((person) {
                    final amountToPay = shares[person.id] ?? 0.0;
                    final discountReceived = discounts[person.id] ?? 0.0;
                    final itemEmojis =
                        billProvider.personItemEmojis[person.id] ?? [];

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              PersonAvatar(
                                person: person,
                                size: 36,
                                emojiAsIcon: true,
                              ),
                              const SizedBox(width: AppConstants.smallPadding),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person.name,
                                      style: AppTextStyles.bodyStyle.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (itemEmojis.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        itemEmojis
                                            .take(8)
                                            .join(' '), // Show max 8 emojis
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                '${amountToPay.toStringAsFixed(2)} ${AppConstants.currencyText}',
                                style: AppTextStyles.priceStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          if (discountReceived > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const SizedBox(width: 32), // Space for emoji
                                Expanded(
                                  child: Text(
                                    '${AppConstants.discountReceivedLabel} ${discountReceived.toStringAsFixed(2)} ${AppConstants.currencyText}',
                                    style: AppTextStyles.captionStyle.copyWith(
                                      color: Colors.orange.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomButtonsSection extends StatelessWidget {
  final GlobalKey summaryKey;

  const _BottomButtonsSection({required this.summaryKey});

  Future<void> _exportImage(BuildContext context) async {
    final billProvider = context.read<BillProvider>();

    // Check if there's anything to export
    if (billProvider.people.isEmpty || billProvider.items.isEmpty) {
      AppHelpers.showSnackBar(
        context,
        'ไม่มีข้อมูลเพื่อส่งออก กรุณาเพิ่มรายการและคนก่อน',
        backgroundColor: Colors.orange,
      );
      return;
    }

    // Check if platform supports export
    if (!ExportService.isSupported) {
      AppHelpers.showSnackBar(
        context,
        'ไม่รองรับการส่งออกรูปภาพในอุปกรณ์นี้',
        backgroundColor: Colors.red,
      );
      return;
    }

    // Validate widget is ready for export
    if (!ExportService.validateForExport(summaryKey)) {
      // Add a small delay and try again
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (!ExportService.validateForExport(summaryKey)) {
        if (context.mounted) {
          AppHelpers.showSnackBar(
            context,
            'ไม่สามารถส่งออกได้ กรุณาลองใหม่',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }
    }

    // Show loading
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('กำลังสร้างรูปภาพ...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Generate filename
      final filename = ExportService.generateFileName();

      // Calculate optimal pixel ratio
      final pixelRatio = context.mounted ? 
          ExportService.getOptimalPixelRatio(context) : 2.0;

      // Export the image
      final success = await ExportService.exportWidgetAsImage(
        repaintBoundaryKey: summaryKey,
        filename: filename,
        pixelRatio: pixelRatio,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        if (context.mounted) {
          AppHelpers.showSnackBar(
            context,
            'บันทึกรูปภาพเรียบร้อย',
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          );
        }
      } else {
        if (context.mounted) {
          AppHelpers.showSnackBar(
            context,
            'ไม่สามารถบันทึกรูปภาพได้',
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'ตั้งค่า',
              onPressed: () => ExportService.openAppSettings(),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        AppHelpers.showSnackBar(
          context,
          'เกิดข้อผิดพลาด: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<BillProvider>().resetBill();
              AppHelpers.showSnackBar(context, 'Reset เรียบร้อย');
            },
            icon: const Text('🔄'),
            label: const Text('Reset'),
          ),
        ),
        const SizedBox(width: AppConstants.defaultPadding),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () => _exportImage(context),
            icon: const Text('📸'),
            label: const Text('Save Result as Image'),
          ),
        ),
      ],
    );
  }
}
