import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.welcomeText,
    this.supportingText,
    this.headerLabel,
    this.visualRefresh = false,
    this.maxWidth = 480,
    this.headerHeight,
    this.headerIconSize,
    this.headerTitleSpacing,
    this.titleFormSpacing,
    this.cardPadding,
    this.darkDecorativeBackground = false,
    this.showTitle = true,
    this.scrollBottomPadding,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? welcomeText;
  final String? supportingText;
  final String? headerLabel;
  final bool visualRefresh;
  final double maxWidth;
  final double? headerHeight;
  final double? headerIconSize;
  final double? headerTitleSpacing;
  final double? titleFormSpacing;
  final EdgeInsetsGeometry? cardPadding;
  final bool darkDecorativeBackground;
  final bool showTitle;
  final double? scrollBottomPadding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding =
        (scrollBottomPadding ?? (visualRefresh ? 32.0 : 28.0)) + bottomSafeArea;
    final headerRadius = visualRefresh
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          )
        : BorderRadius.circular(20);

    final content = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minContentHeight = constraints.maxHeight - 28 - bottomPadding;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 28, 20, bottomPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minContentHeight > 0 ? minContentHeight : 0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: headerRadius,
                          child: BackdropFilter(
                            filter: darkDecorativeBackground
                                ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                            child: Container(
                              width: visualRefresh ? double.infinity : 64,
                              height:
                                  headerHeight ?? (visualRefresh ? 110 : 64),
                              decoration: BoxDecoration(
                                color: darkDecorativeBackground
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                gradient:
                                    !darkDecorativeBackground && visualRefresh
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                          AppColors.secondary.withValues(
                                            alpha: 0.15,
                                          ),
                                        ],
                                      )
                                    : null,
                                borderRadius: darkDecorativeBackground
                                    ? null
                                    : headerRadius,
                                border: darkDecorativeBackground
                                    ? Border(
                                        bottom: BorderSide(
                                          color: AppColors.border,
                                          width: 1,
                                        ),
                                      )
                                    : null,
                                boxShadow: visualRefresh
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: headerLabel == null
                                  ? Icon(
                                      Icons.medication_liquid_outlined,
                                      color: darkDecorativeBackground
                                          ? AppColors.primary
                                          : visualRefresh
                                          ? AppColors.primary
                                          : AppColors.primary,
                                      size:
                                          headerIconSize ??
                                          (visualRefresh ? 44 : 34),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.medication_liquid_outlined,
                                          color: darkDecorativeBackground
                                              ? AppColors.primary
                                              : AppColors.primary,
                                          size:
                                              headerIconSize ??
                                              (visualRefresh ? 38 : 34),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          headerLabel!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: darkDecorativeBackground
                                                ? AppColors.textPrimary
                                                : AppColors.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            shadows: !darkDecorativeBackground
                                                ? const [
                                                    Shadow(
                                                      color: Color(0x660F172A),
                                                      blurRadius: 6,
                                                      offset: Offset(0, 1),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: headerTitleSpacing ?? 28),
                      if (welcomeText != null) ...[
                        Text(
                          welcomeText!,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            color: darkDecorativeBackground
                                ? AppColors.textPrimary
                                : AppColors.textPrimary,
                            fontSize: darkDecorativeBackground
                                ? 26
                                : visualRefresh
                                ? 28
                                : null,
                            fontWeight: darkDecorativeBackground
                                ? FontWeight.w700
                                : FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: showTitle ? 6 : 10),
                      ],
                      if (showTitle) ...[
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            color: welcomeText != null
                                ? darkDecorativeBackground
                                      ? AppColors.textSecondary
                                      : AppColors.textSecondary
                                : darkDecorativeBackground
                                ? AppColors.textPrimary
                                : visualRefresh
                                ? AppColors.textPrimary
                                : AppColors.textPrimary,
                            fontSize: welcomeText != null
                                ? 18
                                : visualRefresh
                                ? 26
                                : null,
                            fontWeight: visualRefresh
                                ? FontWeight.w700
                                : FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: visualRefresh
                              ? darkDecorativeBackground
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondary
                              : AppColors.textSecondary,
                          fontSize: visualRefresh ? 14 : null,
                          fontWeight: visualRefresh
                              ? FontWeight.w500
                              : FontWeight.normal,
                          height: 1.4,
                        ),
                      ),
                      if (supportingText != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          supportingText!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: darkDecorativeBackground
                                ? AppColors.textSecondary
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                      SizedBox(
                        height: titleFormSpacing ?? (visualRefresh ? 24 : 28),
                      ),
                      visualRefresh
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: darkDecorativeBackground
                                    ? ImageFilter.blur(sigmaX: 18, sigmaY: 18)
                                    : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: darkDecorativeBackground
                                        ? AppColors.surface
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: darkDecorativeBackground
                                        ? Border.all(
                                            color: AppColors.border,
                                            width: 1,
                                          )
                                        : visualRefresh
                                        ? Border.all(
                                            color: AppColors.border,
                                            width: 1,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: darkDecorativeBackground
                                            ? Colors.black.withValues(
                                                alpha: 0.08,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                        blurRadius: darkDecorativeBackground
                                            ? 16
                                            : 16,
                                        spreadRadius: 0,
                                        offset: darkDecorativeBackground
                                            ? const Offset(0, 6)
                                            : const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  padding:
                                      cardPadding ??
                                      const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 20,
                                      ),
                                  child: child,
                                ),
                              ),
                            )
                          : Card(
                              elevation: 0,
                              color: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: child,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    return Scaffold(
      body: darkDecorativeBackground
          ? Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(color: AppColors.background),
              child: Stack(children: [content]),
            )
          : visualRefresh
          ? Container(
              decoration: const BoxDecoration(color: AppColors.background),
              child: content,
            )
          : content,
    );
  }
}
