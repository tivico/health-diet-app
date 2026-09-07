/// App 的視覺設計系統：色盤、主題、以及各元件的統一樣式。
///
/// 設計概念是「新鮮蔬果」——葉綠當主色，柑橘 / 莓果 / 藍莓當點綴，
/// 讓飲控這件事看起來有活力，而不是一份冷冰冰的表格。
///
/// 畫面用色一律走 [AppPalette]（`Theme.of(context).palette`），
/// 不要直接抓 [AppColors]：前者會依深 / 淺色模式調整，後者只是原始色票。
library;

import 'package:flutter/material.dart';

import 'domain/meal_type.dart';

/// 原始品牌色票。深淺色模式的實際用色請看 [AppPalette]。
abstract final class AppColors {
  static const leaf = Color(0xFF12A87A); // 主色：葉綠
  static const sprout = Color(0xFF3ED598); // 嫩芽綠（漸層亮端）
  static const teal = Color(0xFF0C8C84); // 湖水綠（漸層暗端）
  static const citrus = Color(0xFFFF8A3D); // 柑橘：早餐 / 提醒
  static const berry = Color(0xFFF4557E); // 莓果：蛋白質 / 點心
  static const grain = Color(0xFFF2B035); // 穀物黃：脂肪
  static const blueberry = Color(0xFF5A7BFF); // 藍莓：碳水
  static const plum = Color(0xFF7C6BF0); // 夜紫：晚餐

  /// 頁面底色（淺色帶一點綠、深色偏墨綠，避免純白 / 純黑的死板）。
  static const lightBackground = Color(0xFFF4F7F3);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkBackground = Color(0xFF0E1512);
  static const darkSurface = Color(0xFF19211D);
}

/// 語意化用色：三大營養素、餐別、狀態色與漸層。
///
/// 放在 [ThemeExtension] 裡而不是散在各畫面，深 / 淺色才有單一調整處。
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// 三大營養素：蛋白＝莓果紅、脂肪＝穀物黃、碳水＝藍莓藍。
  final Color protein;
  final Color fat;
  final Color carbs;

  /// 狀態色。「超標」沿用 ColorScheme.error，這裡只補達標與提醒。
  final Color success;
  final Color warning;

  /// 熱量主卡的漸層（正常 / 超出目標）。
  final List<Color> heroGradient;
  final List<Color> heroOverGradient;

  /// 體重目標卡的漸層。刻意跟熱量卡不同色系，兩個分頁才不會長得一樣。
  final List<Color> weightGradient;

  /// 卡片陰影色（淺色模式才看得出來，深色幾乎透明）。
  final Color shadow;

  /// 卡片與頁面底色（Card / Scaffold 用同一組，元件才不會各自為政）。
  final Color surface;
  final Color background;

  /// 餐別用色：早餐日出橘、午餐葉綠、晚餐夜紫、點心莓果、未分類灰。
  final Color breakfast;
  final Color lunch;
  final Color dinner;
  final Color snack;
  final Color uncategorized;

  const AppPalette({
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.success,
    required this.warning,
    required this.heroGradient,
    required this.heroOverGradient,
    required this.weightGradient,
    required this.shadow,
    required this.surface,
    required this.background,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
    required this.uncategorized,
  });

  /// 餐別對應色；`null`（舊資料）為未分類灰。
  Color mealColor(MealType? type) => switch (type) {
        MealType.breakfast => breakfast,
        MealType.lunch => lunch,
        MealType.dinner => dinner,
        MealType.snack => snack,
        null => uncategorized,
      };

  static const light = AppPalette(
    protein: AppColors.berry,
    fat: Color(0xFFE09A16), // 淺底上的黃要壓深一點才看得清楚
    carbs: AppColors.blueberry,
    success: AppColors.leaf,
    warning: Color(0xFFE07A28),
    heroGradient: [Color(0xFF2FCF95), AppColors.leaf, AppColors.teal],
    heroOverGradient: [Color(0xFFFFA25C), Color(0xFFF4694F), Color(0xFFE8456C)],
    weightGradient: [Color(0xFF6E8BFF), Color(0xFF7C6BF0)],
    shadow: Color(0x14184D3C),
    surface: AppColors.lightSurface,
    background: AppColors.lightBackground,
    breakfast: AppColors.citrus,
    lunch: AppColors.leaf,
    dinner: AppColors.plum,
    snack: AppColors.berry,
    uncategorized: Color(0xFF8A9691),
  );

  static const dark = AppPalette(
    protein: Color(0xFFFF7FA0),
    fat: Color(0xFFF6C453),
    carbs: Color(0xFF8AA0FF),
    success: Color(0xFF3ED598),
    warning: Color(0xFFFFA05C),
    heroGradient: [Color(0xFF17A87C), Color(0xFF0E8B72), Color(0xFF0A6E6E)],
    heroOverGradient: [Color(0xFFE0854A), Color(0xFFCF5A48), Color(0xFFC03C5E)],
    weightGradient: [Color(0xFF4B63C9), Color(0xFF5B4FC0)],
    shadow: Color(0x33000000),
    surface: AppColors.darkSurface,
    background: AppColors.darkBackground,
    breakfast: Color(0xFFFFA463),
    lunch: Color(0xFF3ED598),
    dinner: Color(0xFF9B8DFF),
    snack: Color(0xFFFF7FA0),
    uncategorized: Color(0xFF8A9691),
  );

  @override
  AppPalette copyWith({
    Color? protein,
    Color? fat,
    Color? carbs,
    Color? success,
    Color? warning,
    List<Color>? heroGradient,
    List<Color>? heroOverGradient,
    List<Color>? weightGradient,
    Color? shadow,
    Color? surface,
    Color? background,
    Color? breakfast,
    Color? lunch,
    Color? dinner,
    Color? snack,
    Color? uncategorized,
  }) {
    return AppPalette(
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      heroGradient: heroGradient ?? this.heroGradient,
      heroOverGradient: heroOverGradient ?? this.heroOverGradient,
      weightGradient: weightGradient ?? this.weightGradient,
      shadow: shadow ?? this.shadow,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      snack: snack ?? this.snack,
      uncategorized: uncategorized ?? this.uncategorized,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      protein: Color.lerp(protein, other.protein, t)!,
      fat: Color.lerp(fat, other.fat, t)!,
      carbs: Color.lerp(carbs, other.carbs, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      heroGradient: _lerpColors(heroGradient, other.heroGradient, t),
      heroOverGradient:
          _lerpColors(heroOverGradient, other.heroOverGradient, t),
      weightGradient: _lerpColors(weightGradient, other.weightGradient, t),
      shadow: Color.lerp(shadow, other.shadow, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      background: Color.lerp(background, other.background, t)!,
      breakfast: Color.lerp(breakfast, other.breakfast, t)!,
      lunch: Color.lerp(lunch, other.lunch, t)!,
      dinner: Color.lerp(dinner, other.dinner, t)!,
      snack: Color.lerp(snack, other.snack, t)!,
      uncategorized: Color.lerp(uncategorized, other.uncategorized, t)!,
    );
  }

  static List<Color> _lerpColors(List<Color> a, List<Color> b, double t) => [
        for (var i = 0; i < a.length; i++) Color.lerp(a[i], b[i], t)!,
      ];
}

/// 讓畫面能寫 `theme.palette.protein`，而不是每次都 `extension<AppPalette>()!`。
extension AppPaletteAccess on ThemeData {
  AppPalette get palette =>
      extension<AppPalette>() ??
      (brightness == Brightness.dark ? AppPalette.dark : AppPalette.light);
}

/// 餐別圖示：早餐日出、午餐太陽、晚餐月亮、點心餅乾。
IconData mealTypeIcon(MealType? type) => switch (type) {
      MealType.breakfast => Icons.wb_twilight,
      MealType.lunch => Icons.wb_sunny_outlined,
      MealType.dinner => Icons.nightlight_outlined,
      MealType.snack => Icons.cookie_outlined,
      null => Icons.restaurant_outlined,
    };

/// 全 App 通用的圓角尺度（卡片 20、輸入框與小元件 14）。
abstract final class AppRadius {
  static const card = 20.0;
  static const field = 14.0;
  static const chip = 12.0;
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;

    // vibrant 變體會讓次要色更飽和，整體比預設的 tonalSpot 更有生氣。
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.leaf,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    ).copyWith(surface: palette.surface);

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = base.textTheme;

    return base.copyWith(
      scaffoldBackgroundColor: palette.background,
      // 標題偏粗一點，中文字重才拉得開層次。
      textTheme: text.copyWith(
        headlineMedium:
            text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        headlineSmall:
            text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero, // 間距一律由外層自己給，才不會東多一塊西少一塊
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: palette.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHigh : palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _fieldBorder(scheme.outlineVariant),
        enabledBorder: _fieldBorder(scheme.outlineVariant),
        focusedBorder: _fieldBorder(scheme.primary, width: 2),
        errorBorder: _fieldBorder(scheme.error),
        focusedErrorBorder: _fieldBorder(scheme.error, width: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        extendedTextStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.24 : 0.14),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle:
            text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: Colors.transparent,
      ),
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide(color: color, width: width),
      );
}
