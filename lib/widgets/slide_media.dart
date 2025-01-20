import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/slide.dart';

class SlideMedia extends StatefulWidget {
  final Slide slide;
  final BoxFit fit;

  const SlideMedia({
    Key? key,
    required this.slide,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<SlideMedia> createState() => _SlideMediaState();
}

class _SlideMediaState extends State<SlideMedia> {
  @override
  Widget build(BuildContext context) {
    // If we have cached image bytes, use them
    if (widget.slide.imageBytes != null) {
      return Image.memory(
        Uint8List.fromList(widget.slide.imageBytes!),
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error_outline, size: 40),
          );
        },
      );
    }
    
    // If it's an asset path, use Image.asset
    if (widget.slide.imageUrl.startsWith('assets/')) {
      return Image.asset(
        widget.slide.imageUrl,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error_outline, size: 40),
          );
        },
      );
    }
    
    // Otherwise, try to load from network
    return Image.network(
      widget.slide.imageUrl,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.error_outline, size: 40),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }
} 