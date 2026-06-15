import 'package:flutter/material.dart';
import '../desings/colors.dart';

class SocialDivider extends StatelessWidget {
  const SocialDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DividerLine(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'o continúa con',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 13,
            ),
          ),
        ),
        _DividerLine(),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Divider(
        color: AppColors.borderColor,
        thickness: 1,
      ),
    );
  }
}
