import 'package:flutter/material.dart';

import '../extensions/build_context_extensions.dart';
import '../models/ori_record.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_footer.dart';
import '../widgets/putnam_app_bar.dart';
import '../widgets/settings_drawer.dart';

class OriRecordDetailScreen extends StatelessWidget {
  const OriRecordDetailScreen({super.key, required this.record});

  final OriRecord record;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
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
                _buildHeader(context, appColors),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  icon: Icons.people,
                  title: 'PARTIES',
                  rows: <_DetailRow>[
                    _DetailRow('From', record.fromParty ?? '—'),
                    _DetailRow('To', record.toParty ?? '—'),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSection(
                  context,
                  icon: Icons.description,
                  title: 'RECORD',
                  rows: <_DetailRow>[
                    _DetailRow('Instrument #', record.instrumentNumber),
                    _DetailRow('Book', record.bookNumber.toString()),
                    _DetailRow('Page', record.pageNumber.toString()),
                    _DetailRow(
                      'Type',
                      '${record.transactionDisplay}'
                          '${record.transactionCode != null ? ' (${record.transactionCode})' : ''}',
                    ),
                    _DetailRow(
                      'File date',
                      record.fileDate == null ? '—' : record.fileDateString,
                    ),
                  ],
                ),
                if (record.description != null &&
                    record.description!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _buildSection(
                    context,
                    icon: Icons.notes,
                    title: 'DESCRIPTION',
                    rows: <_DetailRow>[
                      _DetailRow('', record.description!),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic appColors) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            record.transactionDisplay.toUpperCase(),
            style: TextStyle(
              color: appColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            record.fileDateString.isEmpty
                ? 'Instrument #${record.instrumentNumber}'
                : '${record.fileDateString} · Instrument #${record.instrumentNumber}',
            style: TextStyle(
              color: appColors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<_DetailRow> rows,
  }) {
    final appColors = context.appColors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: appColors.lightPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: appColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: appColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final _DetailRow row in rows) ...<Widget>[
              _buildRow(context, row),
              if (row != rows.last) const Divider(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, _DetailRow row) {
    final appColors = context.appColors;
    if (row.label.isEmpty) {
      return Text(
        row.value,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 100,
          child: Text(
            row.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: appColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            row.value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _DetailRow {
  _DetailRow(this.label, this.value);
  final String label;
  final String value;
}
