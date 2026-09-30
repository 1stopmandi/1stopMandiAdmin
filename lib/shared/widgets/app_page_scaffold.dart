import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

/// A standard page scaffold used across all screens in the app.
///
/// Ensures:
/// - Consistent background color (`AppColors.background`)
/// - Proper [SafeArea] handling so content never collides with the phone's
///   status bar, camera notch, or system gesture/navigation bar
/// - Consistent [AppBar] typography, icons, and elevation
/// - Built-in pull-to-refresh when [onRefresh] is provided
/// - Clean sticky [bottomBar] container with soft elevation and safe area insets
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.showBackButton = true,
    this.leading,
    this.actions,
    this.appBar,
    required this.body,
    this.bottomBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.onRefresh,
    this.backgroundColor,
    this.padding = EdgeInsets.zero,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
  });

  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Future<void> Function()? onRefresh;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.background;

    PreferredSizeWidget? effectiveAppBar = appBar;

    if (effectiveAppBar == null && (title != null || showBackButton || leading != null)) {
      Widget? titleWidget;
      if (title != null) {
        titleWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      }

      effectiveAppBar = AppBar(
        automaticallyImplyLeading: false,
        leading: leading ??
            (showBackButton && context.canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: AppColors.textPrimary,
                    onPressed: () => context.pop(),
                  )
                : null),
        title: titleWidget,
        centerTitle: false,
        titleSpacing: (leading != null || (showBackButton && context.canPop())) ? 0 : 16,
        actions: actions,
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      );
    }

    Widget content = Padding(
      padding: padding,
      child: body,
    );

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        child: content,
      );
    }

    Widget? effectiveBottomBar = bottomBar;
    if (effectiveBottomBar != null) {
      effectiveBottomBar = Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: effectiveBottomBar,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: effectiveAppBar,
      body: SafeArea(
        top: effectiveAppBar == null,
        bottom: effectiveBottomBar == null,
        child: content,
      ),
      bottomNavigationBar: effectiveBottomBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
