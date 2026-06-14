import 'package:flutter/material.dart';
import 'colors.dart';

class AppThemes {
  AppThemes._(); // Constructor privado para evitar instanciación

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.appBarColor,
    scaffoldBackgroundColor: AppColors.backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.appBarColor,
      titleTextStyle: const TextStyle(
        color: AppColors.textColor,
        fontSize: 34,
        fontWeight: FontWeight.bold,
      ),
      centerTitle: true,
    ),

  );
}