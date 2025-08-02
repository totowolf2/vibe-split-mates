import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/bill_provider.dart';
import 'utils/constants.dart';
import 'widgets/add_person_dialog.dart';
import 'widgets/add_item_dialog.dart';
import 'widgets/item_card.dart';
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
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppConstants.primaryColor,
            surface: AppConstants.backgroundColor,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🍽️', style: AppTextStyles.emojiStyle),
            const SizedBox(width: 8),
            Text(AppConstants.appName, style: AppTextStyles.headerStyle),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Action buttons section
            const _ActionButtonsSection(),

            const SizedBox(height: AppConstants.largePadding),

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
    );
  }
}

class _ActionButtonsSection extends StatelessWidget {
  const _ActionButtonsSection();

  void _showAddPersonDialog(BuildContext context) async {
    final billProvider = context.read<BillProvider>();

    final person = await showDialog<Person>(
      context: context,
      builder: (context) =>
          AddPersonDialog(existingPeople: billProvider.savedPeople),
    );

    if (person != null) {
      // Check if this is an existing person or a new one
      final isExistingPerson = billProvider.savedPeople.any((p) => p.id == person.id);
      
      bool success = true;
      if (!isExistingPerson) {
        // Only try to save if it's a new person
        success = await billProvider.addSavedPerson(person);
      }
      
      if (success) {
        // Add to current bill (works for both new and existing people)
        billProvider.addPersonToBill(person);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isExistingPerson 
                ? 'เพิ่ม ${person.name} เข้าร่วมแล้ว' 
                : 'เพิ่ม ${person.name} เรียบร้อย'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถเพิ่มคนได้ อาจมีชื่อซ้ำ'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _scanReceipt(BuildContext context) async {
    final billProvider = context.read<BillProvider>();

    if (billProvider.people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเพิ่มคนก่อนเพื่อสแกนใบเสร็จ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

      // Pick and crop image
      final imageFile = await ImageService.pickAndCropImage(
        source: imageSource,
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('รูปภาพไม่ถูกต้องหรือไฟล์ใหญ่เกินไป'),
              backgroundColor: Colors.red,
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่พบข้อความในรูปภาพ กรุณาลองใหม่'),
              backgroundColor: Colors.red,
            ),
          );
        }
        // Clean up image file
        await ImageService.cleanupTempFiles([imageFile.path]);
        return;
      }

      // Parse items from text
      final detectedItems = OCRService.parseItemsFromText(extractedText);

      // Validate results
      final validationResult = OCRService.validateOCRResults(detectedItems, rawText: extractedText);

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'เพิ่ม ${selectedItems.length} รายการจากการสแกนเรียบร้อย',
                ),
                backgroundColor: Colors.green,
              ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddItemDialog(BuildContext context) async {
    final billProvider = context.read<BillProvider>();

    if (billProvider.people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเพิ่มคนก่อนเพื่อแชร์ค่าใช้จ่าย'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final item = await showDialog<Item>(
      context: context,
      builder: (context) => AddItemDialog(availablePeople: billProvider.people),
    );

    if (item != null) {
      billProvider.addItem(item);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เพิ่ม ${item.name} เรียบร้อย'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: '📷',
            label: 'เพิ่มจากสลิป',
            onTap: () => _scanReceipt(context),
          ),
        ),
        const SizedBox(width: AppConstants.smallPadding),
        Expanded(
          child: _ActionButton(
            icon: '➕',
            label: 'เพิ่มของ',
            onTap: () => _showAddItemDialog(context),
          ),
        ),
        const SizedBox(width: AppConstants.smallPadding),
        Expanded(
          child: _ActionButton(
            icon: '👥',
            label: 'เพิ่มคน',
            onTap: () => _showAddPersonDialog(context),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      elevation: AppConstants.cardElevation,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              Text(icon, style: AppTextStyles.emojiStyle),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                label,
                style: AppTextStyles.captionStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('ลบ ${item.name} เรียบร้อย'),
                                  backgroundColor: Colors.red.shade600,
                                ),
                              );
                            },
                            onDiscount: (discount) {
                              billProvider.addDiscountToItem(item.id, discount);
                              if (discount > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'ใส่ส่วนลด ${AppConstants.currencySymbol}${discount.toStringAsFixed(2)} ให้ ${item.name}',
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'ลบส่วนลดของ ${item.name} เรียบร้อย',
                                    ),
                                  ),
                                );
                              }
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
                if (billProvider.people.isEmpty)
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
                      // People in current bill
                      if (billProvider.people.isNotEmpty) ...[
                        Text(
                          'ในบิลนี้:',
                          style: AppTextStyles.captionStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Wrap(
                          spacing: AppConstants.smallPadding,
                          runSpacing: AppConstants.smallPadding,
                          children: billProvider.people.map((person) {
                            return Chip(
                              avatar: Text(person.avatar),
                              label: Text(person.name),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                billProvider.removePersonFromBill(person.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'ลบ ${person.name} ออกจากบิล',
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      // Saved people not in current bill
                      if (billProvider.savedPeople.isNotEmpty) ...[
                        if (billProvider.people.isNotEmpty)
                          const SizedBox(height: AppConstants.defaultPadding),

                        Text(
                          'คนที่บันทึกไว้:',
                          style: AppTextStyles.captionStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Wrap(
                          spacing: AppConstants.smallPadding,
                          runSpacing: AppConstants.smallPadding,
                          children: billProvider.savedPeople
                              .where(
                                (person) => !billProvider.people.any(
                                  (p) => p.id == person.id,
                                ),
                              )
                              .map((person) {
                                return ActionChip(
                                  avatar: Text(person.avatar),
                                  label: Text(person.name),
                                  onPressed: () {
                                    billProvider.addPersonToBill(person);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'เพิ่ม ${person.name} เข้าบิล',
                                        ),
                                      ),
                                    );
                                  },
                                );
                              })
                              .toList(),
                        ),
                      ],
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

class _GlobalDiscountSection extends StatelessWidget {
  const _GlobalDiscountSection();

  void _showGlobalDiscountDialog(BuildContext context) async {
    final billProvider = context.read<BillProvider>();

    if (billProvider.subtotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเพิ่มรายการก่อนเพื่อใส่ส่วนลด'),
          backgroundColor: Colors.orange,
        ),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ลบส่วนลดรวมเรียบร้อย')));
        }
      } else if (result is BillDiscount) {
        billProvider.setGlobalDiscount(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ใส่ส่วนลดรวม ${AppConstants.currencySymbol}${billProvider.globalDiscountAmount.toStringAsFixed(2)} เรียบร้อย',
              ),
              backgroundColor: Colors.green,
            ),
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
                              '${AppConstants.currencySymbol}${billProvider.subtotal.toStringAsFixed(2)}',
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
                                '-${AppConstants.currencySymbol}${billProvider.globalDiscountAmount.toStringAsFixed(2)}',
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
                              '${AppConstants.currencySymbol}${billProvider.total.toStringAsFixed(2)}',
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
                              Text(
                                person.avatar,
                                style: AppTextStyles.emojiStyle,
                              ),
                              const SizedBox(width: AppConstants.smallPadding),
                              Expanded(
                                child: Text(
                                  person.name,
                                  style: AppTextStyles.bodyStyle.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${AppConstants.currencySymbol}${amountToPay.toStringAsFixed(2)}',
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
                                    '${AppConstants.discountReceivedLabel} ${AppConstants.currencySymbol}${discountReceived.toStringAsFixed(2)}',
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

  void _exportImage(BuildContext context) async {
    final billProvider = context.read<BillProvider>();

    // Check if there's anything to export
    if (billProvider.people.isEmpty || billProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีข้อมูลเพื่อส่งออก กรุณาเพิ่มรายการและคนก่อน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if platform supports export
    if (!ExportService.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่รองรับการส่งออกรูปภาพในอุปกรณ์นี้'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate widget is ready for export
    if (!ExportService.validateForExport(summaryKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณารอสักครู่แล้วลองใหม่'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
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
      final pixelRatio = ExportService.getOptimalPixelRatio(context);

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกรูปภาพเรียบร้อย'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ไม่สามารถบันทึกรูปภาพได้'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'ตั้งค่า',
                onPressed: () => ExportService.openAppSettings(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Reset เรียบร้อย')));
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
