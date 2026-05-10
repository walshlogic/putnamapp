import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../extensions/build_context_extensions.dart';
import '../models/agency.dart';
import '../models/incident.dart';
import '../models/incident_attachment.dart';
import '../providers/incident_providers.dart';
import '../repositories/incident_repository.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

/// Create or edit an incident. Pass `incidentId` to edit; omit to create.
class IncidentEditScreen extends ConsumerStatefulWidget {
  const IncidentEditScreen({this.incidentId, super.key});

  final String? incidentId;

  @override
  ConsumerState<IncidentEditScreen> createState() =>
      _IncidentEditScreenState();
}

class _IncidentEditScreenState extends ConsumerState<IncidentEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();
  final TextEditingController _bookingNoCtrl = TextEditingController();

  DateTime _occurredAt = DateTime.now();
  String? _category;
  String? _agencyId;
  bool _loading = false;
  bool _loadedFromExisting = false;
  Incident? _existing;

  bool get _isEdit => widget.incidentId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final Incident inc = await ref
          .read(incidentRepositoryProvider)
          .getIncidentById(widget.incidentId!);
      if (!mounted) return;
      setState(() {
        _existing = inc;
        _titleCtrl.text = inc.title;
        _descCtrl.text = inc.description;
        _locationCtrl.text = inc.locationText;
        _latCtrl.text = inc.latitude?.toString() ?? '';
        _lngCtrl.text = inc.longitude?.toString() ?? '';
        _bookingNoCtrl.text = inc.relatedBookingNo ?? '';
        _occurredAt = inc.occurredAt.toLocal();
        _category = inc.category;
        _agencyId = inc.agencyId;
        _loadedFromExisting = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _bookingNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !mounted) return;
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (t == null || !mounted) return;
    setState(() {
      _occurredAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final IncidentRepository repo = ref.read(incidentRepositoryProvider);
    try {
      final double? lat = double.tryParse(_latCtrl.text.trim());
      final double? lng = double.tryParse(_lngCtrl.text.trim());

      if (_isEdit && _existing != null) {
        final Incident updated = _existing!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          occurredAt: _occurredAt,
          locationText: _locationCtrl.text.trim(),
          latitude: lat,
          longitude: lng,
          category: _category,
          agencyId: _agencyId,
          relatedBookingNo: _bookingNoCtrl.text.trim().isEmpty
              ? null
              : _bookingNoCtrl.text.trim(),
        );
        await repo.updateIncident(updated);
      } else {
        final Incident draft = Incident(
          id: '', // server-generated
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          occurredAt: _occurredAt,
          locationText: _locationCtrl.text.trim(),
          latitude: lat,
          longitude: lng,
          category: _category,
          agencyId: _agencyId,
          relatedBookingNo: _bookingNoCtrl.text.trim().isEmpty
              ? null
              : _bookingNoCtrl.text.trim(),
        );
        final String newId = await repo.createIncident(draft);
        if (!mounted) return;
        // Load the new incident as "existing" so attachment buttons enable.
        setState(() {
          _existing = draft.copyWith(id: newId);
          _loadedFromExisting = true;
        });
      }
      if (!mounted) return;
      ref.invalidate(incidentsProvider);
      if (_existing != null) {
        ref.invalidate(incidentByIdProvider(_existing!.id));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          duration: const Duration(seconds: 12),
          showCloseIcon: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final DateFormat fmt = DateFormat('EEE, MMM d, y • h:mm a');

    return Scaffold(
      appBar: const PutnamAppBar(showBackButton: true),
      drawer: const AppDrawer(),
      endDrawer: const SettingsDrawer(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Text(
                    _isEdit ? 'EDIT INCIDENT' : 'NEW INCIDENT',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: appColors.primaryPurple,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 6,
                    minLines: 4,
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.event, size: 18),
                    label: Text('Occurred: ${fmt.format(_occurredAt)}'),
                    onPressed: _pickDateTime,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g. 200 N 6th St, Palatka FL',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _latCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Latitude (optional)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _lngCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Longitude (optional)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— None —'),
                      ),
                      ...IncidentCategory.all.map(
                        (String c) => DropdownMenuItem<String?>(
                          value: c,
                          child: Text(IncidentCategory.label(c)),
                        ),
                      ),
                    ],
                    onChanged: (String? v) => setState(() => _category = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _agencyId,
                    decoration: const InputDecoration(
                      labelText: 'Agency involved (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— None —'),
                      ),
                      ...Agency.all.map(
                        (Agency a) => DropdownMenuItem<String?>(
                          value: a.id,
                          child: Text(a.shortName),
                        ),
                      ),
                    ],
                    onChanged: (String? v) => setState(() => _agencyId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bookingNoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Related booking # (optional)',
                      hintText: 'e.g. 24-1234',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(_loading
                        ? 'Saving…'
                        : _isEdit
                            ? 'Save changes'
                            : 'Create incident'),
                  ),
                  if (_loadedFromExisting && _existing != null) ...<Widget>[
                    const SizedBox(height: 28),
                    _AttachmentsEditor(
                      incident: _existing!,
                      onChanged: () {
                        ref.invalidate(incidentByIdProvider(_existing!.id));
                        _loadExisting();
                      },
                    ),
                  ] else if (!_isEdit) ...<Widget>[
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.amber.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Save the incident first to add photos, videos, or links.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}

/// Below-the-form section: list current attachments and offer "add link"
/// and "add file" actions. Only visible after the incident has been saved
/// (we need its id to attach to).
class _AttachmentsEditor extends ConsumerStatefulWidget {
  const _AttachmentsEditor({required this.incident, required this.onChanged});
  final Incident incident;
  final VoidCallback onChanged;

  @override
  ConsumerState<_AttachmentsEditor> createState() =>
      _AttachmentsEditorState();
}

class _AttachmentsEditorState extends ConsumerState<_AttachmentsEditor> {
  bool _uploading = false;

  Future<void> _addUrl() async {
    final TextEditingController urlCtrl = TextEditingController();
    final TextEditingController titleCtrl = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Add link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://…',
              ),
              keyboardType: TextInputType.url,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Label (optional)',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (urlCtrl.text.trim().isEmpty) return;
    try {
      await ref.read(incidentRepositoryProvider).addUrlAttachment(
            incidentId: widget.incident.id,
            url: urlCtrl.text.trim(),
            title: titleCtrl.text.trim().isEmpty
                ? null
                : titleCtrl.text.trim(),
            sortOrder: widget.incident.attachments.length,
          );
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          duration: const Duration(seconds: 12),
          showCloseIcon: true,
        ),
      );
    }
  }

  Future<void> _addFile() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['jpg', 'jpeg', 'png', 'heic', 'webp',
        'mp4', 'mov', 'm4v', 'pdf'],
      withData: kIsWeb, // bytes are only needed on web; native uses path
    );
    if (result == null || result.files.isEmpty) return;
    final PlatformFile picked = result.files.first;
    setState(() => _uploading = true);
    try {
      final String filename = picked.name;
      final String mime = _mimeFor(filename);
      if (picked.path != null) {
        await ref.read(incidentRepositoryProvider).uploadFileFromPath(
              incidentId: widget.incident.id,
              filePath: picked.path!,
              mimeType: mime,
              sortOrder: widget.incident.attachments.length,
            );
      } else if (picked.bytes != null) {
        await ref.read(incidentRepositoryProvider).uploadFileAttachment(
              incidentId: widget.incident.id,
              bytes: picked.bytes!,
              filename: filename,
              mimeType: mime,
              sortOrder: widget.incident.attachments.length,
            );
      }
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          duration: const Duration(seconds: 12),
          showCloseIcon: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _mimeFor(String filename) {
    final String ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
      case 'qt':
        return 'video/quicktime';
      case 'm4v':
        return 'video/x-m4v';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _delete(IncidentAttachment att) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Remove attachment?'),
        content: Text(att.title ?? att.url,
            maxLines: 2, overflow: TextOverflow.ellipsis),
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
    try {
      await ref.read(incidentRepositoryProvider).deleteAttachment(att);
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          duration: const Duration(seconds: 12),
          showCloseIcon: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'ATTACHMENTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: appColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.incident.attachments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No attachments yet.',
                style: TextStyle(color: Colors.grey)),
          ),
        for (final IncidentAttachment a in widget.incident.attachments)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: Icon(
                a.kind == IncidentAttachmentKind.url
                    ? Icons.link
                    : a.isVideo
                        ? Icons.movie
                        : a.isImage
                            ? Icons.image
                            : a.isPdf
                                ? Icons.picture_as_pdf
                                : Icons.attach_file,
              ),
              title: Text(a.title?.isNotEmpty == true ? a.title! : a.url,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                a.kind == IncidentAttachmentKind.url ? 'External link' : 'File',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(a),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('Add link'),
                onPressed: _uploading ? null : _addUrl,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_uploading ? 'Uploading…' : 'Add file'),
                onPressed: _uploading ? null : _addFile,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
