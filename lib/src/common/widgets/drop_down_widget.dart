import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phoosar/src/utils/colors.dart';
import '../../utils/dimens.dart';

class DropDownWidget extends ConsumerStatefulWidget {
  const DropDownWidget({
    super.key,
    required this.items,
    required this.onSelect,
    this.defaultBgColor = true,
    required this.initValue,
  });

  final List<String> items;
  final ValueChanged<String?> onSelect;
  final bool defaultBgColor;
  final String? initValue;

  @override
  ConsumerState<DropDownWidget> createState() =>
      _DropDownWidgetState();
}

class _DropDownWidgetState extends ConsumerState<DropDownWidget> {
  final TextEditingController textEditingController =
  TextEditingController();

  late final ValueNotifier<String?> selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = ValueNotifier<String?>(widget.initValue);
  }

  @override
  void didUpdateWidget(covariant DropDownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initValue != widget.initValue ||
        oldWidget.items != widget.items) {
      selectedValue.value =
      widget.items.contains(widget.initValue)
          ? widget.initValue
          : null;
    }
  }

  @override
  void dispose() {
    textEditingController.dispose();
    selectedValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items.toSet().toList();

    if (selectedValue.value != null &&
        !items.contains(selectedValue.value)) {
      selectedValue.value = null;
    }

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: whitePaleColor,
      ),
      child: DropdownButtonFormField2<String>(
        valueListenable: selectedValue,
        isExpanded: true,

        selectedItemBuilder: (context) {
          return items.map<Widget>((value) {
            return Center(
              child: FittedBox(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList();
        },

        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Colors.black,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: kMarginLarge,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        items: items.map((item) {
          return DropdownItem<String>(
            value: item,
            child: SizedBox(
              width: 200,
              child: Center(
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: kTextRegular2x,
                  ),
                ),
              ),
            ),
          );
        }).toList(),

        validator: (value) {
          if (value == null) {
            return 'Please select';
          }
          return null;
        },

        onChanged: (value) {
          selectedValue.value = value;
          widget.onSelect(value);
        },

        buttonStyleData: const FormFieldButtonStyleData(
          padding: EdgeInsets.only(right: 0),
        ),

        iconStyleData: const IconStyleData(
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.black,
          ),
          iconSize: 14,
        ),

        dropdownStyleData: DropdownStyleData(
          maxHeight: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 0),
        ),

        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            textEditingController.clear();
          }
        },
      ),
    );
  }
}