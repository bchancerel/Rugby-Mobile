import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rugby_jam_mobile/core/assets/app_assets.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    this.size = 52,
    super.key,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppAssets.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
