import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../config/route_paths.dart';
import '../extensions/build_context_extensions.dart';
import '../models/agency.dart';
import '../models/incident.dart';
import '../models/incident_attachment.dart';
import '../providers/incident_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({required this.incidentId, super.key});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = context.appColors;
    final AsyncValue<Incident> async =
        ref.watch(incidentByIdProvider(incidentId));
    final AsyncValue<bool> canEditAsync =
        ref.watch(canEditIncidentsProvider);

    return Scaffold(
      appBar: PutnamAppBar(
        showBackButton: true,
        extraActions: <Widget>[
          canEditAsync.maybeWhen(
            data: (canEdit) => canEdit
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (String value) async {
                      if (value == 'edit') {
                        context.push(RoutePaths.incidentEdit,
                            extra: incidentId);
                      } else if (value == 'delete') {
                        await _confirmDelete(context, ref);
                      }
                    },
                    itemBuilder: (BuildContext _) =>
                        const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Remove'),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: async.when(
              data: (Incident incident) =>
                  _Body(incident: incident, appColors: appColors),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Failed to load incident:\n$e',
                      textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Remove incident?'),
        content: const Text(
            'This will hide the incident from the app. It can be restored from the Supabase dashboard.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;

    try {
      await ref
          .read(incidentRepositoryProvider)
          .deactivateIncident(incidentId);
      if (!context.mounted) return;
      ref.invalidate(incidentsProvider);
      ref.invalidate(incidentByIdProvider(incidentId));
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove: $e')),
      );
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.incident, required this.appColors});
  final Incident incident;
  final dynamic appColors;

  @override
  Widget build(BuildContext context) {
    final DateFormat fmt = DateFormat('EEEE, MMM d, y • h:mm a');
    final Agency? agency = incident.agencyId == null
        ? null
        : Agency.all.firstWhere(
            (Agency a) => a.id == incident.agencyId,
            orElse: () => Agency.all.first,
          );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // Header gradient
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[appColors.primaryPurple, appColors.darkPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(incident.title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: appColors.white)),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Icon(Icons.event, color: appColors.white, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fmt.format(incident.occurredAt.toLocal()),
                      style: TextStyle(
                          color: appColors.white.withValues(alpha: 0.95),
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Icon(Icons.place, color: appColors.white, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      incident.locationText,
                      style: TextStyle(
                          color: appColors.white.withValues(alpha: 0.95),
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: <Widget>[
            if (incident.category != null)
              Chip(
                avatar: const Icon(Icons.local_offer, size: 16),
                label: Text(IncidentCategory.label(incident.category!)),
              ),
            if (agency != null)
              Chip(
                avatar: Icon(agency.icon, size: 16),
                label: Text(agency.shortName),
              ),
            if (incident.relatedBookingNo != null &&
                incident.relatedBookingNo!.isNotEmpty)
              Chip(
                avatar: const Icon(Icons.gavel, size: 16),
                label: Text('Booking ${incident.relatedBookingNo}'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'DESCRIPTION',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6),
        ),
        const SizedBox(height: 6),
        Text(incident.description, style: const TextStyle(height: 1.4)),
        if (incident.attachments.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          const Text(
            'MEDIA & LINKS',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6),
          ),
          const SizedBox(height: 8),
          for (final IncidentAttachment a in incident.attachments) ...<Widget>[
            _AttachmentTile(att: a, appColors: appColors),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.att, required this.appColors});
  final IncidentAttachment att;
  final dynamic appColors;

  @override
  Widget build(BuildContext context) {
    if (att.kind == IncidentAttachmentKind.file && att.isVideo) {
      return _VideoPlayer(att: att);
    }
    if (att.kind == IncidentAttachmentKind.file && att.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(att.url, fit: BoxFit.cover),
      );
    }
    // Default: external link / PDF / unknown — render as tappable card.
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          att.isPdf
              ? Icons.picture_as_pdf
              : att.kind == IncidentAttachmentKind.url
                  ? Icons.link
                  : Icons.attach_file,
          color: appColors.primaryPurple,
        ),
        title: Text(
          att.title?.isNotEmpty == true ? att.title! : _domainOf(att.url),
        ),
        subtitle: Text(att.url,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () async {
          final Uri uri = Uri.parse(att.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  String _domainOf(String url) {
    try {
      return Uri.parse(url).host.isNotEmpty
          ? Uri.parse(url).host
          : url;
    } catch (_) {
      return url;
    }
  }
}

class _VideoPlayer extends StatefulWidget {
  const _VideoPlayer({required this.att});
  final IncidentAttachment att;

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _failed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final VideoPlayerController v =
          VideoPlayerController.networkUrl(Uri.parse(widget.att.url));
      await v.initialize();
      if (!mounted) {
        v.dispose();
        return;
      }
      setState(() {
        _video = v;
        _chewie = ChewieController(
          videoPlayerController: v,
          autoPlay: false,
          looping: false,
          aspectRatio: v.value.aspectRatio == 0 ? 16 / 9 : v.value.aspectRatio,
        );
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _failed = true;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: Text(widget.att.title ?? 'Video'),
          subtitle: Text('Failed to load video.\n$_error',
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      );
    }
    if (_chewie == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _chewie!.videoPlayerController.value.aspectRatio == 0
            ? 16 / 9
            : _chewie!.videoPlayerController.value.aspectRatio,
        child: Chewie(controller: _chewie!),
      ),
    );
  }
}
