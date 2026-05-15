import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.visualRefresh = false,
    this.maxWidth = 480,
    this.headerHeight,
    this.headerIconSize,
    this.headerTitleSpacing,
    this.titleFormSpacing,
    this.cardPadding,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool visualRefresh;
  final double maxWidth;
  final double? headerHeight;
  final double? headerIconSize;
  final double? headerTitleSpacing;
  final double? titleFormSpacing;
  final EdgeInsetsGeometry? cardPadding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final bottomPadding = visualRefresh ? 32.0 : 28.0;

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
                        child: Container(
                          width: visualRefresh ? double.infinity : 64,
                          height: headerHeight ?? (visualRefresh ? 110 : 64),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: visualRefresh
                                ? const BorderRadius.only(
                                    bottomLeft: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                  )
                                : BorderRadius.circular(20),
                            boxShadow: visualRefresh
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            Icons.medication_liquid_outlined,
                            color: AppColors.primary,
                            size:
                                headerIconSize ?? (visualRefresh ? 44 : 34),
                          ),
                        ),
                      ),
                      SizedBox(height: headerTitleSpacing ?? 28),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: visualRefresh
                              ? Colors.grey.shade800
                              : AppColors.textPrimary,
                          fontSize: visualRefresh ? 26 : null,
                          fontWeight: visualRefresh
                              ? FontWeight.w700
                              : FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: visualRefresh
                              ? Colors.grey.shade500
                              : AppColors.textSecondary,
                          fontSize: visualRefresh ? 14 : null,
                          fontWeight: visualRefresh
                              ? FontWeight.w400
                              : FontWeight.normal,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(
                        height: titleFormSpacing ?? (visualRefresh ? 24 : 28),
                      ),
                      visualRefresh
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 6),
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
      body: visualRefresh
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
              ),
              child: content,
            )
          : content,
    );
  }
}
