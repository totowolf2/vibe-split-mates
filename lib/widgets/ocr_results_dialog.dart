import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/item.dart';
import '../models/person.dart';
import '../utils/constants.dart';
import '../utils/emoji_utils.dart';

class OCRResultsDialog extends StatefulWidget {
  final List<Item> detectedItems;
  final List<Person> availablePeople;
  final double confidence;
  final List<String> issues;
  final List<String> suggestions;

  const OCRResultsDialog({
    super.key,
    required this.detectedItems,
    required this.availablePeople,
    required this.confidence,
    required this.issues,
    required this.suggestions,
  });

  @override
  State<OCRResultsDialog> createState() => _OCRResultsDialogState();
}

class _OCRResultsDialogState extends State<OCRResultsDialog> {
  late List<Item> _editableItems;
  final Set<int> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _editableItems = widget.detectedItems
        .map((item) => item.copyWith())
        .toList();
    // Select all items by default
    _selectedItems.addAll(
      List.generate(_editableItems.length, (index) => index),
    );
  }

  void _toggleItemSelection(int index) {
    setState(() {
      if (_selectedItems.contains(index)) {
        _selectedItems.remove(index);
      } else {
        _selectedItems.add(index);
      }
    });
  }

  void _editItem(int index) async {
    final item = _editableItems[index];
    final result = await showDialog<Item>(
      context: context,
      builder: (context) =>
          _EditItemDialog(item: item, availablePeople: widget.availablePeople),
    );

    if (result != null) {
      setState(() {
        _editableItems[index] = result;
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _editableItems.removeAt(index);
      _selectedItems.remove(index);
      // Adjust indices for remaining selected items
      final adjustedSelection = <int>{};
      for (final selectedIndex in _selectedItems) {
        if (selectedIndex < index) {
          adjustedSelection.add(selectedIndex);
        } else if (selectedIndex > index) {
          adjustedSelection.add(selectedIndex - 1);
        }
      }
      _selectedItems.clear();
      _selectedItems.addAll(adjustedSelection);
    });
  }

  void _addSelectedItems() {
    final selectedItems = _selectedItems
        .where((index) => index < _editableItems.length)
        .map((index) => _editableItems[index])
        .where((item) => item.ownerIds.isNotEmpty)
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกรายการและใส่คนที่จะแชร์ค่าใช้จ่าย'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).pop(selectedItems);
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getConfidenceText(double confidence) {
    if (confidence >= 0.8) return 'ดีมาก';
    if (confidence >= 0.6) return 'ปานกลาง';
    return 'ต่ำ';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const Text('📷', style: AppTextStyles.emojiStyle),
                    const SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: Text(
                        'ผลการสแกนใบเสร็จ',
                        style: AppTextStyles.subHeaderStyle,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                // Confidence indicator
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(
                      widget.confidence,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    border: Border.all(
                      color: _getConfidenceColor(
                        widget.confidence,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.confidence >= 0.6
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _getConfidenceColor(widget.confidence),
                      ),
                      const SizedBox(width: AppConstants.smallPadding),
                      Text(
                        'ความแม่นยำ: ${_getConfidenceText(widget.confidence)} (${(widget.confidence * 100).toInt()}%)',
                        style: AppTextStyles.captionStyle.copyWith(
                          color: _getConfidenceColor(widget.confidence),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Issues and suggestions
                if (widget.issues.isNotEmpty ||
                    widget.suggestions.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  Container(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.issues.isNotEmpty) ...[
                          Text(
                            'ข้อควรระวัง:',
                            style: AppTextStyles.captionStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          ...widget.issues.map(
                            (issue) => Text(
                              '• $issue',
                              style: AppTextStyles.captionStyle.copyWith(
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                        if (widget.suggestions.isNotEmpty) ...[
                          if (widget.issues.isNotEmpty)
                            const SizedBox(height: AppConstants.smallPadding),
                          Text(
                            'คำแนะนำ:',
                            style: AppTextStyles.captionStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          ...widget.suggestions.map(
                            (suggestion) => Text(
                              '• $suggestion',
                              style: AppTextStyles.captionStyle.copyWith(
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppConstants.largePadding),

                // Items list
                Text(
                  'รายการที่พบ (${_editableItems.length} รายการ):',
                  style: AppTextStyles.captionStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),

                Expanded(
                  child: _editableItems.isEmpty
                      ? Center(
                          child: Text(
                            'ไม่พบรายการใดจากการสแกน',
                            style: AppTextStyles.captionStyle,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _editableItems.length,
                          itemBuilder: (context, index) {
                            final item = _editableItems[index];
                            final isSelected = _selectedItems.contains(index);
                            final hasOwners = item.ownerIds.isNotEmpty;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              color: isSelected
                                  ? AppConstants.primaryColor.withValues(
                                      alpha: 0.1,
                                    )
                                  : null,
                              child: ListTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (_) =>
                                          _toggleItemSelection(index),
                                    ),
                                    Text(
                                      item.emoji,
                                      style: AppTextStyles.emojiStyle,
                                    ),
                                  ],
                                ),
                                title: Text(
                                  item.name,
                                  style: AppTextStyles.bodyStyle,
                                ),
                                subtitle: hasOwners
                                    ? Text(
                                        'แชร์กับ: ${item.ownerIds.map((id) => widget.availablePeople.firstWhere(
                                          (p) => p.id == id,
                                          orElse: () => Person(id: id, name: 'Unknown', avatar: '❓'),
                                        ).name).join(', ')}',
                                        style: AppTextStyles.captionStyle,
                                      )
                                    : Text(
                                        'ยังไม่ได้เลือกคนแชร์',
                                        style: AppTextStyles.captionStyle
                                            .copyWith(
                                              color: Colors.orange.shade600,
                                            ),
                                      ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${AppConstants.currencySymbol}${item.price.toStringAsFixed(2)}',
                                      style: AppTextStyles.priceStyle,
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            _editItem(index);
                                            break;
                                          case 'remove':
                                            _removeItem(index);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 16),
                                              SizedBox(width: 8),
                                              Text('แก้ไข'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'ลบ',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => _editItem(index),
                              ),
                            );
                          },
                        ),
                ),

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
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _selectedItems.isEmpty
                            ? null
                            : _addSelectedItems,
                        child: Text('เพิ่ม ${_selectedItems.length} รายการ'),
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

class _EditItemDialog extends StatefulWidget {
  final Item item;
  final List<Person> availablePeople;

  const _EditItemDialog({required this.item, required this.availablePeople});

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late String _selectedEmoji;
  late List<String> _selectedOwnerIds;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(
      text: widget.item.price.toString(),
    );
    _selectedEmoji = widget.item.emoji;
    _selectedOwnerIds = List<String>.from(widget.item.ownerIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
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

  void _updateEmoji() {
    setState(() {
      _selectedEmoji = EmojiUtils.generateEmoji(_nameController.text);
    });
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedItem = widget.item.copyWith(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        emoji: _selectedEmoji,
        ownerIds: List<String>.from(_selectedOwnerIds),
      );
      Navigator.of(context).pop(updatedItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('แก้ไขรายการ'),
      content: SizedBox(
        width: 300,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name and emoji
              Row(
                children: [
                  GestureDetector(
                    onTap: _updateEmoji,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _selectedEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อรายการ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณาใส่ชื่อรายการ';
                        }
                        return null;
                      },
                      onChanged: (_) => _updateEmoji(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'ราคา (${AppConstants.currencySymbol})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาใส่ราคา';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'กรุณาใส่ราคาที่ถูกต้อง';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // Owner selection
              Text(
                'ใครจะแชร์ค่าใช้จ่าย?',
                style: AppTextStyles.captionStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),

              if (widget.availablePeople.isEmpty)
                const Text(
                  'ไม่มีคนในบิล กรุณาเพิ่มคนก่อน',
                  style: AppTextStyles.captionStyle,
                )
              else
                Wrap(
                  spacing: AppConstants.smallPadding,
                  children: widget.availablePeople.map((person) {
                    final isSelected = _selectedOwnerIds.contains(person.id);
                    return FilterChip(
                      avatar: Text(person.avatar),
                      label: Text(person.name),
                      selected: isSelected,
                      onSelected: (_) => _toggleOwner(person.id),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(onPressed: _saveChanges, child: const Text('บันทึก')),
      ],
    );
  }
}
