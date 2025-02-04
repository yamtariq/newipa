import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class CustomDatePicker extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  final Function(HijriCalendar)? onHijriDateSelected;

  const CustomDatePicker({
    Key? key,
    this.onDateSelected,
    this.onHijriDateSelected,
  }) : super(key: key);

  @override
  _CustomDatePickerState createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDay = 5;
  String _selectedMonth = 'May';
  int _selectedYear = 1990;
  bool _isGregorian = true;

  final List<String> _gregorianMonths = [
    'April', 'May', 'June'
  ];

  final List<String> _hijriMonths = [
    'Muharram', 'Safar', 'Rabi Al-Awwal', 'Rabi Al-Thani',
    'Jumada Al-Awwal', 'Jumada Al-Thani', 'Rajab', 'Shaban',
    'Ramadan', 'Shawwal', 'Dhu Al-Qadah', 'Dhu Al-Hijjah'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _isGregorian = _tabController.index == 0;
        // Reset selections when switching calendars
        _selectedDay = 5;
        _selectedMonth = _isGregorian ? 'May' : 'Muharram';
        _selectedYear = _isGregorian ? 1990 : 1441;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildNumberSelector(List<int> numbers, int selected, Function(int) onChanged) {
    return Container(
      height: 200,
      child: ListWheelScrollView(
        itemExtent: 50,
        diameterRatio: 1.5,
        useMagnifier: true,
        magnification: 1.2,
        onSelectedItemChanged: (index) => onChanged(numbers[index]),
        children: numbers.map((number) {
          return Container(
            alignment: Alignment.center,
            child: Text(
              number.toString(),
              style: TextStyle(
                fontSize: 20,
                color: number == selected ? Colors.black : Colors.grey,
                fontWeight: number == selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthSelector(List<String> months, String selected, Function(String) onChanged) {
    return Container(
      height: 200,
      child: ListWheelScrollView(
        itemExtent: 50,
        diameterRatio: 1.5,
        useMagnifier: true,
        magnification: 1.2,
        onSelectedItemChanged: (index) => onChanged(months[index]),
        children: months.map((month) {
          return Container(
            alignment: Alignment.center,
            child: Text(
              month,
              style: TextStyle(
                fontSize: 20,
                color: month == selected ? Colors.black : Colors.grey,
                fontWeight: month == selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _updateDate() {
    if (_isGregorian) {
      final date = DateTime(_selectedYear, _gregorianMonths.indexOf(_selectedMonth) + 4, _selectedDay);
      widget.onDateSelected?.call(date);
    } else {
      final hijriDate = HijriCalendar()
        ..hYear = _selectedYear
        ..hMonth = _hijriMonths.indexOf(_selectedMonth) + 1
        ..hDay = _selectedDay;
      widget.onHijriDateSelected?.call(hijriDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Gregorian'),
            Tab(text: 'Hijri'),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildNumberSelector(
                List.generate(31, (i) => i + 1),
                _selectedDay,
                (value) => setState(() {
                  _selectedDay = value;
                  _updateDate();
                }),
              ),
            ),
            Expanded(
              child: _buildMonthSelector(
                _isGregorian ? _gregorianMonths : _hijriMonths,
                _selectedMonth,
                (value) => setState(() {
                  _selectedMonth = value;
                  _updateDate();
                }),
              ),
            ),
            Expanded(
              child: _buildNumberSelector(
                _isGregorian
                    ? List.generate(3, (i) => 1989 + i)
                    : List.generate(3, (i) => 1440 + i),
                _selectedYear,
                (value) => setState(() {
                  _selectedYear = value;
                  _updateDate();
                }),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateDate();
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      ],
    );
  }
}
