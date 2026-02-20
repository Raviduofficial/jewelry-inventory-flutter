import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF00796B); 
  static const Color _errorColor = Color(0xFFD32F2F);
  
  static const double _borderRadius = 16.0;
  static const double _inputBorderRadius = 14.0;
  static const double _buttonBorderRadius = 12.0;
  static const double _elevation = 2.0;
  static const EdgeInsets _cardMargin = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  static const EdgeInsets _inputPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  static const _lightSurface = Color(0xFFFAFAFA);
  static const _lightInputFill = Color(0xFFF8F9FA);
  static const _lightCardColor = Colors.white;

  static const _darkSurface = Color(0xFF0F0F0F);
  static const _darkCardColor = Color(0xFF1C1C1C);
  static const _darkInputFill = Color(0xFF1A1A1A);
  static const _darkBorder = Color(0xFF2C2C2C);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      error: _errorColor,
    ).copyWith(
      surface: _lightSurface,
      surfaceContainerHighest: _lightCardColor,
    ),
    
    textTheme: _buildTextTheme(Brightness.light),
    
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.transparent,
      foregroundColor: _seedColor,
      titleTextStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _seedColor,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    cardTheme: CardThemeData(
      color: _lightCardColor,
      elevation: _elevation,
      shadowColor: Colors.black.withOpacity(0.08),
      surfaceTintColor: _seedColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      margin: _cardMargin,
      clipBehavior: Clip.antiAlias,
    ),

    // Modern Input Fields
    inputDecorationTheme: _buildInputTheme(
      fillColor: _lightInputFill,
      borderColor: Colors.grey.shade300,
      focusColor: _seedColor,
      labelColor: Colors.grey.shade700,
      hintColor: Colors.grey.shade500,
    ),

    // Modern Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _seedColor,
        foregroundColor: Colors.white,
        elevation: _elevation,
        padding: _buttonPadding,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: _buttonPadding,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: _buttonPadding,
        minimumSize: const Size(0, 48),
        side: BorderSide(color: _seedColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
      ),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _seedColor,
      foregroundColor: Colors.white,
      elevation: 6,
      focusElevation: 8,
      hoverElevation: 8,
    ),

    // Modern Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: _lightCardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // Bottom Sheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _lightCardColor,
      modalBackgroundColor: _lightCardColor,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: _lightInputFill,
      selectedColor: _seedColor.withOpacity(0.2),
      deleteIconColor: Colors.grey.shade600,
      labelStyle: TextStyle(color: Colors.grey.shade800),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    ),
  );

  // --- DARK THEME ---
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      error: _errorColor,
    ).copyWith(
      surface: _darkSurface,
      surfaceContainerHighest: _darkCardColor,
      outline: _darkBorder,
    ),

    // Dark Typography
    textTheme: _buildTextTheme(Brightness.dark),
    
    scaffoldBackgroundColor: _darkSurface,

    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.tealAccent.shade200,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.tealAccent.shade200,
      ),
    ),

    cardTheme: CardThemeData(
      color: _darkCardColor,
      elevation: 0,
      surfaceTintColor: Colors.tealAccent.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: BorderSide(color: _darkBorder, width: 1),
      ),
      margin: _cardMargin,
      clipBehavior: Clip.antiAlias,
    ),

    inputDecorationTheme: _buildInputTheme(
      fillColor: _darkInputFill,
      borderColor: _darkBorder,
      focusColor: Colors.tealAccent.shade200,
      labelColor: Colors.grey.shade400,
      hintColor: Colors.grey.shade600,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.tealAccent.shade700,
        foregroundColor: Colors.black87,
        elevation: _elevation,
        padding: _buttonPadding,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: _buttonPadding,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: _buttonPadding,
        minimumSize: const Size(0, 48),
        side: BorderSide(color: Colors.tealAccent.shade200, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
      ),
    ),
    
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.tealAccent.shade700,
      foregroundColor: Colors.black87,
      elevation: 6,
      focusElevation: 8,
      hoverElevation: 8,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: _darkCardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _darkCardColor,
      modalBackgroundColor: _darkCardColor,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: _darkInputFill,
      selectedColor: Colors.tealAccent.withOpacity(0.2),
      deleteIconColor: Colors.grey.shade500,
      labelStyle: TextStyle(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    ),
  );

  // Helper Methods
  static InputDecorationTheme _buildInputTheme({
    required Color fillColor,
    required Color borderColor,
    required Color focusColor,
    required Color labelColor,
    required Color hintColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: _inputPadding,
      
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        borderSide: BorderSide(color: focusColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        borderSide: const BorderSide(color: _errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        borderSide: const BorderSide(color: _errorColor, width: 2),
      ),
      labelStyle: TextStyle(
        color: labelColor,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      hintStyle: TextStyle(
        color: hintColor,
        fontSize: 16,
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.light 
        ? Colors.black87 
        : Colors.white70;
    
    return TextTheme(
      displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.w300),
      displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.w400),
      displaySmall: TextStyle(color: textColor, fontWeight: FontWeight.w400),
      headlineLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: textColor, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(color: textColor, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(color: textColor, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: textColor, fontWeight: FontWeight.w500),
    );
  }
}

// Optional: Theme Extension for custom properties
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.success,
    required this.warning,
    required this.info,
  });

  final Color success;
  final Color warning;
  final Color info;

  @override
  CustomColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return CustomColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }

  static const light = CustomColors(
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFF9800),
    info: Color(0xFF2196F3),
  );

  static const dark = CustomColors(
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFB74D),
    info: Color(0xFF42A5F5),
  );
}
