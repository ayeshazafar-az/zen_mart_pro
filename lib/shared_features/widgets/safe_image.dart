import 'dart:convert';
import 'package:flutter/material.dart';

class SafeImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SafeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    int? getCacheWidth() {
      int calculatedWidth = 500; // Safe fallback
      if (width != null && width != double.infinity && width! > 0) {
        calculatedWidth = (width! * 2.5).toInt();
      } else {
        final screenWidth = MediaQuery.of(context).size.width;
        if (screenWidth > 0) {
          calculatedWidth = (screenWidth * 2.5).toInt();
        }
      }
      // Ensure we never pass 0 to the native image decoder (causes SIG 9 JVM crash)
      return calculatedWidth > 0 ? calculatedWidth : null;
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: getCacheWidth(),
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    try {
      final bytes = base64Decode(imageUrl);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: getCacheWidth(),
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } catch (e) {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey),
      ),
    );
  }
}
