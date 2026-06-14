import 'package:flutter/material.dart';
import '../desings/themes.dart';
import 'home_page.dart';

class TrakioApp extends StatelessWidget {
  const TrakioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    theme: AppThemes.darkTheme,
     home: const HomePage(),
    

   );
  }
}