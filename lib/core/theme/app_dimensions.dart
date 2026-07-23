/// Spacing, sizing, and dimension constants for the Wrenta application.
/// 
/// Provides consistent measurements throughout the app for spacing,
/// border radius, icon sizes, and component dimensions.
class AppDimensions {
  AppDimensions._();

  // ============ SPACING SCALE ============
  
  /// Extra small spacing - 4px
  static const double spacingXs = 4.0;
  
  /// Small spacing - 8px
  static const double spacingSm = 8.0;
  
  /// Medium spacing - 12px
  static const double spacingMd = 12.0;
  
  /// Large spacing - 16px
  static const double spacingLg = 16.0;
    static const double spaceLg  = 20.0;
  /// Extra large spacing - 20px
  static const double spacingXl = 20.0;

  static const double spacingXxl = 32.0;
  
  /// 2X large spacing - 24px
  static const double spacing2xl = 24.0;
  
  /// 3X large spacing - 32px
  static const double spacing3xl = 32.0;
  
  /// 4X large spacing - 40px
  static const double spacing4xl = 40.0;
  
  /// 5X large spacing - 48px
  static const double spacing5xl = 48.0;
  
  /// 6X large spacing - 64px
  static const double spacing6xl = 64.0;

  // ============ BORDER RADIUS ============
  
  /// Extra small radius - 4px
  static const double radiusXs = 4.0;
  
  /// Small radius - 8px
  static const double radiusSm = 8.0;
  
  /// Medium radius - 12px
  static const double radiusMd = 12.0;
  
  /// Large radius - 16px (Default for cards/buttons)
  static const double radiusLg = 16.0;
  
  /// Extra large radius - 20px
  static const double radiusXl = 20.0;
  
  /// 2X large radius - 24px
  static const double radius2xl = 24.0;
  
  /// Full/pill radius - 999px
  static const double radiusFull = 999.0;

  // ============ ICON SIZES ============
  
  /// Extra small icon - 16px
  static const double iconXs = 16.0;
  
  /// Small icon - 20px
  static const double iconSm = 20.0;
  
  /// Medium icon - 24px (Default)
  static const double iconMd = 24.0;
  
  /// Large icon - 28px
  static const double iconLg = 28.0;
  
  /// Extra large icon - 32px
  static const double iconXl = 32.0;
  
  /// 2X large icon - 40px
  static const double icon2xl = 40.0;

  // ============ BUTTON DIMENSIONS ============
  
  /// Small button height - 40px
  static const double buttonHeightSm = 40.0;
  
  /// Medium button height - 48px
  static const double buttonHeightMd = 48.0;
  
  /// Large button height - 56px (Default)
  static const double buttonHeightLg = 56.0;
  
  /// Extra large button height - 64px
  static const double buttonHeightXl = 64.0;
  
  /// Button horizontal padding
  static const double buttonPaddingH = 24.0;
  
  /// Button vertical padding
  static const double buttonPaddingV = 16.0;

  // ============ AVATAR SIZES ============
  
  /// Extra small avatar - 24px
  static const double avatarXs = 24.0;
  
  /// Small avatar - 32px
  static const double avatarSm = 32.0;
  
  /// Medium avatar - 48px
  static const double avatarMd = 48.0;
  
  /// Large avatar - 64px (Default)
  static const double avatarLg = 64.0;
  
  /// Extra large avatar - 80px
  static const double avatarXl = 80.0;
  
  /// 2X large avatar - 100px
  static const double avatar2xl = 100.0;
  
  /// 3X large avatar - 140px (Profile)
  static const double avatar3xl = 140.0;

  // ============ CARD DIMENSIONS ============
  
  /// Small card padding - 12px
  static const double cardPaddingSm = 12.0;
  
  /// Medium card padding - 16px
  static const double cardPaddingMd = 16.0;
  
  /// Large card padding - 20px (Default)
  static const double cardPaddingLg = 20.0;
  
  /// Extra large card padding - 24px
  static const double cardPaddingXl = 24.0;
  
  /// Card elevation
  static const double cardElevation = 0.0;
  
  /// Card margin
  static const double cardMargin = 12.0;

  // ============ INPUT DIMENSIONS ============
  
  /// Input field height - 56px
  static const double inputHeight = 56.0;
  
  /// Input field padding horizontal
  static const double inputPaddingH = 16.0;
  
  /// Input field padding vertical
  static const double inputPaddingV = 16.0;
  
  /// Input field border width
  static const double inputBorderWidth = 1.0;

  // ============ DIVIDER DIMENSIONS ============
  
  /// Thin divider - 1px
  static const double dividerThin = 1.0;
  
  /// Medium divider - 2px
  static const double dividerMedium = 2.0;
  
  /// Thick divider - 4px
  static const double dividerThick = 4.0;

  // ============ BORDER WIDTHS ============
  
  /// Thin border - 1px (Default)
  static const double borderThin = 1.0;
  
  /// Medium border - 2px
  static const double borderMedium = 2.0;
  
  /// Thick border - 3px
  static const double borderThick = 3.0;

  // ============ APPBAR DIMENSIONS ============
  
  /// AppBar height (uses default kToolbarHeight = 56.0)
  static const double appBarHeight = 56.0;
  
  /// AppBar icon size
  static const double appBarIconSize = 24.0;

  // ============ BOTTOM NAV BAR ============
  
  /// Bottom navigation bar height
  static const double bottomNavHeight = 60.0;
  
  /// Bottom navigation bar icon size
  static const double bottomNavIconSize = 24.0;

  // ============ PROGRESS INDICATORS ============
  
  /// Small progress indicator - 16px
  static const double progressSm = 16.0;
  
  /// Medium progress indicator - 24px
  static const double progressMd = 24.0;
  
  /// Large progress indicator - 32px
  static const double progressLg = 32.0;
  
  /// Progress indicator stroke width
  static const double progressStrokeWidth = 2.0;

  // ============ BADGE DIMENSIONS ============
  
  /// Badge size - 8px
  static const double badgeSm = 8.0;
  
  /// Medium badge size - 16px
  static const double badgeMd = 16.0;
  
  /// Large badge size - 20px
  static const double badgeLg = 20.0;

  // ============ MODAL/SHEET DIMENSIONS ============
  
  /// Bottom sheet handle width
  static const double sheetHandleWidth = 40.0;
  
  /// Bottom sheet handle height
  static const double sheetHandleHeight = 4.0;
  
  /// Dialog border radius
  static const double dialogRadius = 20.0;
  
  /// Dialog padding
  static const double dialogPadding = 24.0;

  // ============ LIST ITEM DIMENSIONS ============
  
  /// Small list item height - 48px
  static const double listItemSm = 48.0;
  
  /// Medium list item height - 56px
  static const double listItemMd = 56.0;
  
  /// Large list item height - 72px
  static const double listItemLg = 72.0;


  static const double pagePaddingH = 20.0;
  static const double pagePaddingV = 20.0;
}