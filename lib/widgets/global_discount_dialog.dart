import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bill.dart';
import '../utils/constants.dart';

class GlobalDiscountDialog extends StatefulWidget {
  final BillDiscount? currentDiscount;
  final double billSubtotal;

  const GlobalDiscountDialog({
    super.key,
    this.currentDiscount,
    required this.billSubtotal,
  });

  @override
  State<GlobalDiscountDialog> createState() => _GlobalDiscountDialogState();
}

class _GlobalDiscountDialogState extends State<GlobalDiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();

  DiscountType _discountType = DiscountType.amount;
  DiscountSplitType _splitType = DiscountSplitType.equal;

  @override
  void initState() {
    super.initState();
    if (widget.currentDiscount != null) {
      _discountType = widget.currentDiscount!.type;
      _splitType = widget.currentDiscount!.splitType;
      _valueController.text = widget.currentDiscount!.value.toString();
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  double get _maxDiscount {
    return _discountType == DiscountType.percentage
        ? 100.0
        : widget.billSubtotal;
  }

  double get _previewDiscountAmount {
    final input = double.tryParse(_valueController.text) ?? 0.0;
    if (_discountType == DiscountType.percentage) {
      return widget.billSubtotal * (input / 100);
    }
    return input;
  }

  double get _previewTotal {
    return (widget.billSubtotal - _previewDiscountAmount).clamp(
      0.0,
      double.infinity,
    );
  }

  void _submitDiscount() {
    if (_formKey.currentState!.validate()) {
      final discount = BillDiscount(
        value: double.parse(_valueController.text),
        type: _discountType,
        splitType: _splitType,
      );
      Navigator.of(context).pop(discount);
    }
  }

  void _removeDiscount() {
    Navigator.of(context).pop('remove');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Text('💸', style: AppTextStyles.emojiStyle),
          SizedBox(width: 8),
          Text('ส่วนลดรวมทั้งบิล'),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bill summary
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
                      'ยอดรวมก่อนลด: ${widget.billSubtotal.toStringAsFixed(2)} ${AppConstants.currencyText}',
                      style: AppTextStyles.bodyStyle,
                    ),
                    if (_previewDiscountAmount > 0) ...[
                      Text(
                        'ส่วนลดรวม: ${_previewDiscountAmount.toStringAsFixed(2)} ${AppConstants.currencyText}',
                        style: AppTextStyles.captionStyle.copyWith(
                          color: Colors.red.shade600,
                        ),
                      ),
                      Text(
                        'ยอดสุทธิ: ${_previewTotal.toStringAsFixed(2)} ${AppConstants.currencyText}',
                        style: AppTextStyles.priceStyle.copyWith(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.largePadding),

              // Discount type selection
              Text(
                'ประเภทส่วนลด:',
                style: AppTextStyles.captionStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),

              Row(
                children: [
                  Expanded(
                    child: RadioListTile<DiscountType>(
                      title: const Text('จำนวนเงิน'),
                      subtitle: Text(AppConstants.currencyText),
                      value: DiscountType.amount,
                      groupValue: _discountType,
                      onChanged: (value) {
                        setState(() {
                          _discountType = value!;
                          _valueController.clear();
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<DiscountType>(
                      title: const Text('เปอร์เซ็นต์'),
                      subtitle: const Text('%'),
                      value: DiscountType.percentage,
                      groupValue: _discountType,
                      onChanged: (value) {
                        setState(() {
                          _discountType = value!;
                          _valueController.clear();
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // Discount value input
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: _discountType == DiscountType.percentage
                      ? 'เปอร์เซ็นต์ลด'
                      : 'จำนวนเงินลด',
                  hintText: _discountType == DiscountType.percentage
                      ? '10'
                      : '100.00',
                  border: const OutlineInputBorder(),
                  prefixText: _discountType == DiscountType.amount
                      ? '${AppConstants.currencyText} '
                      : null,
                  suffixText: _discountType == DiscountType.percentage
                      ? '%'
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาใส่จำนวนลด';
                  }
                  final discount = double.tryParse(value);
                  if (discount == null || discount < 0) {
                    return 'กรุณาใส่ตัวเลขที่ถูกต้อง';
                  }
                  if (discount > _maxDiscount) {
                    return _discountType == DiscountType.percentage
                        ? 'ไม่สามารถลดเกิน 100%'
                        : 'ไม่สามารถลดเกินยอดรวม';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // Quick discount buttons
              Text(
                'ลดด่วน:',
                style: AppTextStyles.captionStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Wrap(
                spacing: AppConstants.smallPadding,
                children: _discountType == DiscountType.percentage
                    ? [5, 10, 15, 20].map((percent) {
                        return ActionChip(
                          label: Text('$percent%'),
                          onPressed: () {
                            _valueController.text = percent.toString();
                            setState(() {});
                          },
                        );
                      }).toList()
                    : [50, 100, 200, 500].map((amount) {
                        return ActionChip(
                          label: Text('$amount ${AppConstants.currencyText}'),
                          onPressed: () {
                            _valueController.text = amount.toString();
                            setState(() {});
                          },
                        );
                      }).toList(),
              ),

              const SizedBox(height: AppConstants.largePadding),

              // Split type selection
              Text(
                'วิธีการแบ่งส่วนลด:',
                style: AppTextStyles.captionStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),

              Column(
                children: [
                  RadioListTile<DiscountSplitType>(
                    title: const Text('หารเท่ากัน'),
                    subtitle: const Text('แบ่งส่วนลดเท่ากันทุกคน'),
                    value: DiscountSplitType.equal,
                    groupValue: _splitType,
                    onChanged: (value) {
                      setState(() {
                        _splitType = value!;
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<DiscountSplitType>(
                    title: const Text('หารตามยอดจ่าย'),
                    subtitle: const Text('แบ่งส่วนลดตามสัดส่วนที่แต่ละคนจ่าย'),
                    value: DiscountSplitType.proportional,
                    groupValue: _splitType,
                    onChanged: (value) {
                      setState(() {
                        _splitType = value!;
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
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
        if (widget.currentDiscount != null)
          TextButton(
            onPressed: _removeDiscount,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
