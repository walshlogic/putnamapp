import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../models/booking.dart';
import '../models/weather.dart';
import '../providers/booking_providers.dart';
import '../providers/last_viewed_providers.dart';
import '../providers/weather_providers.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/cards/booking_count_card.dart';
import '../widgets/cards/clerk_of_court_card.dart';
import '../widgets/cards/directory_card.dart';
import '../widgets/cards/government_card.dart';
import '../widgets/cards/law_order_card.dart';
import '../widgets/cards/news_card.dart';
import '../widgets/cards/weather_card.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/trial_banner.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);
    final bookings = ref.watch(recentBookingsProvider);
    final hasNewBookings = ref.watch(hasNewBookingsProvider);

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: false),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          // Trial banner (shows when user is in trial)
          const TrialBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(weatherProvider);
                ref.invalidate(recentBookingsProvider);
              },
              child: Builder(
                builder: (context) {
                  // Get responsive values
                  final spacing = context.responsiveSpacing;
                  final padding = context.responsivePadding;
                  // Use shortest side to determine device type (prevents false tablet detection in landscape)
                  final isWideScreen = context.isTablet || context.isDesktop;

                  return ResponsiveUtils.constrainWidth(
                    context,
                    ListView(
                      padding: padding,
                      children: <Widget>[
                        // Responsive grid layout for cards
                        if (isWideScreen)
                          // Tablet/Desktop: Use GridView for better layout
                          _buildResponsiveGrid(
                            context,
                            spacing,
                            padding,
                            weather,
                            bookings,
                            hasNewBookings,
                            ref,
                          )
                        else
                          // Mobile: Use existing Row layout
                          _buildMobileLayout(
                            context,
                            spacing,
                            weather,
                            bookings,
                            hasNewBookings,
                            ref,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    double spacing,
    AsyncValue<WeatherSummary> weather,
    AsyncValue<List<JailBooking>> bookings,
    AsyncValue<bool> hasNewBookings,
    WidgetRef ref,
  ) {
    return Column(
      children: <Widget>[
        // First row: Weather + Jail Log (2 cards)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push(RoutePaths.weather),
                  borderRadius: BorderRadius.circular(16),
                  child: WeatherCard(weather: weather),
                ),
              ),
            ),
            SizedBox(width: spacing * 0.5),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final markAsViewed = ref.read(markJailLogAsViewedProvider);
                    await markAsViewed();
                    if (context.mounted) {
                      context.push(RoutePaths.bookings);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: BookingCountCard(
                    bookings: bookings,
                    hasNewBookings: hasNewBookings,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),

        // Local Directory (full width)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(RoutePaths.directory),
            borderRadius: BorderRadius.circular(16),
            child: const DirectoryCard(),
          ),
        ),
        SizedBox(height: spacing),

        // Law & Order + Clerk of Court Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push(RoutePaths.lawOrder),
                  borderRadius: BorderRadius.circular(16),
                  child: const LawOrderCard(),
                ),
              ),
            ),
            SizedBox(width: spacing * 0.5),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push(RoutePaths.clerkOfCourt),
                  borderRadius: BorderRadius.circular(16),
                  child: const ClerkOfCourtCard(),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),

        // Government + News Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push(RoutePaths.government),
                  borderRadius: BorderRadius.circular(16),
                  child: const GovernmentCard(),
                ),
              ),
            ),
            SizedBox(width: spacing * 0.5),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push(RoutePaths.news),
                  borderRadius: BorderRadius.circular(16),
                  child: const NewsCard(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResponsiveGrid(
    BuildContext context,
    double spacing,
    EdgeInsets padding,
    AsyncValue<WeatherSummary> weather,
    AsyncValue<List<JailBooking>> bookings,
    AsyncValue<bool> hasNewBookings,
    WidgetRef ref,
  ) {
    final crossAxisCount = context.cardGridCrossAxisCount;
    final childAspectRatio = ResponsiveUtils.getCardAspectRatio(context);

    return Column(
      children: <Widget>[
        // First row: Weather + Booking cards (full width, 50% each)
        // Use negative margins to extend to full width including padding
        Padding(
          padding: EdgeInsets.symmetric(horizontal: -padding.horizontal),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: padding.left,
                    right: spacing * 0.5,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push(RoutePaths.weather),
                      borderRadius: BorderRadius.circular(16),
                      child: WeatherCard(weather: weather),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: spacing * 0.5,
                    right: padding.right,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final markAsViewed = ref.read(markJailLogAsViewedProvider);
                        await markAsViewed();
                        if (context.mounted) {
                          context.push(RoutePaths.bookings);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: BookingCountCard(
                        bookings: bookings,
                        hasNewBookings: hasNewBookings,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing),

        // Directory Card (full width on tablets)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(RoutePaths.directory),
            borderRadius: BorderRadius.circular(16),
            child: const DirectoryCard(),
          ),
        ),
        SizedBox(height: spacing),

        // Remaining cards grid
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
          children: <Widget>[
            // Law & Order Card
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(RoutePaths.lawOrder),
                borderRadius: BorderRadius.circular(16),
                child: const LawOrderCard(),
              ),
            ),
            // Clerk of Court Card
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(RoutePaths.clerkOfCourt),
                borderRadius: BorderRadius.circular(16),
                child: const ClerkOfCourtCard(),
              ),
            ),
            // Government Card
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(RoutePaths.government),
                borderRadius: BorderRadius.circular(16),
                child: const GovernmentCard(),
              ),
            ),
            // News Card
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(RoutePaths.news),
                borderRadius: BorderRadius.circular(16),
                child: const NewsCard(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
