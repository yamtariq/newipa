import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final lastUsedDate = existingDevice['last_used_at'] != null 
        ? dateFormat.format(DateTime.parse(existingDevice['last_used_at']))
        : '';

    return AlertDialog(
      title: Text(
        isArabic 
            ? 'تم اكتشاف جهاز آخر'
            : 'Different Device Detected',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? 'لديك جهاز مسجل مسبقاً:'
                : 'You have a previously registered device:',
          ),
          const SizedBox(height: 16),
          _DeviceInfoRow(
            label: isArabic ? 'الموديل:' : 'Model:',
            value: '${existingDevice['manufacturer'] ?? ''} ${existingDevice['model'] ?? ''}',
          ),
          _DeviceInfoRow(
            label: isArabic ? 'آخر استخدام:' : 'Last Used:',
            value: lastUsedDate,
          ),
          const SizedBox(height: 16),
          Text(
            isArabic
                ? 'هل تريد استبدال الجهاز القديم بهذا الجهاز؟'
                : 'Would you like to replace the old device with this one?',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => onTransitionDecision(false),
          child: Text(
            isArabic ? 'إلغاء' : 'Cancel',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () => onTransitionDecision(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0077B6),
          ),
          child: Text(
            isArabic ? 'استبدال الجهاز' : 'Replace Device',
            style: const TextStyle(color: Colors.white),
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
    return AlertDialog(
      title: Text(
        isArabic 
            ? 'الجهاز مسجل لمستخدم آخر'
            : 'Device Registered to Another User',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic
                ? 'هذا الجهاز مسجل للمستخدم:'
                : 'This device is registered to:',
          ),
          const SizedBox(height: 16),
          _UserInfoRow(
            label: isArabic ? 'الاسم:' : 'Name:',
            value: isArabic 
                ? (registeredUser['arabic_name'] ?? '')
                : (registeredUser['name'] ?? ''),
          ),
          _UserInfoRow(
            label: isArabic ? 'رقم الهوية:' : 'National ID:',
            value: registeredUser['national_id'] ?? '',
          ),
          const SizedBox(height: 16),
          Text(
            isArabic
                ? 'يجب على المستخدم الحالي تسجيل الخروج أولاً'
                : 'The current user must sign out first',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            isArabic ? 'إلغاء' : 'Cancel',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: onUnregisterRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0077B6),
          ),
          child: Text(
            isArabic ? 'تسجيل خروج المستخدم الحالي' : 'Sign Out Current User',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _DeviceInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DeviceInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
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

  const _UserInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 