import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_providers.dart';
import 'router/app_router.dart';
// import 'services/admob_service.dart'; // Disabled - ads removed for App Store submission
import 'services/revenuecat_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('❌ FlutterError: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
    debugPrint('Library: ${details.library}');
    debugPrint('Context: ${details.context}');
  };

  // Set up error widget builder
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('❌ ErrorWidget: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'An error occurred',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exception.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Handle errors outside of Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('❌ PlatformDispatcher error: $error');
    debugPrint('Stack: $stack');
    return true;
  };

  // Run app in error zone to catch all unhandled exceptions
  runZonedGuarded(
    () async {
      await _runApp();
    },
    (error, stack) {
      debugPrint('❌ Unhandled error: $error');
      debugPrint('Stack: $stack');
    },
  );
}

Future<void> _runApp() async {
  // Initialize Flutter bindings first - must be in same zone as runApp
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv
        .load(fileName: 'assets/.env')
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Timeout loading environment variables');
          },
        );

    final String? supabaseUrl = dotenv.env['SUPABASE_URL'];
    final String? supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null ||
        supabaseUrl.isEmpty ||
        supabaseAnonKey == null ||
        supabaseAnonKey.isEmpty) {
      throw Exception(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY in assets/.env',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Timeout initializing Supabase');
      },
    );

    SupabaseService.configure(Supabase.instance.client);

    // AdMob initialization disabled - removed ads for App Store submission
    // Initialize AdMob (non-blocking)
    // AdMobService.initialize()
    //     .timeout(
    //       const Duration(seconds: 5),
    //       onTimeout: () {
    //         // Silently continue if AdMob times out
    //       },
    //     )
    //     .catchError((e) {
    //       // Silently continue if AdMob fails
    //     });

    // Initialize RevenueCat in background (non-blocking)
    // This can sometimes hang on iOS, so we don't block app startup
    RevenueCatService.initialize()
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // Silently continue if RevenueCat times out
          },
        )
        .catchError((e) {
          // Silently continue if RevenueCat fails
        });

    runApp(const ProviderScope(child: PutnamApp()));
  } catch (e, stackTrace) {
    debugPrint('❌ App: Fatal error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');

    // Run app anyway with error widget to show the error
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'App Initialization Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PutnamApp extends ConsumerStatefulWidget {
  const PutnamApp({super.key});

  @override
  ConsumerState<PutnamApp> createState() => _PutnamAppState();
}

class _PutnamAppState extends ConsumerState<PutnamApp> {
  GoRouter? _router;
  bool _ackDialogShown = false;

  String _platformLabel() {
    if (kIsWeb) {
      return 'web';
    }
    return defaultTargetPlatform.name;
  }

  Future<void> _logAcknowledgement() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    try {
      await client.from('acknowledge_log').insert({
        'user_id': userId,
        'acknowledged_at': DateTime.now().toUtc().toIso8601String(),
        'ack_version': 'v1',
        'platform': _platformLabel(),
      });
    } catch (e) {
      debugPrint('❌ Acknowledge log insert failed: $e');
    }
  }

  Future<void> _showAcknowledgementDialog(BuildContext context) async {
    bool acknowledged = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return AlertDialog(
              title: const Text('IMPORTANT NOTICE'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'The PutnamApp collects data from various public sources. '
                      'This data may be incomplete, erroneous, misleading, or otherwise inaccurate. '
                      'DO NOT MAKE DECISIONS BASED UPON INFORMATION YOU FIND ON THIS APP. '
                      'Do your own research elsewhere before taking any actions.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Checkbox(
                          value: acknowledged,
                          onChanged: (bool? value) {
                            setState(() {
                              acknowledged = value ?? false;
                            });
                          },
                        ),
                        const Expanded(child: Text('I acknowledge')),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: acknowledged
                      ? () async {
                          await _logAcknowledgement();
                          if (mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        }
                      : null,
                  child: const Text('CONTINUE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen(authStateProvider, (previous, next) {
      next.when(
        data: (_) {
          // Auth state changed - router will handle navigation
        },
        loading: () {
          // Loading state
        },
        error: (e, _) {
          debugPrint('❌ Auth state error: $e');
        },
      );
    });

    // Create router once and cache it
    _router ??= createAppRouter(ref);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Putnam.app',
      theme: AppTheme.light(),
      routerConfig: _router!,
      builder: (context, child) {
        if (child == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!_ackDialogShown) {
          _ackDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showAcknowledgementDialog(context);
            }
          });
        }
        return child;
      },
    );
  }
}
