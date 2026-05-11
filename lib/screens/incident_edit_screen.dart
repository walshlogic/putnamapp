import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../extensions/build_context_extensions.dart';
import '../models/agency.dart';
import '../models/incident.dart';
import '../models/incident_attachment.dart';
import '../models/incident_person.dart';
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

  DateTime _occurredAt = _todayLocal();
  String? _category;
  Set<String> _agencyIds = <String>{};
  bool _loading = false;
  bool _loadedFromExisting = false;
  Incident? _existing;

  bool get _isEdit => widget.incidentId != null;

  static DateTime _todayLocal() {
    final DateTime n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

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
        _occurredAt = DateTime(
            inc.occurredAt.year, inc.occurredAt.month, inc.occurredAt.day);
        _category = inc.category;
        _agencyIds = Set<String>.from(inc.agencyIds);
        _loadedFromExisting = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Failed to load: $e');
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null && mounted) {
      setState(() => _occurredAt = DateTime(d.year, d.month, d.day));
    }
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
          agencyIds: _agencyIds.toList(),
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
          agencyIds: _agencyIds.toList(),
        );
        final String newId = await repo.createIncident(draft);
        if (!mounted) return;
        // Re-fetch as full incident so persons/attachments lists are present.
        await _loadExistingId(newId);
      }
      if (!mounted) return;
      ref.invalidate(incidentsProvider);
      if (_existing != null) {
        ref.invalidate(incidentByIdProvider(_existing!.id));
      }
      _snack('Saved');
    } catch (e) {
      if (!mounted) return;
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Used after creating a new incident — re-fetch full row + relations so the
  /// "Persons" and "Attachments" sub-editors can open.
  Future<void> _loadExistingId(String id) async {
    try {
      final Incident inc =
          await ref.read(incidentRepositoryProvider).getIncidentById(id);
      if (!mounted) return;
      setState(() {
        _existing = inc;
        _loadedFromExisting = true;
      });
    } catch (_) {/* non-fatal; user can re-open */}
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 12),
        showCloseIcon: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final DateFormat fmt = DateFormat('EEEE, MMM d, y');

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
                    onPressed: _pickDate,
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
                  const SizedBox(height: 16),
                  _SectionTitle(
                      label: 'AGENCIES INVOLVED', appColors: appColors),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: Agency.all.map((Agency a) {
                      final bool selected = _agencyIds.contains(a.id);
                      return FilterChip(
                        label: Text(a.shortName),
                        selected: selected,
                        onSelected: (bool v) => setState(() {
                          if (v) {
                            _agencyIds.add(a.id);
                          } else {
                            _agencyIds.remove(a.id);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
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
                    _PersonsEditor(
                      incident: _existing!,
                      onChanged: () async {
                        if (_existing != null) {
                          await _loadExistingId(_existing!.id);
                          if (mounted) {
                            ref.invalidate(
                                incidentByIdProvider(_existing!.id));
                          }
                        }
                      },
                      snack: _snack,
                    ),
                    const SizedBox(height: 24),
                    _AttachmentsEditor(
                      incident: _existing!,
                      onChanged: () async {
                        if (_existing != null) {
                          await _loadExistingId(_existing!.id);
                          if (mounted) {
                            ref.invalidate(
                                incidentByIdProvider(_existing!.id));
                          }
                        }
                      },
                      snack: _snack,
                    ),
                  ] else if (!_isEdit) ...<Widget>[
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.amber.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Save the incident first to tag persons or add photos, videos, audio, or links.',
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.appColors});
  final String label;
  final dynamic appColors;
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: appColors.primaryPurple,
      ),
    );
  }
}

// ===================================================================
// Persons editor
// ===================================================================
class _PersonsEditor extends ConsumerStatefulWidget {
  const _PersonsEditor({
    required this.incident,
    required this.onChanged,
    required this.snack,
  });
  final Incident incident;
  final Future<void> Function() onChanged;
  final void Function(String) snack;

  @override
  ConsumerState<_PersonsEditor> createState() => _PersonsEditorState();
}

class _PersonsEditorState extends ConsumerState<_PersonsEditor> {
  bool _busy = false;

  Future<void> _addPerson() async {
    final TextEditingController bookingCtrl = TextEditingController();
    final TextEditingController mniCtrl = TextEditingController();
    final TextEditingController labelCtrl = TextEditingController();

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Add person'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                  'Enter any combination of Booking #, MNI #, and a label '
                  '(at least one is required).',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: bookingCtrl,
                decoration: const InputDecoration(labelText: 'Booking #'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: mniCtrl,
                decoration: const InputDecoration(labelText: 'MNI #'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label / role',
                  hintText: 'e.g. John Doe — driver',
                ),
              ),
            ],
          ),
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
    if (bookingCtrl.text.trim().isEmpty &&
        mniCtrl.text.trim().isEmpty &&
        labelCtrl.text.trim().isEmpty) {
      widget.snack('Enter at least one field.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(incidentRepositoryProvider).addPerson(
            incidentId: widget.incident.id,
            bookingNo: bookingCtrl.text,
            mniNo: mniCtrl.text,
            label: labelCtrl.text,
            sortOrder: widget.incident.persons.length,
          );
      await widget.onChanged();
    } catch (e) {
      widget.snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(IncidentPerson p) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Remove person?'),
        content: Text(p.displayName,
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
      await ref.read(incidentRepositoryProvider).deletePerson(p.id);
      await widget.onChanged();
    } catch (e) {
      widget.snack('Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionTitle(label: 'PERSONS TAGGED', appColors: appColors),
        const SizedBox(height: 8),
        if (widget.incident.persons.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No persons tagged yet.',
                style: TextStyle(color: Colors.grey)),
          ),
        for (final IncidentPerson p in widget.incident.persons)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.person_outline),
              title: Text(p.displayName,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: _personSubtitle(p),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _remove(p),
              ),
            ),
          ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          icon: const Icon(Icons.person_add),
          label: const Text('Add person'),
          onPressed: _busy ? null : _addPerson,
        ),
      ],
    );
  }

  Widget? _personSubtitle(IncidentPerson p) {
    final List<String> parts = <String>[];
    if (p.bookingNo != null && p.bookingNo!.isNotEmpty) {
      parts.add('Booking ${p.bookingNo}');
    }
    if (p.mniNo != null && p.mniNo!.isNotEmpty) {
      parts.add('MNI ${p.mniNo}');
    }
    if (parts.isEmpty) return null;
    return Text(parts.join(' • '), style: const TextStyle(fontSize: 11));
  }
}

// ===================================================================
// Attachments editor
// ===================================================================
class _AttachmentsEditor extends ConsumerStatefulWidget {
  const _AttachmentsEditor({
    required this.incident,
    required this.onChanged,
    required this.snack,
  });
  final Incident incident;
  final Future<void> Function() onChanged;
  final void Function(String) snack;

  @override
  ConsumerState<_AttachmentsEditor> createState() =>
      _AttachmentsEditorState();
}

class _AttachmentsEditorState extends ConsumerState<_AttachmentsEditor> {
  bool _uploading = false;

  Future<void> _addUrl() async {
    final TextEditingController urlCtrl = TextEditingController();
    final TextEditingController titleCtrl = TextEditingController();
    String type = IncidentDisplayType.other;
    String? suggestedType;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setStateDialog) =>
            AlertDialog(
          title: const Text('Add link'),
          content: SingleChildScrollView(
            child: Column(
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
                  onChanged: (String v) {
                    final String s =
                        IncidentAttachment.suggestDisplayType(url: v);
                    if (s != suggestedType) {
                      suggestedType = s;
                      setStateDialog(() => type = s);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title (required)',
                    hintText: 'e.g. News4Jax article',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: IncidentDisplayType.all
                      .map((String d) => DropdownMenuItem<String>(
                            value: d,
                            child: Text(IncidentDisplayType.label(d)),
                          ))
                      .toList(),
                  onChanged: (String? v) =>
                      setStateDialog(() => type = v ?? type),
                ),
              ],
            ),
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
      ),
    );
    if (ok != true) return;
    if (urlCtrl.text.trim().isEmpty || titleCtrl.text.trim().isEmpty) {
      widget.snack('URL and title are required.');
      return;
    }
    try {
      await ref.read(incidentRepositoryProvider).addUrlAttachment(
            incidentId: widget.incident.id,
            url: _normalizeUrl(urlCtrl.text.trim()),
            title: titleCtrl.text.trim(),
            displayType: type,
            sortOrder: widget.incident.attachments.length,
          );
      await widget.onChanged();
    } catch (e) {
      widget.snack('Failed: $e');
    }
  }

  /// Prepend https:// if the user-typed URL has no scheme. Doesn't try to
  /// validate the rest — Uri.parse + tap-to-open surface bad URLs at use time.
  String _normalizeUrl(String input) {
    final String s = input.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    return 'https://$s';
  }

  Future<void> _addFile() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>[
        'jpg', 'jpeg', 'png', 'heic', 'webp',
        'mp4', 'mov', 'm4v',
        'mp3', 'm4a', 'wav', 'aac',
        'pdf',
      ],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final PlatformFile picked = result.files.first;
    final String filename = picked.name;
    final String mime = _mimeFor(filename);
    final String suggested =
        IncidentAttachment.suggestDisplayType(mimeType: mime, url: filename);

    final _FileAddDialogResult? meta = await _askFileMeta(
      filename: filename,
      initialTitle: _deriveTitleFromFilename(filename),
      initialType: suggested,
    );
    if (meta == null) return;

    setState(() => _uploading = true);
    try {
      if (picked.path != null) {
        await ref.read(incidentRepositoryProvider).uploadFileFromPath(
              incidentId: widget.incident.id,
              filePath: picked.path!,
              mimeType: mime,
              title: meta.title,
              displayType: meta.type,
              sortOrder: widget.incident.attachments.length,
            );
      } else if (picked.bytes != null) {
        await ref.read(incidentRepositoryProvider).uploadFileAttachment(
              incidentId: widget.incident.id,
              bytes: picked.bytes!,
              filename: filename,
              mimeType: mime,
              title: meta.title,
              displayType: meta.type,
              sortOrder: widget.incident.attachments.length,
            );
      }
      await widget.onChanged();
    } catch (e) {
      widget.snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<_FileAddDialogResult?> _askFileMeta({
    required String filename,
    required String initialTitle,
    required String initialType,
  }) async {
    final TextEditingController titleCtrl =
        TextEditingController(text: initialTitle);
    String type = initialType;
    return showDialog<_FileAddDialogResult>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setStateDialog) =>
            AlertDialog(
          title: const Text('Name this file'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('File: $filename',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title (required)',
                    hintText: 'e.g. Video from Outside',
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: IncidentDisplayType.all
                      .map((String d) => DropdownMenuItem<String>(
                            value: d,
                            child: Text(IncidentDisplayType.label(d)),
                          ))
                      .toList(),
                  onChanged: (String? v) =>
                      setStateDialog(() => type = v ?? type),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.of(ctx)
                    .pop(_FileAddDialogResult(titleCtrl.text.trim(), type));
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  String _deriveTitleFromFilename(String filename) {
    final String base = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    // Replace underscores/hyphens with spaces and title-case lightly.
    final String cleaned = base.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    return cleaned;
  }

  Future<void> _editMeta(IncidentAttachment att) async {
    final TextEditingController titleCtrl =
        TextEditingController(text: att.title ?? '');
    final TextEditingController urlCtrl =
        TextEditingController(text: att.url);
    final bool isUrlKind = att.kind == IncidentAttachmentKind.url;
    String type = att.displayType;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setStateDialog) =>
            AlertDialog(
          title: const Text('Edit attachment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (att.bucketPath != null)
                  Text('File: ${att.bucketPath!.split('/').last}',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey)),
                if (isUrlKind) ...<Widget>[
                  TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL (required)',
                      hintText: 'https://…',
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title (required)',
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: !isUrlKind,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: IncidentDisplayType.all
                      .map((String d) => DropdownMenuItem<String>(
                            value: d,
                            child: Text(IncidentDisplayType.label(d)),
                          ))
                      .toList(),
                  onChanged: (String? v) =>
                      setStateDialog(() => type = v ?? type),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (titleCtrl.text.trim().isEmpty) {
      widget.snack('Title cannot be empty.');
      return;
    }
    String? normalizedUrl;
    if (isUrlKind) {
      final String raw = urlCtrl.text.trim();
      if (raw.isEmpty) {
        widget.snack('URL cannot be empty.');
        return;
      }
      normalizedUrl = _normalizeUrl(raw);
    }
    try {
      await ref.read(incidentRepositoryProvider).updateAttachmentMeta(
            attachmentId: att.id,
            title: titleCtrl.text.trim(),
            displayType: type,
            url: normalizedUrl,
          );
      await widget.onChanged();
    } catch (e) {
      widget.snack('Failed: $e');
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
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/x-m4a';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
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
        content: Text(att.displayLabel,
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
      await widget.onChanged();
    } catch (e) {
      widget.snack('Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionTitle(label: 'ATTACHMENTS', appColors: appColors),
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
              leading: Icon(_iconFor(a)),
              title: Text(a.displayLabel,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${IncidentDisplayType.label(a.displayType)} • '
                '${a.kind == IncidentAttachmentKind.url ? "Link" : "File"}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit title / type',
                    onPressed: () => _editMeta(a),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _delete(a),
                  ),
                ],
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

  IconData _iconFor(IncidentAttachment a) {
    switch (a.displayType) {
      case IncidentDisplayType.video:
        return Icons.movie;
      case IncidentDisplayType.audio:
        return Icons.audiotrack;
      case IncidentDisplayType.image:
        return Icons.image;
      case IncidentDisplayType.document:
        return a.isPdf ? Icons.picture_as_pdf : Icons.description;
      case IncidentDisplayType.news:
        return Icons.article;
      case IncidentDisplayType.social:
        return Icons.public;
      default:
        return a.kind == IncidentAttachmentKind.url
            ? Icons.link
            : Icons.attach_file;
    }
  }
}

class _FileAddDialogResult {
  _FileAddDialogResult(this.title, this.type);
  final String title;
  final String type;
}
