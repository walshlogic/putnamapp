import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final FooterStyles? styles = Theme.of(context).extension<FooterStyles>();
    final FooterStyles safeStyles = styles ?? const FooterStyles(
      fontSize: 12,
      opacity: 0.4,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: GestureDetector(
          onTap: () => context.push('/about'),
          child: Text(
            'walsh+logic',
            style: TextStyle(
              fontSize: safeStyles.fontSize,
              color: appColors.primaryPurple.withValues(alpha: safeStyles.opacity),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}


