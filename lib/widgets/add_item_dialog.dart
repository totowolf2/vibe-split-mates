import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../models/item.dart';
import '../models/person.dart';
import '../utils/emoji_utils.dart';
import '../utils/constants.dart';
import 'person_avatar.dart';

class AddItemDialog extends StatefulWidget {
  final List<Person> availablePeople;
  final Item? existingItem; // For editing existing items

  const AddItemDialog({
    super.key, 
    required this.availablePeople,
    this.existingItem,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedEmoji = '🍽️';
  List<String> _selectedOwnerIds = [];
  bool _showEmojiPicker = false;
  bool _userSelectedEmoji = false; // Track if user manually selected emoji

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    
    // If editing existing item, populate the fields
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _nameController.text = item.name;
      _priceController.text = item.price.toString();
      _selectedEmoji = item.emoji;
      _selectedOwnerIds = List.from(item.ownerIds);
      _userSelectedEmoji = true; // Assume existing emoji was user-selected
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final name = _nameController.text.trim();
    
    // For editing items: if name changes significantly, reset to auto-generate
    if (widget.existingItem != null && 
        name.isNotEmpty && 
        name != widget.existingItem!.name) {
      // Name changed during editing - reset to auto-generate
      final autoEmoji = EmojiUtils.generateEmoji(name);
      setState(() {
        _selectedEmoji = autoEmoji;
        _userSelectedEmoji = false; // Reset user selection flag
      });
      return;
    }
    
    // For new items: auto-generate if user hasn't manually selected
    if (name.isNotEmpty && !_userSelectedEmoji) {
      final autoEmoji = EmojiUtils.generateEmoji(name);
      if (autoEmoji != _selectedEmoji && !_showEmojiPicker) {
        setState(() {
          _selectedEmoji = autoEmoji;
        });
      }
    }
  }

  void _selectEmoji(String emoji) {
    setState(() {
      _selectedEmoji = emoji;
      _showEmojiPicker = false;
      _userSelectedEmoji = true; // Mark that user manually selected emoji
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _toggleOwner(String personId) {
    setState(() {
      if (_selectedOwnerIds.contains(personId)) {
        _selectedOwnerIds.remove(personId);
      } else {
        _selectedOwnerIds.add(personId);
      }
    });
  }

  void _selectAllOwners() {
    setState(() {
      _selectedOwnerIds = widget.availablePeople.map((p) => p.id).toList();
    });
  }

  void _clearAllOwners() {
    setState(() {
      _selectedOwnerIds.clear();
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final item = Item(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        emoji: _selectedEmoji,
        ownerIds: List<String>.from(_selectedOwnerIds), // ตอนนี้ยอมให้เป็น empty list ได้
      );

      Navigator.of(context).pop(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const Text('➕', style: AppTextStyles.emojiStyle),
                    const SizedBox(width: AppConstants.smallPadding),
                    Text(
                      widget.existingItem != null ? 'แก้ไขรายการ' : 'เพิ่มรายการใหม่',
                      style: AppTextStyles.subHeaderStyle,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.largePadding),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Item name and emoji
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Emoji picker
                          GestureDetector(
                            onTap: _toggleEmojiPicker,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius,
                                ),
                                color: Colors.grey.shade50,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _selectedEmoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  Text(
                                    'แตะ',
                                    style: AppTextStyles.captionStyle.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: AppConstants.defaultPadding),

                          // Item name
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'ชื่อรายการ',
                                hintText: 'เช่น พิซซ่า, น้ำอัดลม',
                                border: OutlineInputBorder(),
                              ),
                              maxLength: AppConstants.maxItemNameLength,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'กรุณาใส่ชื่อรายการ';
                                }
                                if (value.trim().length < 2) {
                                  return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.defaultPadding),

                      // Price input
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'ราคา (${AppConstants.currencySymbol})',
                          hintText: '0.00',
                          border: const OutlineInputBorder(),
                          prefixText: AppConstants.currencySymbol,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณาใส่ราคา';
                          }
                          final price = double.tryParse(value);
                          if (price == null) {
                            return 'กรุณาใส่ตัวเลขที่ถูกต้อง';
                          }
                          if (price < AppConstants.minItemPrice) {
                            return 'ราคาต้องมากกว่า ${AppConstants.currencySymbol}${AppConstants.minItemPrice}';
                          }
                          if (price > AppConstants.maxItemPrice) {
                            return 'ราคาต้องน้อยกว่า ${AppConstants.currencySymbol}${AppConstants.maxItemPrice}';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submitForm(),
                      ),

                      const SizedBox(height: AppConstants.largePadding),

                      // Owner selection
                      Text(
                        'ใครจะแชร์ค่าใช้จ่าย? (เลือกได้ทีหลัง)',
                        style: AppTextStyles.captionStyle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),

                      if (widget.availablePeople.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(
                            AppConstants.defaultPadding,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange.shade300),
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadius,
                            ),
                            color: Colors.orange.shade50,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: AppConstants.smallPadding),
                              Expanded(
                                child: Text(
                                  'ยังไม่มีคนในบิล กรุณาเพิ่มคนก่อน',
                                  style: AppTextStyles.captionStyle.copyWith(
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Quick selection buttons
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _selectAllOwners,
                              icon: const Icon(Icons.group, size: 16),
                              label: const Text('ทุกคน'),
                            ),
                            TextButton.icon(
                              onPressed: _clearAllOwners,
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('ล้าง'),
                            ),
                          ],
                        ),

                        // People selection chips
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: AppConstants.smallPadding,
                              runSpacing: AppConstants.smallPadding,
                              children: widget.availablePeople.map((person) {
                                final isSelected = _selectedOwnerIds.contains(
                                  person.id,
                                );
                                return FilterChip(
                                  avatar: PersonAvatar(person: person, size: 28, showBorder: false),
                                  label: Text(person.name),
                                  selected: isSelected,
                                  onSelected: (_) => _toggleOwner(person.id),
                                  selectedColor: AppConstants.primaryColor
                                      .withValues(alpha: 0.3),
                                  checkmarkColor: AppConstants.primaryColor,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Emoji picker
                if (_showEmojiPicker) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Quick emoji selection
                        Container(
                          height: 60,
                          padding: const EdgeInsets.all(
                            AppConstants.smallPadding,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: EmojiUtils.getAllFoodEmojis()
                                  .take(20)
                                  .map((emoji) {
                                    final isSelected = emoji == _selectedEmoji;
                                    return GestureDetector(
                                      onTap: () => _selectEmoji(emoji),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppConstants.primaryColor
                                                    .withValues(alpha: 0.2)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: isSelected
                                              ? Border.all(
                                                  color:
                                                      AppConstants.primaryColor,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            emoji,
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        ),

                        const Divider(height: 1),

                        // Full emoji picker
                        Expanded(
                          child: EmojiPicker(
                            onEmojiSelected: (category, emoji) {
                              _selectEmoji(emoji.emoji);
                            },
                            config: Config(
                              height: 140,
                              checkPlatformCompatibility: true,
                              emojiViewConfig: EmojiViewConfig(
                                backgroundColor: Colors.transparent,
                                columns: 8,
                                emojiSizeMax: 20,
                              ),
                              skinToneConfig: const SkinToneConfig(),
                              categoryViewConfig: const CategoryViewConfig(),
                              bottomActionBarConfig:
                                  const BottomActionBarConfig(
                                    backgroundColor: Colors.transparent,
                                    buttonColor: Colors.transparent,
                                  ),
                              searchViewConfig: const SearchViewConfig(
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppConstants.largePadding),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('ยกเลิก'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitForm, // ตอนนี้เพิ่มได้เสมอ ไม่ต้องมีคนก่อน
                        child: Text(widget.existingItem != null ? 'บันทึก' : 'เพิ่ม'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
