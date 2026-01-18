import 'package:flutter/material.dart';

import '../../extensions/build_context_extensions.dart';

/// Card widget for Law & Order
class LawOrderCard extends StatelessWidget {
  const LawOrderCard({super.key});

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
                appColors.purpleGradientStart,
                appColors.purpleGradientEnd,
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
                  Icons.gavel,
                  size: 32,
                  color: appColors.white,
                ),
                const SizedBox(height: 4),
                Text(
                  'LAW &',
                  style: TextStyle(
                    fontSize: cardTitleSize * 0.7,
                    fontWeight: FontWeight.bold,
                    color: appColors.white,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'ORDER',
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

