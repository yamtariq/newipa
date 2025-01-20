import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/content_update_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  final bool isArabic;

  const SplashScreen({
    Key? key,
    required this.isArabic,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _startAnimations = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Start animations after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _startAnimations = true;
      });

      // Load content during animations
      final contentService = Provider.of<ContentUpdateService>(context, listen: false);
      final contentFuture = contentService.checkAndUpdateContent(force: true, isInitialLoad: true);

      // Wait for both animations and content to complete
      await Future.wait([
        contentFuture,
        Future.delayed(const Duration(milliseconds: 2200)),
      ]);

      // Navigate directly to home, skipping loading screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      debugPrint('Error during app initialization: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F4F8), // Light gray background
        body: SafeArea(
          child: Align(
            alignment: const AlignmentDirectional(0, 0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_startAnimations)
                  Align(
                    alignment: const AlignmentDirectional(0, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // First Image (Logo with Words)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/nayifatlogowords-nobg.png',
                            width: 170,
                            height: 85,
                            fit: BoxFit.cover,
                          ),
                        ).animate()
                          .move(
                            begin: const Offset(-100, 0),
                            end: Offset.zero,
                            curve: Curves.bounceOut,
                            duration: 1200.ms,
                          ),
                        // Second Image (Logo Circle)
                        Align(
                          alignment: const AlignmentDirectional(0, 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/nayifatlogocircle-nobg.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.fill,
                              alignment: const Alignment(-1, 0),
                            ),
                          ),
                        ).animate()
                          .rotate(
                            begin: 3.0,
                            end: 1.0,
                            curve: Curves.linear,
                            duration: 600.ms,
                          )
                          .move(
                            begin: const Offset(100, 0),
                            end: Offset.zero,
                            curve: Curves.bounceOut,
                            duration: 1200.ms,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}