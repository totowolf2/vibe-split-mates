import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _showEmojiPicker = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเลือกรูปได้')),
        );
      }
    }
  }

  Future<String?> _saveImageToAppDirectory(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDir.path}/profiles');
      
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${profileDir.path}/$fileName');
      
      return savedImage.path;
    } catch (e) {
      return null;
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String? imagePath;
      
      if (_selectedImage != null) {
        imagePath = await _saveImageToAppDirectory(_selectedImage!);
      }
      
      final person = Person(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        avatar: _selectedAvatar,
        imagePath: imagePath,
      );
      
      if (mounted) {
        Navigator.of(context).pop(person);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: SingleChildScrollView(
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
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: ClipOval(
                              child: person.hasProfilePicture
                                  ? Image.file(
                                      File(person.imagePath!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade100,
                                          child: Center(
                                            child: Text(
                                              person.avatar,
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.grey.shade100,
                                      child: Center(
                                        child: Text(
                                          person.avatar,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                            ),
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
                      Row(
                        children: [
                          Text('เลือกรูปแทนตัว', style: AppTextStyles.captionStyle),
                          const Spacer(),
                          if (_selectedImage != null)
                            TextButton.icon(
                              onPressed: _removeImage,
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('ลบรูป'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.smallPadding),

                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Selected avatar/image display
                            Expanded(
                              child: GestureDetector(
                                onTap: _selectedImage == null ? _toggleEmojiPicker : null,
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
                                  child: _selectedImage != null
                                      ? Stack(
                                          children: [
                                            Center(
                                              child: Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: AppConstants.primaryColor,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: ClipOval(
                                                  child: Image.file(
                                                    _selectedImage!,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              left: 0,
                                              right: 0,
                                              child: Center(
                                                child: Text(
                                                  'รูปโปรไฟล์',
                                                  style: AppTextStyles.captionStyle.copyWith(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _selectedAvatar,
                                              style: const TextStyle(fontSize: 32),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'กดเพื่อเปลี่ยน',
                                              style: AppTextStyles.captionStyle.copyWith(fontSize: 10),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),

                            // Camera button  
                            Container(
                              width: 70,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border(
                                  left: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: InkWell(
                                onTap: _pickImage,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: AppConstants.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'รูป',
                                      style: AppTextStyles.captionStyle.copyWith(
                                        fontSize: 9,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Quick emoji selection
                            if (_selectedImage == null)
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    AppConstants.smallPadding,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(AppConstants.borderRadius),
                                    ),
                                  ),
                                  child: Wrap(
                                    spacing: 3,
                                    runSpacing: 3,
                                    children: EmojiUtils.getPersonEmojis()
                                        .take(8)
                                        .map((emoji) {
                                          final isSelected = emoji == _selectedAvatar;
                                          return GestureDetector(
                                            onTap: () => _selectAvatar(emoji),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppConstants.primaryColor.withValues(alpha: 0.2)
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(4),
                                                border: isSelected
                                                    ? Border.all(
                                                        color: AppConstants.primaryColor,
                                                        width: 1.5,
                                                      )
                                                    : null,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  emoji,
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
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
                    height: 180,
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
                        height: 180,
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
      ),
    );
  }
}