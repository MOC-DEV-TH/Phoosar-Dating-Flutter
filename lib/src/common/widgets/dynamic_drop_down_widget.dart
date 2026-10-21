
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/dimens.dart';

class DynamicDropDownWidget<T> extends ConsumerStatefulWidget {
  const DynamicDropDownWidget({
    super.key,
    required this.items,
    required this.onSelect,
    required this.getItemName,
    this.defaultBgColor = true,
    this.hintText,
    this.initValue,
  });

  final List<T> items;
  final ValueChanged<T?> onSelect;
  final String Function(T item) getItemName;
  final bool defaultBgColor;
  final T? initValue;
  final String? hintText;

  @override
  ConsumerState<DynamicDropDownWidget<T>> createState() =>
      _DynamicDropDownWidgetState<T>();
}

class _DynamicDropDownWidgetState<T>
    extends ConsumerState<DynamicDropDownWidget<T>> {
  late final ValueNotifier<T?> selectedValue;

  @override
  void initState() {
    super.initState();

    selectedValue = ValueNotifier<T?>(
      widget.items.contains(widget.initValue)
          ? widget.initValue
          : null,
    );
  }

  @override
  void didUpdateWidget(
      covariant DynamicDropDownWidget<T> oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initValue != widget.initValue ||
        oldWidget.items != widget.items) {
      final newValue = widget.items.contains(widget.initValue)
          ? widget.initValue
          : null;

      if (selectedValue.value != newValue) {
        selectedValue.value = newValue;
      }
    }
  }

  @override
  void dispose() {
    selectedValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
      ),
      child: DropdownButtonFormField2<T>(
        valueListenable: selectedValue,
        isExpanded: true,

        hint: Text(
          widget.hintText ?? '',
          style: const TextStyle(
            color: Colors.black,
          ),
        ),

        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.black,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: widget.defaultBgColor
              ? Colors.white
              : Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: kMarginLarge,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),

        selectedItemBuilder: (context) {
          return widget.items.map<Widget>((item) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.getItemName(item),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            );
          }).toList();
        },

        items: widget.items.map((item) {
          return DropdownItem<T>(
            value: item,
            child: Text(
              widget.getItemName(item),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          );
        }).toList(),

        onChanged: (value) {
          selectedValue.value = value;
          widget.onSelect(value);
        },

        validator: (value) {
          if (value == null) {
            return 'Please select';
          }
          return null;
        },

        buttonStyleData: const FormFieldButtonStyleData(
          padding: EdgeInsets.only(right: 8),
        ),

        iconStyleData: const IconStyleData(
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.black45,
          ),
          iconSize: 24,
        ),

        dropdownStyleData: DropdownStyleData(
          maxHeight: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
