import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../models/place.dart';
import '../models/review.dart';
import '../providers/auth_providers.dart';
import '../providers/review_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/reviews/review_submission_dialog.dart';
import '../widgets/reviews/star_rating_display.dart';
import '../widgets/settings_drawer.dart';

/// Detailed view of a place with reviews and tier-based access
class PlaceDetailScreen extends ConsumerWidget {
  const PlaceDetailScreen({
    required this.place,
    super.key,
  });

  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final reviewsAsync = ref.watch(placeReviewsProvider(place.id));
    final coverUrl = place.coverPhotoUrl ?? place.logoUrl;

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: profileAsync.when(
              data: (profile) {
                final userTier = profile?.subscriptionTier ?? 'free';

                return ListView(
                  children: <Widget>[
                    // Cover Photo or Gradient Header
                    SizedBox(
                      height: 220,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          if (coverUrl != null && coverUrl.isNotEmpty)
                            Image.network(
                              coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildCoverFallback(appColors),
                            )
                          else
                            _buildCoverFallback(appColors),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  appColors.accentTeal.withValues(alpha: 0.75),
                                  appColors.accentTealDark.withValues(alpha: 0.75),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          Center(
                            child: Icon(
                              Icons.store,
                              size: 72,
                              color: appColors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Place Info Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Name
                          Text(
                            place.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: appColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Rating & Reviews
                          if (place.reviewCount > 0)
                            Row(
                              children: <Widget>[
                                StarRatingDisplay(
                                  rating: place.averageRating,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  place.averageRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: appColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${place.reviewCount} ${place.reviewCount == 1 ? "review" : "reviews"})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: appColors.textLight,
                                  ),
                                ),
                              ],
                            ),

                          // Description
                          if (place.description != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              place.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: appColors.textMedium,
                                height: 1.5,
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),
                          Divider(color: appColors.divider),
                          const SizedBox(height: 16),

                          _buildQuickActions(context, appColors, place),

                          // Contact Information
                          if (place.address != null)
                            _buildInfoRow(
                              context,
                              appColors,
                              Icons.location_on,
                              place.fullAddress,
                            ),
                          if (place.phone != null)
                            _buildInfoRow(
                              context,
                              appColors,
                              Icons.phone,
                              place.formattedPhone ?? place.phone!,
                              onTap: () => _launchPhone(place.phone!),
                            ),
                          if (place.website != null)
                            _buildInfoRow(
                              context,
                              appColors,
                              Icons.language,
                              place.website!,
                              onTap: () => _launchUrl(place.website!),
                            ),
                          if (place.priceRange != null)
                            _buildInfoRow(
                              context,
                              appColors,
                              Icons.attach_money,
                              'Price Range: ${place.priceRange}',
                            ),

                          const SizedBox(height: 20),
                          Divider(color: appColors.divider),
                          const SizedBox(height: 20),

                          // Reviews Section with Tier Gates
                          _buildReviewsSection(
                            context,
                            appColors,
                            userTier,
                            reviewsAsync,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading profile: $error'),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    dynamic appColors,
    IconData icon,
    String text, {
    VoidCallback? onTap,
  }) {
    final content = Row(
      children: <Widget>[
        Icon(icon, size: 20, color: appColors.accentTeal),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: onTap != null ? appColors.accentTeal : appColors.textDark,
              decoration: onTap != null ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: content,
    );
  }

  Widget _buildCoverFallback(dynamic appColors) {
    return Container(
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
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    dynamic appColors,
    Place place,
  ) {
    final actions = <Widget>[
      if (place.phone != null)
        _buildActionButton(
          appColors,
          icon: Icons.phone,
          label: 'Call',
          onTap: () => _launchPhone(place.phone!),
        ),
      if (place.website != null)
        _buildActionButton(
          appColors,
          icon: Icons.language,
          label: 'Website',
          onTap: () => _launchUrl(place.website!),
        ),
      if (place.address != null || (place.latitude != null && place.longitude != null))
        _buildActionButton(
          appColors,
          icon: Icons.map,
          label: 'Directions',
          onTap: () => _launchMaps(place),
        ),
    ];

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: actions,
      ),
    );
  }

  Widget _buildActionButton(
    dynamic appColors, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: appColors.accentTeal),
      label: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: appColors.accentTeal,
          letterSpacing: 0.5,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: appColors.accentTeal.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _launchMaps(Place place) {
    String query;
    if (place.latitude != null && place.longitude != null) {
      query = '${place.latitude},${place.longitude}';
    } else {
      query = Uri.encodeComponent(place.fullAddress);
    }
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    _launchUrl(url);
  }

  Widget _buildReviewsSection(
    BuildContext context,
    dynamic appColors,
    String userTier,
    AsyncValue<List<Review>> reviewsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Reviews Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'REVIEWS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appColors.textDark,
              ),
            ),
            if (place.reviewCount > 0)
              Text(
                '${place.reviewCount}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: appColors.accentTeal,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Tier-based Review Display
        if (userTier == 'free')
          _buildFreeTierReviewLock(context, appColors, place.reviewCount)
        else if (userTier == 'silver')
          Column(
            children: <Widget>[
              // Show reviews for silver users
              reviewsAsync.when(
                data: (List<Review> reviews) {
                  if (reviews.isEmpty) {
                    return _buildNoReviews(context, appColors);
                  }
                  return Column(
                    children: reviews.map((review) {
                      return _buildReviewCard(context, appColors, review);
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _buildNoReviews(context, appColors),
              ),
              const SizedBox(height: 16),
              // Silver users can't write - show upgrade prompt
              _buildSilverTierWriteLock(context, appColors),
            ],
          )
        else
          // Gold users get full access
          Column(
            children: <Widget>[
              // Show reviews
              reviewsAsync.when(
                data: (List<Review> reviews) {
                  if (reviews.isEmpty) {
                    return _buildNoReviews(context, appColors);
                  }
                  return Column(
                    children: reviews.map((review) {
                      return _buildReviewCard(context, appColors, review);
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _buildNoReviews(context, appColors),
              ),
              const SizedBox(height: 16),
              // Gold users can write reviews
              _buildWriteReviewButton(context, appColors),
            ],
          ),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, dynamic appColors, Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // User name and rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  review.isAnonymous ? 'Anonymous' : (review.userName ?? 'Anonymous'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: appColors.textDark,
                  ),
                ),
                StarRatingDisplay(
                  rating: review.rating.toDouble(),
                  size: 14,
                ),
              ],
            ),
            
            // Title (if exists)
            if (review.title != null) ...[
              const SizedBox(height: 8),
              Text(
                review.title!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: appColors.textDark,
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            // Comment
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 14,
                color: appColors.textMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            // Date
            Text(
              review.timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: appColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoReviews(BuildContext context, dynamic appColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No reviews yet. Be the first to review!',
          style: TextStyle(
            fontSize: 14,
            color: appColors.textLight,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // FREE TIER: Lock reviews, show upgrade prompt
  Widget _buildFreeTierReviewLock(
    BuildContext context,
    dynamic appColors,
    int reviewCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            appColors.lightPurple.withValues(alpha: 0.3),
            appColors.accentTeal.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.primaryPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.lock_outline,
            size: 48,
            color: appColors.primaryPurple,
          ),
          const SizedBox(height: 16),
          Text(
            '🔒 ${reviewCount > 0 ? "$reviewCount people reviewed this place" : "Reviews Locked"}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: appColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'See what your neighbors are saying about this place',
            style: TextStyle(
              fontSize: 14,
              color: appColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(RoutePaths.tierSelection),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors.primaryPurple,
                foregroundColor: appColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Upgrade to Silver to Read Reviews',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SILVER TIER: Can read, but can't write
  Widget _buildSilverTierWriteLock(BuildContext context, dynamic appColors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Colors.amber.shade50,
            Colors.orange.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.edit_note,
            size: 40,
            color: Colors.amber.shade700,
          ),
          const SizedBox(height: 12),
          Text(
            '✍️ Want to share your experience?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: appColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade to Gold to write reviews and upload photos',
            style: TextStyle(
              fontSize: 13,
              color: appColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(RoutePaths.tierSelection),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Upgrade to Gold - Write Reviews',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // GOLD TIER: Write review button
  Widget _buildWriteReviewButton(BuildContext context, dynamic appColors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showWriteReviewDialog(context);
        },
        icon: const Icon(Icons.rate_review),
        label: const Text(
          'Write a Review',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.accentTeal,
          foregroundColor: appColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  void _showWriteReviewDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => ReviewSubmissionDialog(place: place),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString.startsWith('http')
        ? urlString
        : 'https://$urlString');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

