import 'package:flutter/material.dart';
import '../desings/colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.accentColor),
      ),
    );
  }
}
