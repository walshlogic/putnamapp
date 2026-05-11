import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/route_names.dart';

class PutnamAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const PutnamAppBar({
    super.key,
    this.showBackButton = false,
    this.extraActions,
  });

  final bool showBackButton;

  /// Optional screen-specific actions inserted before the standard profile +
  /// settings icons (e.g., edit/delete on a detail screen).
  final List<Widget>? extraActions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      // backgroundColor and foregroundColor now come from AppBarTheme in app_theme.dart
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            )
          : Builder(
              builder: (BuildContext context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
      title: const Text('PUTNAM+LIFE'),
      centerTitle: true,
      actions: <Widget>[
        if (extraActions != null) ...extraActions!,
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => context.pushNamed(RouteNames.profile),
        ),
        Builder(
          builder: (BuildContext context) => IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
      ],
    );
  }
}
