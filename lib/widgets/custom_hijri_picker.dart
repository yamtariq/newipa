import 'package:flutter/material.dart';
import 'package:flutter_holo_date_picker/widget/date_picker_widget.dart';
import '../utils/constants.dart';

class CustomHijriPicker extends StatefulWidget {
  final bool isArabic;
  final int minYear;
  final int maxYear;
  final int initialYear;
  final Function(int day, int month, int year) onDateSelected;
  final Color primaryColor;
  final bool isDarkMode;

  const CustomHijriPicker({
    Key? key,
    required this.isArabic,
    required this.minYear,
    required this.maxYear,
    required this.initialYear,
    required this.onDateSelected,
    required this.primaryColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<CustomHijriPicker> createState() => _CustomHijriPickerState();
}

class _CustomHijriPickerState extends State<CustomHijriPicker> {
  late int selectedDay = 1;
  late int selectedMonth = 1;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialYear;
  }

  Widget _buildSelectionOverlay() {
    return IgnorePointer(
      child: Container(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(height: 2, color: widget.primaryColor),
                  ),
                  SizedBox(height: 38),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(height: 2, color: widget.primaryColor),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(height: 2, color: widget.primaryColor),
                  ),
                  SizedBox(height: 38),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(height: 2, color: widget.primaryColor),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(height: 2, color: widget.primaryColor),
                  ),
                  SizedBox(height: 38),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(height: 2, color: widget.primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: Stack(
        children: [
          Row(
            children: [
              // Day Picker
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  diameterRatio: 1.1,
                  perspective: 0.01,
                  physics: const FixedExtentScrollPhysics(),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 30,
                    builder: (context, index) {
                      final day = index + 1;
                      return Container(
                        height: 40,
                        alignment: Alignment.center,
                        child: Text(
                          day.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: Color(widget.isDarkMode 
                                ? Constants.darkLabelTextColor 
                                : Constants.lightLabelTextColor),
                            fontSize: 20,
                          ),
                        ),
                      );
                    },
                  ),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      selectedDay = index + 1;
                      widget.onDateSelected(selectedDay, selectedMonth, selectedYear);
                    });
                  },
                ),
              ),
              // Month Picker
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  diameterRatio: 1.1,
                  perspective: 0.01,
                  physics: const FixedExtentScrollPhysics(),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 12,
                    builder: (context, index) {
                      final month = index + 1;
                      return Container(
                        height: 40,
                        alignment: Alignment.center,
                        child: Text(
                          month.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: Color(widget.isDarkMode 
                                ? Constants.darkLabelTextColor 
                                : Constants.lightLabelTextColor),
                            fontSize: 20,
                          ),
                        ),
                      );
                    },
                  ),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      selectedMonth = index + 1;
                      widget.onDateSelected(selectedDay, selectedMonth, selectedYear);
                    });
                  },
                ),
              ),
              // Year Picker
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  diameterRatio: 1.1,
                  perspective: 0.01,
                  physics: const FixedExtentScrollPhysics(),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: widget.maxYear - widget.minYear + 1,
                    builder: (context, index) {
                      final year = widget.minYear + index;
                      return Container(
                        height: 40,
                        alignment: Alignment.center,
                        child: Text(
                          year.toString(),
                          style: TextStyle(
                            color: Color(widget.isDarkMode 
                                ? Constants.darkLabelTextColor 
                                : Constants.lightLabelTextColor),
                            fontSize: 20,
                          ),
                        ),
                      );
                    },
                  ),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      selectedYear = widget.minYear + index;
                      widget.onDateSelected(selectedDay, selectedMonth, selectedYear);
                    });
                  },
                ),
              ),
            ],
          ),
          // Selection overlay
          _buildSelectionOverlay(),
        ],
      ),
    );
  }
} 