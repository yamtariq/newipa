import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class DeviceTransitionDialog extends StatelessWidget {
  final Map<String, dynamic> existingDevice;
  final Function(bool) onTransitionDecision;
  final bool isArabic;

  const DeviceTransitionDialog({
    Key? key,
    required this.existingDevice,
    required this.onTransitionDecision,
    this.isArabic = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final lastUsedDate = existingDevice['last_used_at'] != null 
        ? dateFormat.format(DateTime.parse(existingDevice['last_used_at']))
        : '';

    return AlertDialog(
      backgroundColor: isDarkMode ? Colors.grey[100] : Colors.white,
      title: Text(
        isArabic 
            ? 'تم اكتشاف جهاز آخر'
            : 'Different Device Detected',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: themeColor,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? 'لديك جهاز مسجل مسبقاً:'
                : 'You have a previously registered device:',
            style: TextStyle(
              color: isDarkMode ? Colors.black87 : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          _DeviceInfoRow(
            label: isArabic ? 'الموديل:' : 'Model:',
            value: '${existingDevice['manufacturer'] ?? ''} ${existingDevice['model'] ?? ''}',
            isDarkMode: isDarkMode,
          ),
          _DeviceInfoRow(
            label: isArabic ? 'آخر استخدام:' : 'Last Used:',
            value: lastUsedDate,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 16),
          Text(
            isArabic
                ? 'هل تريد استبدال الجهاز القديم بهذا الجهاز؟'
                : 'Would you like to replace the old device with this one?',
            style: TextStyle(
              color: isDarkMode ? Colors.red[300] : Colors.red[700],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => onTransitionDecision(false),
          child: Text(
            isArabic ? 'إلغاء' : 'Cancel',
            style: TextStyle(
              color: isDarkMode ? Colors.black54 : Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => onTransitionDecision(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: Text(
            isArabic ? 'استبدال الجهاز' : 'Replace Device',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class DeviceMismatchDialog extends StatelessWidget {
  final Map<String, dynamic> registeredUser;
  final Function() onUnregisterRequest;
  final bool isArabic;

  const DeviceMismatchDialog({
    Key? key,
    required this.registeredUser,
    required this.onUnregisterRequest,
    this.isArabic = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);

    return AlertDialog(
      backgroundColor: isDarkMode ? Colors.grey[100] : Colors.white,
      title: Text(
        isArabic 
            ? 'الجهاز مسجل لمستخدم آخر'
            : 'Device Registered to Another User',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: themeColor,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? 'هذا الجهاز مسجل للمستخدم:'
                : 'This device is registered to:',
            style: TextStyle(
              color: isDarkMode ? Colors.black87 : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          _UserInfoRow(
            label: isArabic ? 'الاسم:' : 'Name:',
            value: isArabic 
                ? (registeredUser['arabic_name'] ?? '')
                : (registeredUser['name'] ?? ''),
            isDarkMode: isDarkMode,
          ),
          _UserInfoRow(
            label: isArabic ? 'رقم الهوية:' : 'National ID:',
            value: registeredUser['national_id'] ?? '',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 16),
          Text(
            isArabic
                ? 'يجب على المستخدم الحالي تسجيل الخروج أولاً'
                : 'The current user must sign out first',
            style: TextStyle(
              color: isDarkMode ? Colors.red[300] : Colors.red[700],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            isArabic ? 'إلغاء' : 'Cancel',
            style: TextStyle(
              color: isDarkMode ? Colors.black54 : Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onUnregisterRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: Text(
            isArabic ? 'تسجيل خروج المستخدم الحالي' : 'Sign Out Current User',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviceInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDarkMode;

  const _DeviceInfoRow({
    required this.label,
    required this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label, 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.black87 : Colors.grey[800],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDarkMode ? Colors.black54 : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDarkMode;

  const _UserInfoRow({
    required this.label,
    required this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label, 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.black87 : Colors.grey[800],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDarkMode ? Colors.black54 : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 