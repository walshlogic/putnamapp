import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../extensions/build_context_extensions.dart';
import '../models/booking.dart';
import '../providers/booking_providers.dart';
import '../widgets/putnam_app_bar.dart';

class BookingPhotoProgressionScreen extends ConsumerStatefulWidget {
  const BookingPhotoProgressionScreen({super.key, required this.booking});

  final JailBooking booking;

  @override
  ConsumerState<BookingPhotoProgressionScreen> createState() =>
      _BookingPhotoProgressionScreenState();
}

class _BookingPhotoProgressionScreenState
    extends ConsumerState<BookingPhotoProgressionScreen> {
  final PageController _pageController = PageController();
  Timer? _timer;
  bool _isPlaying = false;
  bool _isPreloading = false;
  bool _userPaused = false;
  int _currentIndex = 0;
  final Set<String> _preloadedUrls = <String>{};
  String? _lastPreloadKey;
  static const int _maxFrames = 30;

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startPlayback(int frameCount) {
    if (frameCount <= 1) return;
    if (_userPaused) return;
    if (_isPlaying) return;
    setState(() {
      _isPlaying = true;
    });
    _timer?.cancel();
    // Use equal timer + animation duration for seamless flow.
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (frameCount == 0) return;
      final nextIndex = (_currentIndex + 1) % frameCount;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 700),
        curve: Curves.linear,
      );
    });
  }

  void _pausePlayback() {
    if (!_isPlaying) return;
    _timer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  void _togglePlayback(int frameCount) {
    if (frameCount <= 1) return;
    if (_isPlaying) {
      _userPaused = true;
      _pausePlayback();
      return;
    }
    _userPaused = false;
    _startPlayback(frameCount);
  }

  Future<void> _preloadFrames(
    List<_PhotoFrame> frames,
    BuildContext context,
  ) async {
    if (_isPreloading) return;
    final List<String> toPreload = frames
        .map((frame) => frame.photoUrl)
        .where((url) => !_preloadedUrls.contains(url))
        .toList();
    if (toPreload.isEmpty) {
      _startPlayback(frames.length);
      return;
    }
    setState(() {
      _isPreloading = true;
    });
    try {
      await Future.wait(
        toPreload.map((url) => precacheImage(NetworkImage(url), context)),
      );
      _preloadedUrls.addAll(toPreload);
    } catch (_) {
      // Ignore cache errors and continue with playback.
    } finally {
      if (!mounted) return;
      setState(() {
        _isPreloading = false;
      });
      _startPlayback(frames.length);
    }
  }

  List<_PhotoFrame> _buildFrames(List<JailBooking> bookings) {
    final List<JailBooking> sorted = List<JailBooking>.from(bookings)
      ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
    final Set<String> seenUrls = <String>{};
    final List<_PhotoFrame> frames = <_PhotoFrame>[];
    for (final booking in sorted) {
      if (booking.photoUrl.isEmpty) continue;
      if (seenUrls.contains(booking.photoUrl)) continue;
      seenUrls.add(booking.photoUrl);
      frames.add(
        _PhotoFrame(
          bookingNo: booking.bookingNo,
          photoUrl: booking.photoUrl,
          bookingDate: booking.bookingDate,
          ageAtBooking: booking.ageOnBookingDate,
        ),
      );
    }
    if (frames.length > _maxFrames) {
      return frames.sublist(frames.length - _maxFrames);
    }
    return frames;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final asyncBookings = widget.booking.mniNo.isNotEmpty
        ? ref.watch(bookingsByMniProvider(widget.booking.mniNo))
        : ref.watch(bookingsByNameProvider(widget.booking.name));

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      body: asyncBookings.when(
        data: (bookings) {
          final frames = _buildFrames(bookings);
          if (frames.isEmpty) {
            return Center(
              child: Text(
                'NO PHOTOS AVAILABLE',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          final preloadKey =
              '${frames.length}:${frames.first.bookingNo}:${frames.last.bookingNo}';
          if (_lastPreloadKey != preloadKey) {
            _lastPreloadKey = preloadKey;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _preloadFrames(frames, context);
            });
          }
          return Column(
            children: <Widget>[
              const SizedBox(height: 16),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.width * 0.9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Listener(
                    onPointerDown: (_) {
                      _userPaused = true;
                      _pausePlayback();
                    },
                    onPointerUp: (_) {},
                    onPointerCancel: (_) {},
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: frames.length,
                      allowImplicitScrolling: true,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final frame = frames[index];
                        return Image.network(
                          frame.photoUrl,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.high,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: appColors.lightPurple,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (_isPreloading) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'LOADING PHOTOS...',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: appColors.textLight),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                frames[_currentIndex].label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: appColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle,
                  color: appColors.primaryPurple,
                  size: 90,
                ),
                iconSize: 90,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 90, minHeight: 90),
                onPressed: () => _togglePlayback(frames.length),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Slider(
                      value: _currentIndex.toDouble(),
                      min: 0,
                      max: (frames.length - 1).toDouble(),
                      onChangeStart: (_) {
                        _userPaused = true;
                        _pausePlayback();
                      },
                      onChanged: (value) {
                        final index = value.round();
                        _pageController.jumpToPage(index);
                      },
                      activeColor: appColors.primaryPurple,
                      inactiveColor: appColors.border,
                    ),
                  ),
                ],
              ),
              Text(
                '${_currentIndex + 1}/${frames.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: appColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              IconButton(
                icon: const Icon(Icons.close),
                color: appColors.primaryPurple,
                iconSize: 60,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 72, minHeight: 72),
                style: IconButton.styleFrom(
                  backgroundColor: appColors.white,
                  shape: const CircleBorder(),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load progression: $e',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _PhotoFrame {
  _PhotoFrame({
    required this.bookingNo,
    required this.photoUrl,
    required this.bookingDate,
    required this.ageAtBooking,
  });

  final String bookingNo;
  final String photoUrl;
  final DateTime bookingDate;
  final int? ageAtBooking;

  String get label {
    final dateLabel =
        '${bookingDate.month}/${bookingDate.day}/${bookingDate.year}';
    if (ageAtBooking == null) {
      return dateLabel;
    }
    return '$dateLabel  |  AGE:$ageAtBooking';
  }
}
