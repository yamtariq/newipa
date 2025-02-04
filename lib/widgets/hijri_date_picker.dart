import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';

class HijriDatePickerWidget extends StatelessWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime initialDate;
  final bool isArabic;
  final Function(DateTime) onDateChanged;
  final DateTimePickerTheme pickerTheme;

  const HijriDatePickerWidget({
    Key? key,
    required this.firstDate,
    required this.lastDate,
    required this.initialDate,
    required this.isArabic,
    required this.onDateChanged,
    required this.pickerTheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Day picker
        Expanded(
          child: DatePickerWidget(
            looping: true,
            firstDate: firstDate,
            lastDate: lastDate,
            initialDate: initialDate,
            dateFormat: "dd",
            locale: isArabic ? DateTimePickerLocale.ar : DateTimePickerLocale.en_us,
            pickerTheme: pickerTheme,
            onChange: onDateChanged,
          ),
        ),
        // Month picker
        Expanded(
          child: DatePickerWidget(
            looping: true,
            firstDate: firstDate,
            lastDate: lastDate,
            initialDate: initialDate,
            dateFormat: "MM",
            locale: isArabic ? DateTimePickerLocale.ar : DateTimePickerLocale.en_us,
            pickerTheme: pickerTheme,
            onChange: onDateChanged,
          ),
        ),
        // Hijri Year picker
        Expanded(
          child: DatePickerWidget(
            looping: true,
            firstDate: firstDate,
            lastDate: lastDate,
            initialDate: initialDate,
            dateFormat: "yyyy",
            locale: isArabic ? DateTimePickerLocale.ar : DateTimePickerLocale.en_us,
            pickerTheme: pickerTheme,
            onChange: onDateChanged,
          ),
        ),
      ],
    );
  }
} 