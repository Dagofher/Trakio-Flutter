import 'package:flutter/material.dart';
import '../desings/colors.dart';
import '../widgets/login_header.dart';
import '../widgets/login_form.dart';
import '../widgets/social_divider.dart';
import '../widgets/social_login_button.dart';
import '../widgets/login_footer.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),
              const LoginHeader(),
              const SizedBox(height: 48),
              const LoginForm(),
              const SizedBox(height: 36),
              const SocialDivider(),
              const SizedBox(height: 24),
              const SocialLoginButton(
                label: 'Continuar con Google',
                icon: Icons.g_mobiledata_rounded,
                onPressed: null, // TODO: conectar con Google Auth
              ),
              const SizedBox(height: 12),
              const SocialLoginButton(
                label: 'Continuar con GitHub',
                icon: Icons.code_rounded,
                onPressed: null, // TODO: conectar con GitHub Auth
              ),
              const SizedBox(height: 48),
              const LoginFooter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}