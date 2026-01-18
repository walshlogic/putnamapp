import 'package:flutter/material.dart';

import '../../extensions/build_context_extensions.dart';

/// Card widget for Clerk of Court
class ClerkOfCourtCard extends StatelessWidget {
  const ClerkOfCourtCard({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final cardTitleSize = context.cardTextStyles.cardTitleSize;

    return SizedBox(
      height: 140,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                appColors.accentOrange,
                appColors.accentOrangeDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.description,
                  size: 32,
                  color: appColors.white,
                ),
                const SizedBox(height: 4),
                Text(
                  'CLERK OF',
                  style: TextStyle(
                    fontSize: cardTitleSize * 0.7,
                    fontWeight: FontWeight.bold,
                    color: appColors.white,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'COURT',
                  style: TextStyle(
                    fontSize: cardTitleSize * 0.7,
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


