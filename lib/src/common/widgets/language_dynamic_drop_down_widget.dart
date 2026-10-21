
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/dimens.dart';

class LanguageDynamicDropDownWidget<T>
    extends ConsumerStatefulWidget {
  const LanguageDynamicDropDownWidget({
    super.key,
    required this.items,
    required this.onSelect,
    this.defaultBgColor = true,
    this.hintText,
    this.initValue,
    required this.selectedList,
  });

  final List<dynamic> items;
  final void Function(dynamic) onSelect;
  final bool defaultBgColor;
  final dynamic initValue;
  final String? hintText;
  final List<dynamic> selectedList;

  @override
  ConsumerState<LanguageDynamicDropDownWidget<T>> createState() =>
      _LanguageDynamicDropDownWidgetState<T>();
}

class _LanguageDynamicDropDownWidgetState<T>
    extends ConsumerState<LanguageDynamicDropDownWidget<T>> {
  late final ValueNotifier<dynamic> selectedValue;

  dynamic _getSelectedValue() {
    if (widget.selectedList.isEmpty) {
      return null;
    }

    if (widget.initValue == null) {
      return null;
    }

    // Ensure the selected value exists in the dropdown items.
    for (final item in widget.items) {
      if (item == widget.initValue) {
        return item;
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();

    selectedValue = ValueNotifier<dynamic>(
      _getSelectedValue(),
    );
  }

  @override
  void didUpdateWidget(
      covariant LanguageDynamicDropDownWidget<T> oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initValue != widget.initValue ||
        oldWidget.selectedList != widget.selectedList ||
        oldWidget.items != widget.items) {
      selectedValue.value = _getSelectedValue();
    }
  }

  @override
  void dispose() {
    selectedValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      "ItemLength:::${widget.selectedList.length}",
    );

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
      ),
      child: DropdownButtonFormField2<dynamic>(
        valueListenable: selectedValue,
        isExpanded: true,

        hint: Text(
          widget.hintText ?? 'Select Language',
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

        selectedItemBuilder: (BuildContext context) {
          return widget.items.map<Widget>((item) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item['name']?.toString() ?? '',
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
          return DropdownItem<dynamic>(
            value: item,
            child: Text(
              item['name']?.toString() ?? '',
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
