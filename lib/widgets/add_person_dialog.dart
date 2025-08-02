import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../models/person.dart';
import '../utils/emoji_utils.dart';
import '../utils/constants.dart';

class AddPersonDialog extends StatefulWidget {
  final List<Person> existingPeople;

  const AddPersonDialog({super.key, required this.existingPeople});

  @override
  State<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends State<AddPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedAvatar = '👤';
  bool _showEmojiPicker = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _isNameTaken(String name) {
    return widget.existingPeople.any(
      (person) => person.name.toLowerCase() == name.toLowerCase().trim(),
    );
  }

  void _selectAvatar(String emoji) {
    setState(() {
      _selectedAvatar = emoji;
      _showEmojiPicker = false;
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final person = Person(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        avatar: _selectedAvatar,
      );
      Navigator.of(context).pop(person);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
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
                    const Text('👥', style: AppTextStyles.emojiStyle),
                    const SizedBox(width: AppConstants.smallPadding),
                    Text('เพิ่มคนใหม่', style: AppTextStyles.subHeaderStyle),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.largePadding),

                // Existing people list
                if (widget.existingPeople.isNotEmpty) ...[
                  Text('เลือกจากคนที่มีอยู่แล้ว (${widget.existingPeople.length} คน)', 
                       style: AppTextStyles.captionStyle),
                  const SizedBox(height: AppConstants.smallPadding),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.existingPeople.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final person = widget.existingPeople[index];
                        return ListTile(
                          dense: true,
                          leading: Text(
                            person.avatar,
                            style: const TextStyle(fontSize: 20),
                          ),
                          title: Text(
                            person.name,
                            style: AppTextStyles.bodyStyle,
                          ),
                          trailing: Icon(
                            Icons.add_circle_outline,
                            color: AppConstants.primaryColor,
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.defaultPadding,
                            vertical: 4,
                          ),
                          onTap: () {
                            Navigator.of(context).pop(person);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Center(
                    child: Text(
                      'หรือเพิ่มคนใหม่',
                      style: AppTextStyles.captionStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                ],

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar selection
                      Text('เลือกรูปแทนตัว', style: AppTextStyles.captionStyle),
                      const SizedBox(height: AppConstants.smallPadding),

                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Selected avatar display
                            Expanded(
                              child: GestureDetector(
                                onTap: _toggleEmojiPicker,
                                child: Container(
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(
                                        AppConstants.borderRadius,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedAvatar,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'กดเพื่อเปลี่ยน',
                                        style: AppTextStyles.captionStyle.copyWith(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Quick emoji selection
                            Container(
                              width: 200,
                              padding: const EdgeInsets.all(
                                AppConstants.smallPadding,
                              ),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: EmojiUtils.getPersonEmojis()
                                    .take(12)
                                    .map((emoji) {
                                      final isSelected =
                                          emoji == _selectedAvatar;
                                      return GestureDetector(
                                        onTap: () => _selectAvatar(emoji),
                                        child: Container(
                                          width: 36,
                                          height: 36,
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
                                                    color: AppConstants
                                                        .primaryColor,
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
                          ],
                        ),
                      ),

                      const SizedBox(height: AppConstants.defaultPadding),

                      // Name input
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อ',
                          hintText: 'ใส่ชื่อของคน',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: AppConstants.maxPersonNameLength,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณาใส่ชื่อ';
                          }
                          if (value.trim().length < 2) {
                            return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
                          }
                          if (_isNameTaken(value)) {
                            return 'ชื่อนี้มีอยู่แล้ว';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submitForm(),
                      ),
                    ],
                  ),
                ),

                // Emoji picker
                if (_showEmojiPicker) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                    ),
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        _selectAvatar(emoji.emoji);
                      },
                      config: Config(
                        height: 250,
                        checkPlatformCompatibility: true,
                        emojiViewConfig: EmojiViewConfig(
                          backgroundColor: Colors.transparent,
                          columns: 7,
                          emojiSizeMax: 24,
                        ),
                        skinToneConfig: const SkinToneConfig(),
                        categoryViewConfig: const CategoryViewConfig(),
                        bottomActionBarConfig: const BottomActionBarConfig(
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
                        onPressed: _submitForm,
                        child: const Text('เพิ่ม'),
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
