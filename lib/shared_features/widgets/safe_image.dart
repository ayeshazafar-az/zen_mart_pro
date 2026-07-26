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
      if (width != null && width != double.infinity) {
        return (width! * 2.5).toInt();
      }
      return (MediaQuery.of(context).size.width * 2.5).toInt();
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
