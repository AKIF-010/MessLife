import 'package:flutter/material.dart';

/// Kept for compatibility with older code that picks a variant.
enum MessLifeLogoVariant { appIcon, foreground }

/// Shows the app logo from assets (same image as the launcher icon).
class MessLifeLogo extends StatelessWidget {
  const MessLifeLogo({
    super.key,
    this.size = 280,
    this.variant = MessLifeLogoVariant.appIcon,
    this.rounded = false,
  });

  final double size;
  final MessLifeLogoVariant variant;

  /// Rounded-square look inside the app (the PNG itself is a full square).
  final bool rounded;

  static const _appIcon = 'assets/icons/messlife_appicon.png';
  static const _foreground = 'assets/icons/messlife_foreground.png';

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      variant == MessLifeLogoVariant.foreground ? _foreground : _appIcon,
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    );
    if (!rounded || variant == MessLifeLogoVariant.foreground) return image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .22),
      child: image,
    );
  }
}