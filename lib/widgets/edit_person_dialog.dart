import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../models/person.dart';
import '../utils/emoji_utils.dart';
import '../utils/constants.dart';

class EditPersonDialog extends StatefulWidget {
  final Person person;
  final List<Person> existingPeople;

  const EditPersonDialog({
    super.key,
    required this.person,
    required this.existingPeople,
  });

  @override
  State<EditPersonDialog> createState() => _EditPersonDialogState();
}

class _EditPersonDialogState extends State<EditPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedAvatar;
  bool _showEmojiPicker = false;
  File? _selectedImage;
  bool _hasChangedImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person.name);
    _selectedAvatar = widget.person.avatar;
    
    // Load existing image if available
    if (widget.person.hasProfilePicture) {
      _selectedImage = File(widget.person.imagePath!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _isNameTaken(String name) {
    return widget.existingPeople.any(
      (person) => 
          person.id != widget.person.id &&
          person.name.toLowerCase() == name.toLowerCase().trim(),
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
          _hasChangedImage = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเลือกรูปภาพได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _hasChangedImage = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถถ่ายรูปได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _hasChangedImage = true;
    });
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกแหล่งที่มาของรูปภาพ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากแกลเลอรี'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายรูปใหม่'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            if (_selectedImage != null || widget.person.hasProfilePicture)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('ลบรูปภาพ', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _saveImageToProfile(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profilesDir = Directory('${appDir.path}/profiles');
      if (!await profilesDir.exists()) {
        await profilesDir.create(recursive: true);
      }
      
      final fileName = '${widget.person.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${profilesDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  Future<void> _deleteOldImage() async {
    if (widget.person.hasProfilePicture) {
      try {
        final oldImage = File(widget.person.imagePath!);
        if (await oldImage.exists()) {
          await oldImage.delete();
        }
      } catch (e) {
        debugPrint('Error deleting old image: $e');
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String? imagePath = widget.person.imagePath;
      
      // Handle image changes
      if (_hasChangedImage) {
        // Delete old image if exists
        await _deleteOldImage();
        
        if (_selectedImage != null) {
          // Save new image
          imagePath = await _saveImageToProfile(_selectedImage!);
          if (imagePath == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ไม่สามารถบันทึกรูปภาพได้'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } else {
          // Remove image path
          imagePath = null;
        }
      }

      final updatedPerson = widget.person.copyWith(
        name: _nameController.text.trim(),
        avatar: _selectedAvatar,
        imagePath: imagePath,
      );

      if (mounted) {
        Navigator.of(context).pop(updatedPerson);
      }
    } catch (e) {
      if (mounted) {
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
                    const Text('✏️', style: AppTextStyles.emojiStyle),
                    const SizedBox(width: AppConstants.smallPadding),
                    Text(
                      'แก้ไขข้อมูลส่วนตัว',
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
                      // Profile picture section
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: _selectedImage != null
                                          ? Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey.shade100,
                                                  child: Center(
                                                    child: Text(
                                                      _selectedAvatar,
                                                      style: const TextStyle(fontSize: 40),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey.shade100,
                                              child: Center(
                                                child: Text(
                                                  _selectedAvatar,
                                                  style: const TextStyle(fontSize: 40),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            Text(
                              'แตะเพื่อเปลี่ยนรูปภาพ',
                              style: AppTextStyles.captionStyle,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppConstants.largePadding),

                      // Name and avatar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar picker
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
                                    _selectedAvatar,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  Text(
                                    'Icon',
                                    style: AppTextStyles.captionStyle.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: AppConstants.defaultPadding),

                          // Name input
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'ชื่อ',
                                hintText: 'เช่น สมชาย, แอน',
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
                                if (_isNameTaken(value.trim())) {
                                  return 'ชื่อนี้มีคนใช้แล้ว';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
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
                              children: EmojiUtils.getPersonEmojis()
                                  .take(20)
                                  .map((emoji) {
                                    final isSelected = emoji == _selectedAvatar;
                                    return GestureDetector(
                                      onTap: () => _selectAvatar(emoji),
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
                                          borderRadius: BorderRadius.circular(6),
                                          border: isSelected
                                              ? Border.all(
                                                  color: AppConstants.primaryColor,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            emoji,
                                            style: const TextStyle(fontSize: 20),
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
                              _selectAvatar(emoji.emoji);
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
                        onPressed: _submitForm,
                        child: const Text('บันทึก'),
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