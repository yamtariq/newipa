import 'package:flutter/material.dart';

class BranchLocatorPageAr extends StatelessWidget {
  const BranchLocatorPageAr({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('موقع الفروع'),
        ),
        body: const Center(
          child: Text('صفحة البحث عن الفروع'),
        ),
      ),
    );
  }
} 