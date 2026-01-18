import 'package:flutter/material.dart';

import '../../extensions/build_context_extensions.dart';

/// Government card for home screen
class GovernmentCard extends StatelessWidget {
  const GovernmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final cardTextStyles = context.cardTextStyles;

    return SizedBox(
      height: 140,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                appColors.accentTeal,
                appColors.accentTealDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: <Widget>[
              // Main content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Icon
                    Icon(
                      Icons.account_balance,
                      size: 32,
                      color: appColors.white,
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      'GOVERNMENT',
                      style: TextStyle(
                        fontSize: cardTextStyles.cardTitleSize * 0.75,
                        fontWeight: FontWeight.bold,
                        color: appColors.white,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

