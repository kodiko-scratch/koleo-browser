import 'package:flutter/material.dart';
import '../../services/security_system.dart';
import '../theme/theme.dart';

/// Полноэкранное предупреждение о безопасности с размытым фоном
class SecurityWarningDialog extends StatelessWidget {
  final String url;
  final SecurityThreatType threatType;
  final String? warningMessage;
  final VoidCallback? onClose;
  final VoidCallback? onContinue;

  const SecurityWarningDialog({
    super.key,
    required this.url,
    required this.threatType,
    this.warningMessage,
    this.onClose,
    this.onContinue,
  });

  /// Shows the security warning dialog as a full-screen overlay
  static Future<bool?> show({
    required BuildContext context,
    required String url,
    required SecurityCheckResult result,
  }) {
    if (result.isSafe || result.threatType == null) {
      return Future.value(true);
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => SecurityWarningDialog(
        url: url,
        threatType: result.threatType!,
        warningMessage: result.warningMessage,
        onClose: () => Navigator.of(context).pop(false),
        onContinue: () => Navigator.of(context).pop(true),
      ),
    );
  }

  String _getThreatTitle() {
    switch (threatType) {
      case SecurityThreatType.malware:
        return 'Обнаружено вредоносное ПО';
      case SecurityThreatType.phishing:
        return 'Подозрение на фишинг';
      case SecurityThreatType.unwantedSoftware:
        return 'Нежелательное программное обеспечение';
      case SecurityThreatType.socialEngineering:
        return 'Социальная инженерия';
    }
  }

  IconData _getThreatIcon() {
    switch (threatType) {
      case SecurityThreatType.malware:
        return Icons.bug_report_rounded;
      case SecurityThreatType.phishing:
        return Icons.phishing_rounded;
      case SecurityThreatType.unwantedSoftware:
        return Icons.warning_amber_rounded;
      case SecurityThreatType.socialEngineering:
        return Icons.psychology_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? KoleoColors.darkSurfaceTransparent95
        : KoleoColors.lightSurfaceTransparent95;
    final textColor = isDark ? KoleoColors.darkText : KoleoColors.lightText;
    final secondaryColor =
        isDark ? KoleoColors.darkTextSecondary : KoleoColors.lightTextSecondary;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Blurred background overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: KoleoTheme.blurFilter(KoleoTheme.dialogBlur),
              child: Container(
                color: KoleoColors.overlayLight,
              ),
            ),
          ),
          // Dialog content
          Center(
            child: AnimatedContainer(
              duration: KoleoTheme.elementAppear,
              curve: KoleoTheme.elementAppearCurve,
              constraints: const BoxConstraints(maxWidth: 480),
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warning icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: KoleoColors.danger.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getThreatIcon(),
                      size: 36,
                      color: KoleoColors.danger,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Этот сайт может быть опасен',
                    style: KoleoTypography.headline.copyWith(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Threat type
                  Text(
                    _getThreatTitle(),
                    style: KoleoTypography.body.copyWith(
                      color: KoleoColors.danger,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Warning message
                  Text(
                    warningMessage ?? 'Посещение этого сайта может быть небезопасным.',
                    style: KoleoTypography.body.copyWith(color: secondaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // URL display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? KoleoColors.darkBackground
                          : KoleoColors.lightBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      url,
                      style: KoleoTypography.caption.copyWith(
                        color: secondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Action buttons
                  Row(
                    children: [
                      // Close site button (primary action)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? KoleoColors.darkAccent
                                : KoleoColors.lightAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Закрыть сайт',
                            style: KoleoTypography.button,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Continue button (secondary action)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onContinue,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: secondaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: secondaryColor.withOpacity(0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Продолжить',
                            style: KoleoTypography.button.copyWith(
                              color: secondaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
