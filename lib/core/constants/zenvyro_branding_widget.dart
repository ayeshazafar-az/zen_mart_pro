import 'package:flutter/material.dart';
import 'app_constants.dart';

class ZenvyroBrandingWidget extends StatelessWidget {
  final bool compact;

  const ZenvyroBrandingWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppConstants.zenvyroLogoPath,
            height: compact ? 20 : 30,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, size: 24),
          ),
          const SizedBox(width: 8),
          Text(
            AppConstants.poweredByText,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}