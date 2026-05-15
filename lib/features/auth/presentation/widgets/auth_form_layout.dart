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
        (scrollBottomPadding ?? (visualRefresh ? 32.0 : 28.0)) +
        bottomSafeArea;
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
                                    ? const Color(0xFF06141B).withOpacity(0.74)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                gradient:
                                    !darkDecorativeBackground && visualRefresh
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF253745),
                                          Color(0xFF4A5C6A),
                                        ],
                                      )
                                    : null,
                                borderRadius: darkDecorativeBackground
                                    ? null
                                    : headerRadius,
                                border: darkDecorativeBackground
                                    ? Border(
                                        bottom: BorderSide(
                                          color: const Color(
                                            0xFF4A5C6A,
                                          ).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      )
                                    : null,
                                boxShadow: visualRefresh
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF4A5C6A,
                                          ).withOpacity(0.18),
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
                                          ? const Color(0xFFCCD0CF)
                                          : visualRefresh
                                          ? Colors.white
                                          : AppColors.primary,
                                      size: headerIconSize ??
                                          (visualRefresh ? 44 : 34),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.medication_liquid_outlined,
                                          color: darkDecorativeBackground
                                              ? const Color(0xFFCCD0CF)
                                              : Colors.white,
                                          size: headerIconSize ??
                                              (visualRefresh ? 38 : 34),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          headerLabel!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: darkDecorativeBackground
                                                ? const Color(0xFFCCD0CF)
                                                : Colors.white,
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
                                ? const Color(0xFFCCD0CF)
                                : const Color(0xFF0F172A),
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
                                      ? const Color(0xFF9BA8AB)
                                      : const Color(0xFF4A5C6A)
                                : darkDecorativeBackground
                                ? const Color(0xFFCCD0CF)
                                : visualRefresh
                                ? const Color(0xFF0F172A)
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
                                    ? const Color(0xFF9BA8AB)
                                    : const Color(0xFF334155)
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
                                ? const Color(0xFFCCD0CF)
                                : const Color(0xFF475569),
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
                                        ? const Color(
                                            0xFF11212D,
                                          ).withOpacity(0.76)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: darkDecorativeBackground
                                        ? Border.all(
                                            color: const Color(
                                              0xFFCCD0CF,
                                            ).withOpacity(0.13),
                                            width: 1,
                                          )
                                        : visualRefresh
                                        ? Border.all(
                                            color: const Color(0xFF9BA8AB),
                                            width: 1,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: darkDecorativeBackground
                                            ? Colors.black.withOpacity(0.38)
                                            : Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                        blurRadius: darkDecorativeBackground
                                            ? 36
                                            : 16,
                                        spreadRadius: 0,
                                        offset: darkDecorativeBackground
                                            ? const Offset(0, 16)
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
          ? Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF06141B),
                        Color(0xFF11212D),
                        Color(0xFF253745),
                        Color(0xFF4A5C6A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.35, 0.65, 1.0],
                    ),
                  ),
                ),
                const IgnorePointer(child: _AmbientBackground()),
                content,
              ],
            )
          : visualRefresh
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFCCD0CF),
                    Color(0xFF9BA8AB),
                    Color(0xFF4A5C6A),
                  ],
                ),
              ),
              child: content,
            )
          : content,
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned(
          top: -120,
          right: -90,
          child: _AmbientGlow(
            width: 320,
            height: 280,
            color: Color(0xFF4A5C6A),
            opacity: 0.20,
          ),
        ),
        Positioned(
          top: 210,
          left: -150,
          child: _AmbientGlow(
            width: 360,
            height: 300,
            color: Color(0xFF253745),
            opacity: 0.22,
          ),
        ),
        Positioned(
          bottom: -130,
          right: -120,
          child: _AmbientGlow(
            width: 420,
            height: 340,
            color: Color(0xFF4A5C6A),
            opacity: 0.16,
          ),
        ),
        Positioned(
          bottom: 120,
          left: 40,
          right: 40,
          child: _AmbientWash(),
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.width,
    required this.height,
    required this.color,
    required this.opacity,
  });

  final double width;
  final double height;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 54, sigmaY: 54),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(opacity * 0.42),
              Colors.transparent,
            ],
            stops: const [0.0, 0.48, 1.0],
          ),
        ),
      ),
    );
  }
}

class _AmbientWash extends StatelessWidget {
  const _AmbientWash();

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF253745).withOpacity(0.0),
              const Color(0xFF253745).withOpacity(0.18),
              const Color(0xFF4A5C6A).withOpacity(0.12),
              const Color(0xFF253745).withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}
