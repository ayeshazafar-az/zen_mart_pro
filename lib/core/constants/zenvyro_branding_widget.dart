import 'package:flutter/material.dart';
import 'app_constants.dart';

class ZenvyroBrandingWidget extends StatelessWidget {
  final bool compact;

  const ZenvyroBrandingWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppConstants.zenvyroLogoPath,
            height: compact ? 18 : 26,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.business_rounded,
              size: compact ? 18 : 24,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppConstants.poweredByText,
            style: TextStyle(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}