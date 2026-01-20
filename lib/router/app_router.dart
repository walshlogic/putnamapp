import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/route_names.dart';
import '../config/route_paths.dart';
import '../models/agency.dart';
import '../models/booking.dart';
import '../models/top_list_item.dart';
import '../providers/auth_providers.dart';
import '../models/place.dart';
import '../models/traffic_citation.dart';
import '../screens/about_screen.dart';
import '../screens/agency_detail_screen.dart';
import '../screens/data_usage_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_use_screen.dart';
import '../screens/agency_stats_screen.dart';
import '../screens/booking_detail_screen.dart';
import '../screens/booking_comment_create_screen.dart';
import '../screens/booking_photo_progression_screen.dart';
import '../screens/bookings_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/directory_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/clerk_of_court_main_screen.dart';
import '../screens/government_detail_screen.dart';
import '../screens/traffic_citations_screen.dart';
import '../screens/traffic_citation_detail_screen.dart';
import '../screens/criminal_back_history_screen.dart';
import '../screens/criminal_back_history_detail_screen.dart';
import '../models/criminal_back_history.dart';
import '../screens/news_screen.dart';
import '../screens/government_screen.dart';
import '../screens/home_page.dart';
import '../screens/law_order_screen.dart';
import '../screens/login_screen.dart';
import '../screens/place_detail_screen.dart';
import '../screens/place_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sex_offender_screen.dart';
import '../screens/sex_offender_detail_screen.dart';
import '../models/sex_offender.dart';
import '../screens/signup_screen.dart';
import '../screens/tier_selection_screen.dart';
import '../screens/bookings_by_date_screen.dart';
import '../screens/people_by_charge_screen.dart';
import '../screens/person_bookings_screen.dart';
import '../screens/person_charge_breakdown_screen.dart';
import '../screens/top_list_detail_screen.dart';
import '../screens/top_ten_screen.dart';
import '../screens/weather_screen.dart';

/// Provider for the app router
/// Using keepAlive to ensure router is only created once and never disposed
/// Note: This provider is kept for backward compatibility but may not be used
final appRouterProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();
  // This provider requires WidgetRef, so it should be created in widget build
  throw UnimplementedError(
    'appRouterProvider should not be used directly. '
    'Create router using createAppRouter(ref) in widget build method.',
  );
});

/// Create the router with auth guards
GoRouter createAppRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: RoutePaths.login, // Require login for all users
    redirect: (BuildContext context, GoRouterState state) {
      try {
        // Get current location
        final currentLocation = state.uri.path;
        final matchedLocation = state.matchedLocation;

        // Define auth pages
        final authPages = [
          RoutePaths.login,
          RoutePaths.signup,
          RoutePaths.forgotPassword,
        ];
        final isAuthPage =
            authPages.contains(currentLocation) ||
            matchedLocation == RoutePaths.login ||
            matchedLocation == RoutePaths.signup ||
            matchedLocation == RoutePaths.forgotPassword;

        // Try to read auth state, but handle if providers aren't ready yet
        bool isLoggedIn = false;
        try {
          isLoggedIn = ref.read(isLoggedInProvider);
        } catch (e) {
          // If provider isn't ready yet, only allow auth pages
          if (isAuthPage) {
            return null;
          }
          return RoutePaths.login;
        }

        // Require login for all non-auth pages
        if (!isAuthPage && !isLoggedIn) {
          return RoutePaths.login;
        }

        // If logged in and on auth page, redirect to home
        if (isLoggedIn && isAuthPage) {
          return RoutePaths.home;
        }

        // No redirect needed
        return null;
      } catch (e) {
        debugPrint('❌ Router: Error in redirect function: $e');
        // On error, require login unless already on auth page
        final currentPath = state.uri.path;
        final authPages = [RoutePaths.login, RoutePaths.signup, RoutePaths.forgotPassword];
        if (!authPages.contains(currentPath)) {
          return RoutePaths.login;
        }
        return null;
      }
    },
    routes: <RouteBase>[
      // Auth routes (accessible without login)
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: RoutePaths.signup,
        name: RouteNames.signup,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: SignupScreen()),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: ForgotPasswordScreen()),
      ),

      // Main app routes (require authentication)
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: HomePage()),
      ),
      GoRoute(
        path: RoutePaths.profile,
        name: RouteNames.profile,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: ProfileScreen()),
      ),
      GoRoute(
        path: RoutePaths.tierSelection,
        name: RouteNames.tierSelection,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: TierSelectionScreen()),
      ),
      GoRoute(
        path: RoutePaths.bookings,
        name: RouteNames.bookings,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: BookingsScreen()),
      ),
      GoRoute(
        path: RoutePaths.weather,
        name: RouteNames.weather,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: WeatherScreen()),
      ),
      GoRoute(
        path: RoutePaths.bookingDetail,
        name: RouteNames.bookingDetail,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final JailBooking booking = state.extra! as JailBooking;
          return NoTransitionPage(child: BookingDetailScreen(booking: booking));
        },
      ),
      GoRoute(
        path: RoutePaths.bookingCommentCreate,
        name: RouteNames.bookingCommentCreate,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final JailBooking booking = state.extra! as JailBooking;
          return NoTransitionPage(
            child: BookingCommentCreateScreen(booking: booking),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.bookingPhotoProgression,
        name: RouteNames.bookingPhotoProgression,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final JailBooking booking = state.extra! as JailBooking;
          return NoTransitionPage(
            child: BookingPhotoProgressionScreen(booking: booking),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.about,
        name: RouteNames.about,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: AboutScreen()),
      ),
      GoRoute(
        path: RoutePaths.dataUsage,
        name: RouteNames.dataUsage,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: DataUsageScreen()),
      ),
      GoRoute(
        path: RoutePaths.contact,
        name: RouteNames.contact,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: ContactScreen()),
      ),
      GoRoute(
        path: RoutePaths.privacy,
        name: RouteNames.privacy,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: PrivacyPolicyScreen()),
      ),
      GoRoute(
        path: RoutePaths.termsOfUse,
        name: RouteNames.termsOfUse,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: TermsOfUseScreen()),
      ),
      GoRoute(
        path: RoutePaths.sexOffenders,
        name: RouteNames.sexOffenders,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: SexOffenderScreen()),
      ),
      GoRoute(
        path: RoutePaths.sexOffenderDetail,
        name: RouteNames.sexOffenderDetail,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final SexOffender offender = state.extra! as SexOffender;
          return NoTransitionPage(
            child: SexOffenderDetailScreen(offender: offender),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.lawOrder,
        name: RouteNames.lawOrder,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: LawOrderScreen()),
      ),
      GoRoute(
        path: RoutePaths.topTen,
        name: RouteNames.topTen,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: TopTenScreen()),
      ),
      GoRoute(
        path: RoutePaths.topListDetail,
        name: RouteNames.topListDetail,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final TopListCategory category = state.extra! as TopListCategory;
          return NoTransitionPage(
            child: TopListDetailScreen(category: category),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.personChargeBreakdown,
        name: RouteNames.personChargeBreakdown,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String personName = state.extra! as String;
          return NoTransitionPage(
            child: PersonChargeBreakdownScreen(personName: personName),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.personBookings,
        name: RouteNames.personBookings,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String personName = state.extra! as String;
          return NoTransitionPage(
            child: PersonBookingsScreen(personName: personName),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.peopleByCharge,
        name: RouteNames.peopleByCharge,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final Map<String, dynamic> params =
              state.extra! as Map<String, dynamic>;
          return NoTransitionPage(
            child: PeopleByChargeScreen(
              chargeName: params['chargeName'] as String,
              timeRange: params['timeRange'] as String,
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.bookingsByDate,
        name: RouteNames.bookingsByDate,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final DateTime date = state.extra! as DateTime;
          return NoTransitionPage(child: BookingsByDateScreen(date: date));
        },
      ),
      GoRoute(
        path: RoutePaths.agencyStats,
        name: RouteNames.agencyStats,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: AgencyStatsScreen()),
      ),
      GoRoute(
        path: RoutePaths.agencyDetail,
        name: RouteNames.agencyDetail,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final Agency agency = state.extra! as Agency;
          return NoTransitionPage(child: AgencyDetailScreen(agency: agency));
        },
      ),
      GoRoute(
        path: RoutePaths.directory,
        name: RouteNames.directory,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: DirectoryScreen()),
      ),
      GoRoute(
        path: RoutePaths.directoryCategory,
        name: RouteNames.directoryCategory,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final PlaceCategory category = state.extra! as PlaceCategory;
          return NoTransitionPage(child: PlaceListScreen(category: category));
        },
      ),
      GoRoute(
        path: RoutePaths.placeDetail,
        name: RouteNames.placeDetail,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final Place place = state.extra! as Place;
          return NoTransitionPage(child: PlaceDetailScreen(place: place));
        },
      ),
      GoRoute(
        path: RoutePaths.government,
        name: RouteNames.government,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: GovernmentScreen()),
      ),
      GoRoute(
        path: RoutePaths.governmentDetail,
        name: RouteNames.governmentDetail,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String governmentName = state.extra! as String;
          return NoTransitionPage(
            child: GovernmentDetailScreen(governmentName: governmentName),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.clerkOfCourt,
        name: RouteNames.clerkOfCourt,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: ClerkOfCourtMainScreen()),
      ),
      GoRoute(
        path: RoutePaths.trafficCitations,
        name: RouteNames.trafficCitations,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: TrafficCitationsScreen()),
      ),
      GoRoute(
        path: RoutePaths.trafficCitationDetail,
        name: RouteNames.trafficCitationDetail,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final TrafficCitation citation = state.extra! as TrafficCitation;
          return NoTransitionPage(
            child: TrafficCitationDetailScreen(citation: citation),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.criminalBackHistory,
        name: RouteNames.criminalBackHistory,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: CriminalBackHistoryScreen()),
      ),
      GoRoute(
        path: RoutePaths.criminalBackHistoryDetail,
        name: RouteNames.criminalBackHistoryDetail,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final CriminalBackHistory caseRecord =
              state.extra! as CriminalBackHistory;
          return NoTransitionPage(
            child: CriminalBackHistoryDetailScreen(caseRecord: caseRecord),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.news,
        name: RouteNames.news,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            const NoTransitionPage(child: NewsScreen()),
      ),
    ],
  );
}

// Legacy router for backward compatibility during migration
// This will be removed once main.dart is updated
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: RoutePaths.home,
      name: RouteNames.home,
      pageBuilder: (BuildContext context, GoRouterState state) =>
          const NoTransitionPage(child: HomePage()),
    ),
    GoRoute(
      path: RoutePaths.bookings,
      name: RouteNames.bookings,
      pageBuilder: (BuildContext context, GoRouterState state) =>
          const NoTransitionPage(child: BookingsScreen()),
    ),
    GoRoute(
      path: RoutePaths.weather,
      name: RouteNames.weather,
      pageBuilder: (BuildContext context, GoRouterState state) =>
          const NoTransitionPage(child: WeatherScreen()),
    ),
    GoRoute(
      path: RoutePaths.bookingDetail,
      name: RouteNames.bookingDetail,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final JailBooking booking = state.extra! as JailBooking;
        return NoTransitionPage(child: BookingDetailScreen(booking: booking));
      },
    ),
    GoRoute(
      path: RoutePaths.about,
      name: RouteNames.about,
      pageBuilder: (BuildContext context, GoRouterState state) =>
          const NoTransitionPage(child: AboutScreen()),
    ),
    GoRoute(
      path: RoutePaths.contact,
      name: RouteNames.contact,
      pageBuilder: (BuildContext context, GoRouterState state) =>
          const NoTransitionPage(child: ContactScreen()),
    ),
    GoRoute(
      path: RoutePaths.privacy,
      name: RouteNames.privacy,
      pageBuilder: (BuildContext context, GoRouterState state) =>
          const NoTransitionPage(child: PrivacyPolicyScreen()),
    ),
    GoRoute(
      path: RoutePaths.termsOfUse,
      name: RouteNames.termsOfUse,
      pageBuilder: (BuildContext context, GoRouterState state) =>
          const NoTransitionPage(child: TermsOfUseScreen()),
    ),
    GoRoute(
      path: RoutePaths.sexOffenders,
      name: RouteNames.sexOffenders,
      pageBuilder: (BuildContext context, GoRouterState state) =>
          const NoTransitionPage(child: SexOffenderScreen()),
    ),
    GoRoute(
      path: RoutePaths.sexOffenderDetail,
      name: RouteNames.sexOffenderDetail,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final SexOffender offender = state.extra! as SexOffender;
        return NoTransitionPage(
          child: SexOffenderDetailScreen(offender: offender),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.lawOrder,
      name: RouteNames.lawOrder,
      pageBuilder: (BuildContext context, GoRouterState state) =>
          const NoTransitionPage(child: LawOrderScreen()),
    ),
    GoRoute(
      path: RoutePaths.topTen,
      name: RouteNames.topTen,
      pageBuilder: (BuildContext context, GoRouterState state) =>
          const NoTransitionPage(child: TopTenScreen()),
    ),
    GoRoute(
      path: RoutePaths.topListDetail,
      name: RouteNames.topListDetail,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final TopListCategory category = state.extra! as TopListCategory;
        return NoTransitionPage(child: TopListDetailScreen(category: category));
      },
    ),
    GoRoute(
      path: RoutePaths.agencyStats,
      name: RouteNames.agencyStats,
      pageBuilder: (BuildContext context, GoRouterState state) =>
          const NoTransitionPage(child: AgencyStatsScreen()),
    ),
    GoRoute(
      path: RoutePaths.agencyDetail,
      name: RouteNames.agencyDetail,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final Agency agency = state.extra! as Agency;
        return NoTransitionPage(child: AgencyDetailScreen(agency: agency));
      },
    ),
  ],
);
