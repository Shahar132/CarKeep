import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ==========================================================
  // Main app colors
  // ==========================================================

  static const Color primary =
      Color(0xFF234E70);

  static const Color primaryLight =
      Color(0xFFE7EFF6);

  static const Color background =
      Color(0xFFF6F7F9);

  // Regular cards / surfaces
  static const Color surface =
      Color(0xFFFAFCFE);

  // Regular card borders
  static const Color border =
      Color(0xFFCBD8E3);

  // ==========================================================
  // Interactive / clickable cards
  // ==========================================================

  // Background for clickable cards
  static const Color interactiveSurface =
      Color(0xFFEAF2F8);

  // Border for clickable cards
  static const Color interactiveBorder =
      Color(0xFFB8CCDC);

  // Background behind icons in clickable cards
  static const Color iconBackground =
      Color(0xFFDCEAF4);

  static const Color textPrimary =
      Color(0xFF1F2933);

  static const Color textSecondary =
      Color(0xFF697386);

  // ==========================================================
  // Status colors
  // ==========================================================

  static const Color success =
      Color(0xFF2E7D32);

  static const Color warning =
      Color(0xFFF59E0B);

  static const Color danger =
      Color(0xFFC62828);

  // ==========================================================
  // Light theme
  // ==========================================================

  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      surface: surface,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,

      colorScheme: colorScheme,

      scaffoldBackgroundColor:
          background,

      // ======================================================
      // AppBar
      // ======================================================

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor:
            Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 21,
          fontWeight:
              FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: textPrimary,
        ),
      ),

      // ======================================================
      // Regular cards
      // ======================================================

      cardTheme: CardThemeData(
        color: surface,
        elevation: 3,

        shadowColor:
            const Color(0x1A234E70),

        surfaceTintColor:
            Colors.transparent,

        margin: EdgeInsets.zero,

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
          side: const BorderSide(
            color: border,
            width: 1.1,
          ),
        ),
      ),

      // ======================================================
      // Elevated buttons
      // ======================================================

      elevatedButtonTheme:
          ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor:
              Colors.white,

          elevation: 1,

          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),

          side: const BorderSide(
            color: primary,
          ),

          textStyle:
              const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),

      // ======================================================
      // Outlined buttons
      // ======================================================

      outlinedButtonTheme:
          OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          backgroundColor: surface,

          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),

          side: const BorderSide(
            color: border,
            width: 1.2,
          ),

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),

          textStyle:
              const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),

      // ======================================================
      // Text buttons
      // ======================================================

      textButtonTheme:
          TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          backgroundColor: surface,

          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(10),

            side: const BorderSide(
              color: border,
            ),
          ),

          textStyle:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),

      // ======================================================
      // Floating action buttons
      // ======================================================

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor:
            Colors.white,
        elevation: 3,
      ),

      // ======================================================
      // Input fields
      // ======================================================

      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,

        fillColor: surface,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              const BorderSide(
            color: border,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              const BorderSide(
            color: border,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              const BorderSide(
            color: primary,
            width: 1.7,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              const BorderSide(
            color: danger,
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              const BorderSide(
            color: danger,
            width: 1.7,
          ),
        ),

        labelStyle:
            const TextStyle(
          color: textSecondary,
        ),

        hintStyle:
            const TextStyle(
          color: textSecondary,
        ),
      ),

      // ======================================================
      // List tiles
      // ======================================================

      listTileTheme:
          const ListTileThemeData(
        iconColor: primary,
        textColor: textPrimary,

        contentPadding:
            EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
      ),

      // ======================================================
      // Bottom navigation
      // ======================================================

      navigationBarTheme:
          NavigationBarThemeData(
        backgroundColor: surface,

        elevation: 4,

        indicatorColor:
            primaryLight,

        labelTextStyle:
            WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return const TextStyle(
                color: primary,
                fontWeight:
                    FontWeight.w600,
              );
            }

            return const TextStyle(
              color: textSecondary,
            );
          },
        ),

        iconTheme:
            WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(
              WidgetState.selected,
            )) {
              return const IconThemeData(
                color: primary,
              );
            }

            return const IconThemeData(
              color: textSecondary,
            );
          },
        ),
      ),

      // ======================================================
      // Dividers
      // ======================================================

      dividerTheme:
          const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // ======================================================
      // Dialogs
      // ======================================================

      dialogTheme: DialogThemeData(
        backgroundColor: surface,

        surfaceTintColor:
            Colors.transparent,

        elevation: 5,

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(18),

          side: const BorderSide(
            color: border,
          ),
        ),
      ),

      // ======================================================
      // SnackBars
      // ======================================================

      snackBarTheme:
          SnackBarThemeData(
        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            textPrimary,

        contentTextStyle:
            const TextStyle(
          color: Colors.white,
        ),

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),

      // ======================================================
      // General text
      // ======================================================

      textTheme:
          const TextTheme(
        headlineSmall: TextStyle(
          color: textPrimary,
          fontWeight:
              FontWeight.bold,
        ),

        titleLarge: TextStyle(
          color: textPrimary,
          fontWeight:
              FontWeight.w600,
        ),

        titleMedium: TextStyle(
          color: textPrimary,
          fontWeight:
              FontWeight.w600,
        ),

        bodyLarge: TextStyle(
          color: textPrimary,
        ),

        bodyMedium: TextStyle(
          color: textPrimary,
        ),

        bodySmall: TextStyle(
          color: textSecondary,
        ),
      ),
    );
  }
}