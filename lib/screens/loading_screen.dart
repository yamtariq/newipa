import 'package:flutter/material.dart';
import '../services/content_update_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class LoadingScreen extends StatefulWidget {
  final bool isArabic;

  const LoadingScreen({
    Key? key,
    required this.isArabic,
  }) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _prepareContent();
    
    // Initialize animation controller with faster rotation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // Faster rotation
      vsync: this,
    );

    // Create a curved animation for smoother rotation
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );

    // Start the continuous rotation
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _prepareContent() async {
    try {
      final contentService = Provider.of<ContentUpdateService>(context, listen: false);
      
      // Force update to ensure fresh content
      await contentService.checkAndUpdateContent(force: true);

      // Navigate to home when content is ready
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      debugPrint('Error preparing content: $e');
      // Still navigate to home even if there's an error
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      body: Center(
        child: RotationTransition(
          turns: _animation,
          child: Image.asset(
            'assets/images/nayifatlogocircle-nobg.png',
            width: 100,
            height: 100,
          ),
        ),
      ),
    );
  }
} 