import 'package:flutter/material.dart';

import '../../extensions/build_context_extensions.dart';

/// Directory card for home screen
class DirectoryCard extends StatelessWidget {
  const DirectoryCard({super.key});

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
                appColors.accentPink,
                appColors.accentPinkDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Icon
                Icon(
                  Icons.store,
                  size: 32,
                  color: appColors.white,
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  'LOCAL PLACES',
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
        ),
      ),
    );
  }
}

