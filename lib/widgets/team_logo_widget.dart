import 'dart:io';
import 'package:flutter/material.dart';

class TeamLogoWidget extends StatelessWidget {
  final String? logoPath;
  final String teamName;
  final double size;
  final bool hasBorder;

  const TeamLogoWidget({
    super.key,
    required this.logoPath,
    required this.teamName,
    this.size = 40,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.colorScheme.surfaceContainerLow; // darkGrayCard (0xFF1C1F1D)

    // Build the default placeholder widget
    Widget buildPlaceholder() {
      final initial = teamName.isNotEmpty ? teamName.substring(0, 1).toUpperCase() : '?';
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cardColor,
          shape: BoxShape.circle,
          border: hasBorder
              ? Border.all(
                  color: primaryColor.withAlpha((255 * 0.4).toInt()),
                  width: 1.5,
                )
              : null,
        ),
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.45,
            ),
          ),
        ),
      );
    }

    // Resolve the logo image
    Widget? imageWidget;

    if (logoPath != null && logoPath!.isNotEmpty) {
      final file = File(logoPath!);
      imageWidget = Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildPlaceholder(),
      );
    }

    // Wrap the image in a circular clip with optional border
    if (imageWidget != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cardColor,
          shape: BoxShape.circle,
          border: hasBorder
              ? Border.all(
                  color: primaryColor.withAlpha((255 * 0.3).toInt()),
                  width: 1.5,
                )
              : null,
        ),
        child: ClipOval(
          child: imageWidget,
        ),
      );
    }

    return buildPlaceholder();
  }
}
