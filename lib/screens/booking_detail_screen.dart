import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/route_paths.dart';
import '../config/route_names.dart';
import '../extensions/build_context_extensions.dart';
import '../models/booking.dart';
import '../models/booking_comment.dart';
import '../providers/auth_providers.dart';
import '../providers/booking_comment_providers.dart';
import '../providers/booking_providers.dart';
import '../providers/person_providers.dart';
import '../utils/text_cleaner.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.booking});

  final JailBooking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    final allBookings = booking.mniNo.isNotEmpty
        ? ref.watch(bookingsByMniProvider(booking.mniNo))
        : ref.watch(bookingsByNameProvider(booking.name));
    final personData = ref.watch(personByNameProvider(booking.name));
    final commentsAsync = booking.mniNo.isNotEmpty
        ? ref.watch(bookingCommentsByMniProvider(booking.mniNo))
        : ref.watch(bookingCommentsByNameProvider(booking.name));
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final currentSession = ref.watch(currentSessionProvider);
    final currentUserId = currentSession?.user.id;
    final bookingHistory = allBookings.maybeWhen(
      data: (list) => list,
      orElse: () => null,
    );

    final styles = context.detailScreenStyles;

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // Large photo (tappable to enlarge)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      // Show enlarged photo in dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            child: Stack(
                              children: <Widget>[
                                // Enlarged photo
                                Center(
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.9,
                                      height:
                                          MediaQuery.of(context).size.width *
                                          0.9,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        image: DecorationImage(
                                          image: NetworkImage(booking.photoUrl),
                                          fit: BoxFit.cover,
                                          filterQuality: FilterQuality.high,
                                        ),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF8B7FED,
                                          ).withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Close button
                                Positioned(
                                  top: 40,
                                  right: 20,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        image: DecorationImage(
                          image: NetworkImage(booking.photoUrl),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      // Add visual hint that it's tappable
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(
                              0xFF8B7FED,
                            ).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // OPTIONAL: Photo progression entry point (hide if no prior bookings)
                allBookings.when(
                  data: (List<JailBooking> allBookingsList) {
                    final bool hasPriorBooking = allBookingsList.any(
                      (JailBooking b) => b.bookingNo != booking.bookingNo,
                    );
                    if (!hasPriorBooking) {
                      return const SizedBox.shrink();
                    }
                    final int totalPhotos = allBookingsList.length;
                    return TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        context.pushNamed(
                          RouteNames.bookingPhotoProgression,
                          extra: booking,
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'MUGSHOT SHOW',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: appColors.primaryPurple,
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '($totalPhotos PHOTOS)',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: appColors.primaryPurple,
                                  letterSpacing: 0.4,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (Object _, StackTrace __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Personal Info Card
                _buildSectionCard(
                  context,
                  icon: Icons.person,
                  title: 'PERSONAL INFORMATION',
                  children: <Widget>[
                    // Name - centered, full width
                    Center(
                      child: Text(
                        booking.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: styles.personNameSize,
                          fontWeight: FontWeight.bold,
                          color: appColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (booking.ageOnBookingDate != null ||
                        booking.race.isNotEmpty ||
                        booking.gender.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                    ],
                    if (booking.race.isNotEmpty) ...<Widget>[
                      _buildInfoRow(
                        context,
                        'Race',
                        booking.race.toUpperCase(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (booking.gender.isNotEmpty) ...<Widget>[
                      _buildInfoRow(
                        context,
                        'Gender',
                        booking.gender.toUpperCase(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (booking.ageOnBookingDate != null) ...<Widget>[
                      _buildInfoRow(
                        context,
                        'Age at Booking',
                        booking.ageOnBookingDate.toString(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Show approximate DOB from booked_persons table
                    personData.when(
                      data: (person) {
                        if (person == null ||
                            person.birthMonthLow == null ||
                            person.birthYearLow == null) {
                          return const SizedBox.shrink();
                        }
                        return _buildInfoRow(
                          context,
                          'Approx DOB',
                          person.birthDateRangeDisplay,
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Address Card
                if (booking.addressGiven.isNotEmpty)
                  _buildSectionCard(
                    context,
                    icon: Icons.home_outlined,
                    title: 'ADDRESS',
                    children: <Widget>[
                      ..._buildAddressLines(context, booking.addressGiven),
                    ],
                  ),

                if (booking.addressGiven.isNotEmpty) const SizedBox(height: 12),

                _buildCommentsCard(
                  context,
                  ref,
                  commentsAsync,
                  isLoggedIn,
                  booking,
                  bookingHistory,
                  currentUserId,
                ),

                const SizedBox(height: 12),

                // Booking Details Card
                _buildSectionCard(
                  context,
                  icon: Icons.info_outline,
                  title: 'BOOKING DETAILS',
                  children: <Widget>[
                    _buildInfoRow(
                      context,
                      'Booking No',
                      booking.bookingNo.toUpperCase(),
                    ),
                    if (booking.mniNo.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'MNI No',
                        booking.mniNo.toUpperCase(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Status',
                      booking.status.toUpperCase(),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Booking Date',
                      booking.bookingDateString.toUpperCase(),
                    ),
                    if (booking.releasedDate != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'Released Date',
                        '${booking.releasedDate!.month}/${booking.releasedDate!.day}/${booking.releasedDate!.year}',
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Holds Card
                if (booking.holdsText.isNotEmpty)
                  _buildSectionCard(
                    context,
                    icon: Icons.warning_amber_outlined,
                    title: 'HOLDS',
                    children: <Widget>[
                      Text(
                        booking.holdsText.toUpperCase(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.appColors.accentPink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                if (booking.holdsText.isNotEmpty) const SizedBox(height: 12),

                // Charges Card with full details
                _buildSectionCard(
                  context,
                  icon: Icons.gavel,
                  title: 'CHARGES',
                  children: <Widget>[
                    ...booking.chargeDetails.asMap().entries.map((
                      MapEntry<int, ChargeDetail> entry,
                    ) {
                      final int index = entry.key;
                      final ChargeDetail charge = entry.value;
                      return Column(
                        children: <Widget>[
                          if (index > 0) ...<Widget>[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: appColors.primaryPurple,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: appColors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      charge.charge.toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: appColors.textDark,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (charge.statute.isNotEmpty)
                                      _buildChargeDetail(
                                        context,
                                        'Statute',
                                        charge.statute.toUpperCase(),
                                      ),
                                    if (charge.caseNumber.isNotEmpty)
                                      _buildChargeDetail(
                                        context,
                                        'Case Number',
                                        charge.caseNumber.toUpperCase(),
                                      ),
                                    if (charge.degree.isNotEmpty)
                                      _buildChargeDetail(
                                        context,
                                        'Degree',
                                        charge.degreeText,
                                      ),
                                    if (charge.level.isNotEmpty)
                                      _buildChargeDetail(
                                        context,
                                        'Level',
                                        charge.levelText,
                                      ),
                                    if (charge.bond.isNotEmpty)
                                      _buildChargeDetail(
                                        context,
                                        'Bond',
                                        TextCleaner.cleanBondAmount(
                                          charge.bond,
                                        ).toUpperCase(),
                                        highlight: true,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 12),

                // Booking History Summary Card & Previous Bookings
                allBookings.when(
                  data: (List<JailBooking> allBookingsList) {
                    final List<JailBooking> otherBookings = allBookingsList
                        .where(
                          (JailBooking b) => b.bookingNo != booking.bookingNo,
                        )
                        .toList();

                    if (otherBookings.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final int totalBookings = allBookingsList.length;
                    final int totalCharges = allBookingsList.fold<int>(
                      0,
                      (int sum, JailBooking b) => sum + b.chargeDetails.length,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Statistics Card
                        _buildSectionCard(
                          context,
                          icon: Icons.history,
                          title: 'BOOKING HISTORY',
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        'BOOKINGS',
                                        style: TextStyle(
                                          fontSize: styles.statisticLabelSize,
                                          color: appColors.textLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        totalBookings.toString(),
                                        style: TextStyle(
                                          fontSize: styles.statisticNumberSize,
                                          fontWeight: FontWeight.bold,
                                          color: appColors.primaryPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: appColors.border,
                                ),
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        'CHARGES',
                                        style: TextStyle(
                                          fontSize: styles.statisticLabelSize,
                                          color: appColors.textLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        totalCharges.toString(),
                                        style: TextStyle(
                                          fontSize: styles.statisticNumberSize,
                                          fontWeight: FontWeight.bold,
                                          color: appColors.accentPink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Previous booking cards
                        ...otherBookings.map((JailBooking b) {
                          return GestureDetector(
                            onTap: () => context.push(
                              RoutePaths.bookingDetail,
                              extra: b,
                            ),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    image: DecorationImage(
                                      image: NetworkImage(b.photoUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  b.bookingDateString,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: context.appColors.primaryPurple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                subtitle: Text(
                                  b.charges.join(', ').toUpperCase(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: context.appColors.divider,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (Object e, StackTrace st) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Future<void> _openAddCommentScreen(
    BuildContext context,
    WidgetRef ref,
    JailBooking booking,
  ) async {
    final result = await context.push<bool>(
      RoutePaths.bookingCommentCreate,
      extra: booking,
    );
    if (result == true) {
      if (booking.mniNo.isNotEmpty) {
        ref.invalidate(bookingCommentsByMniProvider(booking.mniNo));
      } else {
        ref.invalidate(bookingCommentsByNameProvider(booking.name));
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('COMMENT SAVED', textAlign: TextAlign.center),
            backgroundColor: context.appColors.success,
          ),
        );
      }
    }
  }

  void _invalidateComments(WidgetRef ref, BookingComment comment) {
    final mniNo = comment.mniNo;
    if (mniNo != null && mniNo.isNotEmpty) {
      ref.invalidate(bookingCommentsByMniProvider(mniNo));
    } else {
      ref.invalidate(bookingCommentsByNameProvider(comment.personName));
    }
  }

  Future<void> _showCommentActions(
    BuildContext context,
    WidgetRef ref,
    BookingComment comment,
    List<JailBooking>? bookingHistory,
    String? currentUserId,
  ) async {
    final bool isOwner = currentUserId != null && currentUserId == comment.userId;
    final _CommentAction? action = await showModalBottomSheet<_CommentAction>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('EDIT'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_CommentAction.edit),
                ),
              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.visibility_off_outlined),
                  title: const Text('UNPUBLISH'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_CommentAction.unpublish),
                ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('REPORT'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_CommentAction.report),
              ),
              if (bookingHistory != null)
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('VIEW BOOKING'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_CommentAction.viewBooking),
                ),
            ],
          ),
        );
      },
    );

    switch (action) {
      case _CommentAction.edit:
        await _openEditCommentScreen(context, ref, comment);
        return;
      case _CommentAction.unpublish:
        await _confirmUnpublish(context, ref, comment);
        return;
      case _CommentAction.report:
        await _reportComment(context, ref, comment);
        return;
      case _CommentAction.viewBooking:
        if (bookingHistory != null) {
          _openCommentBooking(context, comment, bookingHistory);
        }
        return;
      case null:
        return;
    }
  }

  Future<void> _openEditCommentScreen(
    BuildContext context,
    WidgetRef ref,
    BookingComment comment,
  ) async {
    final result = await context.push<bool>(
      RoutePaths.bookingCommentEdit,
      extra: comment,
    );
    if (result == true && context.mounted) {
      _invalidateComments(ref, comment);
      context.showSuccessSnackBar('COMMENT UPDATED');
    }
  }

  Future<void> _confirmUnpublish(
    BuildContext context,
    WidgetRef ref,
    BookingComment comment,
  ) async {
    final bool? shouldUnpublish = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('UNPUBLISH COMMENT'),
          content: const Text(
            'This will hide your comment from other users.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('UNPUBLISH'),
            ),
          ],
        );
      },
    );

    if (shouldUnpublish != true) return;

    try {
      final repository = ref.read(bookingCommentRepositoryProvider);
      await repository.unpublishComment(currentComment: comment);
      if (!context.mounted) return;
      _invalidateComments(ref, comment);
      context.showSuccessSnackBar('COMMENT UNPUBLISHED');
    } catch (e) {
      if (!context.mounted) return;
      context.showErrorSnackBar('FAILED TO UNPUBLISH COMMENT: $e');
    }
  }

  Future<void> _reportComment(
    BuildContext context,
    WidgetRef ref,
    BookingComment comment,
  ) async {
    const reasons = <String>[
      'SPAM OR SCAM',
      'HARASSMENT OR HATE',
      'OBSCENE OR EXPLICIT',
      'PERSONAL INFORMATION',
      'OTHER',
    ];

    final String? reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons
                .map(
                  (value) => ListTile(
                    title: Text(value),
                    onTap: () => Navigator.of(sheetContext).pop(value),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (reason == null) return;

    try {
      final repository = ref.read(bookingCommentRepositoryProvider);
      await repository.reportComment(comment: comment, reason: reason);
      if (!context.mounted) return;
      context.showSuccessSnackBar('COMMENT REPORTED');
    } catch (e) {
      if (!context.mounted) return;
      context.showErrorSnackBar('FAILED TO REPORT COMMENT: $e');
    }
  }

  Widget _buildCommentsCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<BookingComment>> commentsAsync,
    bool isLoggedIn,
    JailBooking booking,
    List<JailBooking>? bookingHistory,
    String? currentUserId,
  ) {
    final styles = context.detailScreenStyles;
    final appColors = context.appColors;
    final bool hasComments = commentsAsync.maybeWhen(
      data: (comments) => comments.isNotEmpty,
      orElse: () => false,
    );

    final header = Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: appColors.lightPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.forum_outlined,
            color: appColors.primaryPurple,
            size: styles.sectionIconSize,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'COMMENTS',
            style: TextStyle(
              fontSize: styles.sectionTitleSize,
              fontWeight: FontWeight.w600,
              color: appColors.textDark,
            ),
          ),
        ),
        commentsAsync.when(
          data: (comments) => Text(
            '${comments.length}',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: appColors.primaryPurple),
          ),
          loading: () => Text(
            '...',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: appColors.primaryPurple),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () {
            if (!isLoggedIn) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please sign in to leave a comment.'),
                ),
              );
              return;
            }
            _openAddCommentScreen(context, ref, booking);
          },
          icon: const Icon(Icons.add_comment_outlined, size: 18),
          label: const Text('ADD'),
        ),
      ],
    );

    if (!hasComments) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: header,
        ),
      );
    }

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(20),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: header,
        children: <Widget>[
          const SizedBox(height: 12),
          commentsAsync.when(
            data: (comments) => _buildCommentsList(
              context,
              ref,
              appColors,
              comments,
              bookingHistory,
              currentUserId,
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Text(
              'Unable to load comments: $error',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(
    BuildContext context,
    WidgetRef ref,
    dynamic appColors,
    List<BookingComment> comments,
    List<JailBooking>? bookingHistory,
    String? currentUserId,
  ) {
    if (comments.isEmpty) {
      return Text(
        'No comments yet. Be the first to add one.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Column(
      children: comments.map((comment) {
        return _buildCommentItem(
          context,
          ref,
          appColors,
          comment,
          bookingHistory,
          currentUserId,
        );
      }).toList(),
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    WidgetRef ref,
    dynamic appColors,
    BookingComment comment,
    List<JailBooking>? bookingHistory,
    String? currentUserId,
  ) {
    final author = (comment.userName == null || comment.userName!.isEmpty)
        ? 'User'
        : comment.userName!;

    return InkWell(
      onTap: () => _showCommentActions(
        context,
        ref,
        comment,
        bookingHistory,
        currentUserId,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appColors.divider.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: appColors.lightPurple,
                  backgroundImage: comment.userPhotoUrl != null
                      ? NetworkImage(comment.userPhotoUrl!)
                      : null,
                  child: comment.userPhotoUrl == null
                      ? Icon(Icons.person, size: 16, color: appColors.primaryPurple)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    author,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: appColors.textDark,
                    ),
                  ),
                ),
                Text(
                  comment.timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: appColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.comment,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _openCommentBooking(
    BuildContext context,
    BookingComment comment,
    List<JailBooking> bookingHistory,
  ) {
    JailBooking? target;
    for (final booking in bookingHistory) {
      if (booking.bookingNo == comment.bookingNo) {
        target = booking;
        break;
      }
    }
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking not found for this comment.')),
      );
      return;
    }
    context.push(RoutePaths.bookingDetail, extra: target);
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final styles = context.detailScreenStyles;
    final appColors = context.appColors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: appColors.lightPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: appColors.primaryPurple,
                    size: styles.sectionIconSize,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: styles.sectionTitleSize,
                    fontWeight: FontWeight.w600,
                    color: appColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final styles = context.detailScreenStyles;
    final appColors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: styles.infoLabelSize,
              color: appColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value.toUpperCase(),
            style: TextStyle(
              fontSize: styles.infoValueSize,
              fontWeight: FontWeight.w600,
              color: appColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChargeDetail(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final styles = context.detailScreenStyles;
    final appColors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              '${label.toUpperCase()}:',
              style: TextStyle(
                fontSize: styles.chargeDetailLabelSize,
                color: appColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toUpperCase(),
              style: TextStyle(
                fontSize: styles.chargeDetailValueSize,
                color: highlight ? appColors.accentPink : appColors.textMedium,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parse address into two lines: street address and city/state/zip
  List<Widget> _buildAddressLines(BuildContext context, String fullAddress) {
    // Common address format: "104 N 17TH ST CRESCENT CITY, FL 32177"
    // We want:
    //   Line 1: "104 N 17TH ST"
    //   Line 2: "CRESCENT CITY, FL 32177"

    String streetAddress = '';
    String cityStateZip = '';

    // Find the comma that separates city from state
    final commaIndex = fullAddress.indexOf(',');

    if (commaIndex > 0) {
      // Has comma - format like "STREET CITY, STATE ZIP"
      final beforeComma = fullAddress.substring(0, commaIndex).trim();
      final afterComma = fullAddress.substring(commaIndex + 1).trim();

      // Multi-word cities that should stay together
      final multiWordCities = [
        'CRESCENT CITY STATION', // Check longer names first
        'CRESCENT CITY',
        'KEYSTONE HEIGHTS',
        'POMONA PARK',
        'EAST PALATKA',
        'ORANGE MILLS',
        'BUFFALO BLUFF',
        'CYPRESS POINT',
        'FEDERAL POINT',
        'SAN MATEO',
      ];

      // Check if any multi-word city appears at the end of beforeComma
      String? foundCity;
      for (final city in multiWordCities) {
        if (beforeComma.toUpperCase().endsWith(city)) {
          foundCity = city;
          break;
        }
      }

      if (foundCity != null) {
        // Extract street address (everything before the city)
        final cityStartIndex = beforeComma.toUpperCase().lastIndexOf(foundCity);
        streetAddress = beforeComma.substring(0, cityStartIndex).trim();
        final city = beforeComma.substring(cityStartIndex).trim();
        cityStateZip = '$city, $afterComma';
      } else {
        // Single-word city - last word before comma
        final words = beforeComma.split(' ');
        if (words.length > 1) {
          final city = words.last;
          streetAddress = words.sublist(0, words.length - 1).join(' ');
          cityStateZip = '$city, $afterComma';
        } else {
          streetAddress = '';
          cityStateZip = '$beforeComma, $afterComma';
        }
      }
    } else {
      // No comma - try to find state code and work backwards
      final words = fullAddress.split(' ');
      int stateIndex = -1;

      // Look for 2-letter state code (FL, GA, etc.)
      for (int i = 0; i < words.length; i++) {
        if (words[i].length == 2 && words[i].toUpperCase() == words[i]) {
          stateIndex = i;
          break;
        }
      }

      if (stateIndex > 1) {
        // City is right before state
        final cityIndex = stateIndex - 1;
        streetAddress = words.sublist(0, cityIndex).join(' ');
        cityStateZip = words.sublist(cityIndex).join(' ');
      } else {
        // Can't parse - show as-is on one line
        streetAddress = fullAddress;
      }
    }

    return <Widget>[
      if (streetAddress.isNotEmpty)
        Text(
          streetAddress.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      if (streetAddress.isNotEmpty && cityStateZip.isNotEmpty)
        const SizedBox(height: 4),
      if (cityStateZip.isNotEmpty)
        Text(
          cityStateZip.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
    ];
  }
}

enum _CommentAction { edit, unpublish, report, viewBooking }
