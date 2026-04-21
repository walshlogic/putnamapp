import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class AppFooter extends StatefulWidget {
  const AppFooter({super.key});

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Align first tick to the next whole second, then tick every second.
    final int msToNextSecond = 1000 - _now.millisecond;
    _timer = Timer(Duration(milliseconds: msToNextSecond), _startTicking);
  }

  void _startTicking() {
    if (!mounted) return;
    setState(() => _now = DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final FooterStyles safeStyles =
        Theme.of(context).extension<FooterStyles>() ??
            const FooterStyles(fontSize: 12, opacity: 0.4);

    final String formatted =
        DateFormat("EEEE h:mm:ssa").format(_now).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          formatted,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: safeStyles.fontSize,
            color: appColors.primaryPurple
                .withValues(alpha: safeStyles.opacity),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
