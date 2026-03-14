import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      primaryColor: AppColors.accentCyan,
      colorScheme: isDark 
        ? const ColorScheme.dark(
            primary: AppColors.accentCyan,
            secondary: AppColors.accentCyan,
            background: AppColors.background,
            surface: AppColors.cardBackground,
            error: AppColors.criticalRed,
          )
        : const ColorScheme.light(
            primary: AppColors.accentCyan,
            secondary: AppColors.accentCyan,
            background: AppColors.lightBackground,
            surface: AppColors.lightCardBackground,
            error: AppColors.criticalRed,
          ),
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme
      ).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 48, 
          fontWeight: FontWeight.bold, 
          color: AppColors.accentCyan
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 32, 
          fontWeight: FontWeight.bold, 
          color: isDark ? Colors.white : AppColors.textPrimaryLight
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24, 
          fontWeight: FontWeight.w600, 
          color: isDark ? Colors.white : AppColors.textPrimaryLight
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20, 
          fontWeight: FontWeight.w600, 
          color: isDark ? Colors.white : AppColors.textPrimaryLight
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, 
          fontWeight: FontWeight.w600, 
          color: isDark ? Colors.white : AppColors.textPrimaryLight
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, 
          fontWeight: FontWeight.w500, 
          color: isDark ? Colors.white : AppColors.textPrimaryLight
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, 
          color: isDark ? Colors.white : AppColors.textPrimaryLight
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, 
          color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, 
          color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight
        ),
      ),
      cardTheme: CardTheme(
        color: isDark ? AppColors.cardBackground : AppColors.lightCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? AppColors.cardBorder : AppColors.lightCardBorder, 
            width: 1
          ),
        ),
        elevation: isDark ? 0 : 2,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, 
          fontWeight: FontWeight.w600, 
          color: isDark ? Colors.white : AppColors.textPrimaryLight
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.textPrimaryLight),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
        selectedItemColor: AppColors.accentCyan,
        unselectedItemColor: AppColors.systemGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(Colors.white),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.accentCyan;
          }
          return AppColors.systemGray;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentCyan,
        inactiveTrackColor: AppColors.systemGray,
        thumbColor: Colors.white,
        overlayColor: AppColors.accentCyan.withOpacity(0.2),
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
