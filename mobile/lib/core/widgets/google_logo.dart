import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Authentic Google 4-Color 'G' Logo from official branding specification
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({
    super.key,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/branding/google_g.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

