import 'package:flutter/material.dart';

import '../models/item.dart';
import '../models/person.dart';
import '../utils/constants.dart';

class ItemCard extends StatefulWidget {
  final Item item;
  final List<Person> people;
  final bool showHintAnimation;
  final VoidCallback? onDelete;
  final Function(double discount)? onDiscount;
  final Function(List<String> ownerIds)? onOwnersChanged; // เพิ่ม callback สำหรับเปลี่ยนคนที่แชร์

  const ItemCard({
    super.key,
    required this.item,
    required this.people,
    this.showHintAnimation = false,
    this.onDelete,
    this.onDiscount,
    this.onOwnersChanged,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> with TickerProviderStateMixin {
  late AnimationController _hintController;
  late Animation<double> _hintAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize hint animation
    _hintController = AnimationController(
      duration: AppConstants.hintAnimationDuration,
      vsync: this,
    );

    _hintAnimation = Tween<double>(begin: 0.0, end: 30.0).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.elasticInOut),
    );

    // Start hint animation if needed
    if (widget.showHintAnimation) {
      _startHintAnimation();
    }
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  void _startHintAnimation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _hintController.forward().then((_) {
          _hintController.reverse();
        });
      }
    });
  }

  void _showDiscountDialog() async {
    final discount = await showDialog<double>(
      context: context,
      builder: (context) => _DiscountDialog(
        itemName: widget.item.name,
        currentPrice: widget.item.price,
        currentDiscount: widget.item.discount,
      ),
    );

    if (discount != null && widget.onDiscount != null) {
      widget.onDiscount!(discount);
    }
  }

  void _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบรายการ'),
        content: Text('ต้องการลบ "${widget.item.name}" หรือไม่?'),
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

    if (confirmed == true && widget.onDelete != null) {
      widget.onDelete!();
    }
  }

  void _showOwnerSelectionDialog() async {
    final selectedOwnerIds = await showDialog<List<String>>(
      context: context,
      builder: (context) => _OwnerSelectionDialog(
        itemName: widget.item.name,
        availablePeople: widget.people,
        currentOwnerIds: widget.item.ownerIds,
      ),
    );

    if (selectedOwnerIds != null && widget.onOwnersChanged != null) {
      widget.onOwnersChanged!(selectedOwnerIds);
    }
  }

  Widget _buildBackground(DismissDirection direction) {
    final bool isDelete = direction == DismissDirection.endToStart;

    return Container(
      alignment: isDelete ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: isDelete ? Colors.red.shade400 : Colors.green.shade400,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDelete) ...[
            Icon(
              Icons.discount,
              color: Colors.white,
              size: AppConstants.largeIconSize,
            ),
            const SizedBox(width: 8),
            Text(
              'ลด',
              style: AppTextStyles.buttonStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            Text(
              'ลบ',
              style: AppTextStyles.buttonStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.delete,
              color: Colors.white,
              size: AppConstants.largeIconSize,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerNames = widget.item.ownerIds
        .map(
          (id) => widget.people
              .firstWhere(
                (person) => person.id == id,
                orElse: () => Person(id: id, name: 'Unknown', avatar: '❓'),
              )
              .name,
        )
        .join(', ');

    return AnimatedBuilder(
      animation: _hintAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_hintAnimation.value, 0),
          child: Dismissible(
            key: Key(widget.item.id),
            background: _buildBackground(DismissDirection.startToEnd),
            secondaryBackground: _buildBackground(DismissDirection.endToStart),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // Swipe right - show discount dialog
                _showDiscountDialog();
                return false; // Don't actually dismiss
              } else {
                // Swipe left - confirm delete
                _confirmDelete();
                return false; // Don't actually dismiss, handle in dialog
              }
            },
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                onTap: _showOwnerSelectionDialog, // เพิ่ม onTap เพื่อเลือกคนที่แชร์
                leading: Text(
                  widget.item.emoji,
                  style: AppTextStyles.emojiStyle,
                ),
                title: Text(widget.item.name, style: AppTextStyles.bodyStyle),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.ownerIds.isEmpty 
                        ? 'แตะเพื่อเลือกคนที่แชร์' 
                        : 'แชร์กับ: $ownerNames',
                      style: AppTextStyles.captionStyle.copyWith(
                        color: widget.item.ownerIds.isEmpty 
                          ? Colors.orange.shade600 
                          : null,
                        fontStyle: widget.item.ownerIds.isEmpty 
                          ? FontStyle.italic 
                          : null,
                      ),
                    ),
                    if (widget.item.hasDiscount)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Text(
                              '${AppConstants.currencySymbol}${widget.item.discountedPrice.toStringAsFixed(2)}',
                              style: AppTextStyles.discountedPriceStyle,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${AppConstants.currencySymbol}${widget.item.price.toStringAsFixed(2)}',
                              style: AppTextStyles.originalPriceStyle,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.item.hasDiscount
                          ? '${AppConstants.currencySymbol}${widget.item.discountedPrice.toStringAsFixed(2)}'
                          : '${AppConstants.currencySymbol}${widget.item.price.toStringAsFixed(2)}',
                      style: widget.item.hasDiscount
                          ? AppTextStyles.discountedPriceStyle
                          : AppTextStyles.priceStyle,
                    ),
                    if (widget.item.hasDiscount)
                      Text(
                        'ลด ${AppConstants.currencySymbol}${widget.item.discount.toStringAsFixed(2)}',
                        style: AppTextStyles.captionStyle.copyWith(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DiscountDialog extends StatefulWidget {
  final String itemName;
  final double currentPrice;
  final double currentDiscount;

  const _DiscountDialog({
    required this.itemName,
    required this.currentPrice,
    required this.currentDiscount,
  });

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController();
  bool _isPercentage = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentDiscount > 0) {
      _discountController.text = widget.currentDiscount.toString();
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  double get _maxDiscount {
    return _isPercentage ? 100.0 : widget.currentPrice;
  }

  double get _previewDiscount {
    final input = double.tryParse(_discountController.text) ?? 0.0;
    if (_isPercentage) {
      return widget.currentPrice * (input / 100);
    }
    return input;
  }

  double get _previewPrice {
    return (widget.currentPrice - _previewDiscount).clamp(0.0, double.infinity);
  }

  void _submitDiscount() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_previewDiscount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('ลดราคา "${widget.itemName}"'),
      content: SizedBox(
        width: 300,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current price display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ราคาเดิม: ${AppConstants.currencySymbol}${widget.currentPrice.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyStyle,
                    ),
                    if (_previewDiscount > 0) ...[
                      Text(
                        'ลด: ${AppConstants.currencySymbol}${_previewDiscount.toStringAsFixed(2)}',
                        style: AppTextStyles.captionStyle.copyWith(
                          color: Colors.red.shade600,
                        ),
                      ),
                      Text(
                        'ราคาใหม่: ${AppConstants.currencySymbol}${_previewPrice.toStringAsFixed(2)}',
                        style: AppTextStyles.priceStyle.copyWith(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // Discount type selector
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('จำนวนเงิน'),
                      value: false,
                      groupValue: _isPercentage,
                      onChanged: (value) {
                        setState(() {
                          _isPercentage = value!;
                          _discountController.clear();
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('เปอร์เซ็นต์'),
                      value: true,
                      groupValue: _isPercentage,
                      onChanged: (value) {
                        setState(() {
                          _isPercentage = value!;
                          _discountController.clear();
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              // Discount input
              TextFormField(
                controller: _discountController,
                decoration: InputDecoration(
                  labelText: _isPercentage ? 'เปอร์เซ็นต์ลด' : 'จำนวนเงินลด',
                  hintText: _isPercentage ? '10' : '50.00',
                  border: const OutlineInputBorder(),
                  prefixText: _isPercentage
                      ? null
                      : AppConstants.currencySymbol,
                  suffixText: _isPercentage ? '%' : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาใส่จำนวนลด';
                  }
                  final discount = double.tryParse(value);
                  if (discount == null || discount < 0) {
                    return 'กรุณาใส่ตัวเลขที่ถูกต้อง';
                  }
                  if (discount > _maxDiscount) {
                    return _isPercentage
                        ? 'ไม่สามารถลดเกิน 100%'
                        : 'ไม่สามารถลดเกินราคาสินค้า';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // Quick discount buttons
              Text('ลดด่วน:', style: AppTextStyles.captionStyle),
              const SizedBox(height: AppConstants.smallPadding),
              Wrap(
                spacing: AppConstants.smallPadding,
                children: _isPercentage
                    ? [10, 20, 30, 50].map((percent) {
                        return ActionChip(
                          label: Text('$percent%'),
                          onPressed: () {
                            _discountController.text = percent.toString();
                            setState(() {});
                          },
                        );
                      }).toList()
                    : [10, 20, 50, 100].map((amount) {
                        return ActionChip(
                          label: Text('${AppConstants.currencySymbol}$amount'),
                          onPressed: () {
                            _discountController.text = amount.toString();
                            setState(() {});
                          },
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
        if (widget.currentDiscount > 0)
          TextButton(
            onPressed: () => Navigator.of(context).pop(0.0),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('ลบส่วนลด'),
          ),
        ElevatedButton(
          onPressed: _submitDiscount,
          child: const Text('ใส่ส่วนลด'),
        ),
      ],
    );
  }
}

class _OwnerSelectionDialog extends StatefulWidget {
  final String itemName;
  final List<Person> availablePeople;
  final List<String> currentOwnerIds;

  const _OwnerSelectionDialog({
    required this.itemName,
    required this.availablePeople,
    required this.currentOwnerIds,
  });

  @override
  State<_OwnerSelectionDialog> createState() => _OwnerSelectionDialogState();
}

class _OwnerSelectionDialogState extends State<_OwnerSelectionDialog> {
  late List<String> _selectedOwnerIds;

  @override
  void initState() {
    super.initState();
    _selectedOwnerIds = List<String>.from(widget.currentOwnerIds);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('เลือกคนที่แชร์ "${widget.itemName}"'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.availablePeople.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  color: Colors.orange.shade50,
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700),
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
              
              // People selection
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.availablePeople.map((person) {
                      final isSelected = _selectedOwnerIds.contains(person.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleOwner(person.id),
                        title: Row(
                          children: [
                            Text(person.avatar, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(person.name),
                          ],
                        ),
                        dense: true,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: widget.availablePeople.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selectedOwnerIds),
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}