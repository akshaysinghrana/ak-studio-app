import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/presentation/widgets/media_tile.dart' show formatBytes;
import '../application/download_controller.dart';
import '../domain/download_task.dart';
import '../domain/download_variant.dart';

/// Opens the "Download from link" sheet: paste a page or direct media link,
/// then pick a quality (with its size) to download.
Future<void> showDownloadSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => const DownloadSheet(),
  );
}

class DownloadSheet extends ConsumerStatefulWidget {
  const DownloadSheet({super.key});

  @override
  ConsumerState<DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends ConsumerState<DownloadSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    ref.read(downloadControllerProvider.notifier).start(url);
    _controller.clear();
  }

  Future<void> _pasteAndGo() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _controller.text = text;
    _submit();
  }

  Future<void> _openFolder() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(downloadControllerProvider.notifier)
        .openDownloadFolder();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Downloads are saved in the Download/AS Media folder.'),
        ),
      );
    }
  }

  Future<void> _showInfo(DownloadTask task) async {
    final selected = task.selected;
    final rows = <(String, String)>[
      ('Title', task.title),
      if (selected != null) ('Quality', selected.label),
      if (task.receivedBytes > 0) ('Size', formatBytes(task.receivedBytes)),
      if (task.savedPath != null) ('Location', task.savedPath!),
    ];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      Expanded(child: SelectableText(value)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(DownloadTask task) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text(
          '"${task.title}" will be deleted from your phone and removed from '
          'the library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final deleted = await ref
        .read(downloadControllerProvider.notifier)
        .deleteSaved(task.id);
    if (!deleted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete the file.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(downloadControllerProvider);
    final controller = ref.read(downloadControllerProvider.notifier);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Download from link', style: text.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Paste a video page or a direct .mp4 / .m3u8 / .mpd link. '
                      'The app finds the video and shows each quality with its '
                      'size.',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.go,
                        autocorrect: false,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: 'https://…',
                          isDense: true,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.link_rounded),
                          suffixIcon: IconButton(
                            tooltip: 'Paste and fetch',
                            icon: const Icon(Icons.content_paste_go_rounded),
                            onPressed: _pasteAndGo,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Fetch'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: tasks.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Text(
                          'Finished downloads are saved to Download/AS Media on '
                          'your phone and appear in your library.',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                        itemCount: tasks.length,
                        itemBuilder: (context, i) => _TaskCard(
                          task: tasks[i],
                          onDownload: (variant) =>
                              controller.download(tasks[i].id, variant),
                          onCancel: () => controller.cancel(tasks[i].id),
                          onPause: () => controller.pause(tasks[i].id),
                          onResume: () => controller.resume(tasks[i].id),
                          onRemove: () => controller.remove(tasks[i].id),
                          onRetry: () => controller.retry(tasks[i].id),
                          onOpenFolder: _openFolder,
                          onInfo: () => _showInfo(tasks[i]),
                          onDelete: () => _delete(tasks[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatefulWidget {
  const _TaskCard({
    required this.task,
    required this.onDownload,
    required this.onCancel,
    required this.onPause,
    required this.onResume,
    required this.onRemove,
    required this.onRetry,
    required this.onOpenFolder,
    required this.onInfo,
    required this.onDelete,
  });

  final DownloadTask task;
  final void Function(DownloadVariant) onDownload;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRemove;
  final VoidCallback onRetry;
  final VoidCallback onOpenFolder;
  final VoidCallback onInfo;
  final VoidCallback onDelete;

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  DownloadVariant? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.task.selected;
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: task.isActive ? null : widget.onRemove,
                ),
              ],
            ),
            ..._body(context, task),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, DownloadTask task) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    switch (task.status) {
      case DownloadStatus.resolving:
        return const [
          SizedBox(height: 4),
          _BusyRow(label: 'Looking for the video…'),
        ];
      case DownloadStatus.choosing:
        final picked = _picked;
        return [
          if (task.note != null) ...[
            const SizedBox(height: 2),
            Text(
              task.note!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 4),
          for (final variant in task.variants)
            _VariantTile(
              variant: variant,
              selected: identical(variant, picked),
              onTap: () => setState(() => _picked = variant),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: picked == null
                  ? null
                  : () => widget.onDownload(picked),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download'),
            ),
          ),
        ];
      case DownloadStatus.downloading:
      case DownloadStatus.paused:
        final paused = task.status == DownloadStatus.paused;
        final total = task.totalBytes;
        final speed = task.bytesPerSecond;
        final note = task.transferNote;
        final sizes =
            '${formatBytes(task.receivedBytes)}'
            '${total != null ? ' / ${formatBytes(total)}' : ''}';
        return [
          const SizedBox(height: 8),
          LinearProgressIndicator(
            // A paused bar with unknown size would otherwise keep animating.
            value: paused ? (task.progress ?? 0) : task.progress,
          ),
          const SizedBox(height: 6),
          Text(
            paused
                ? 'Paused  ·  $sizes'
                : note != null
                ? '$sizes  ·  $note'
                : '$sizes${speed > 0 ? '  ·  ${formatBytes(speed.round())}/s' : ''}',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel'),
              ),
              if (paused)
                FilledButton.tonalIcon(
                  onPressed: widget.onResume,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Resume'),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: widget.onPause,
                  icon: const Icon(Icons.pause_rounded, size: 18),
                  label: const Text('Pause'),
                ),
            ],
          ),
        ];
      case DownloadStatus.saving:
        return const [
          SizedBox(height: 4),
          _BusyRow(label: 'Saving to your library…'),
        ];
      case DownloadStatus.done:
        return [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saved to Download/AS Media.',
                  style: text.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: widget.onInfo,
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('Info'),
              ),
              TextButton.icon(
                onPressed: widget.onOpenFolder,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Show in folder'),
              ),
              TextButton.icon(
                onPressed: widget.onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: scheme.error,
                ),
                label: Text('Delete', style: TextStyle(color: scheme.error)),
              ),
            ],
          ),
        ];
      case DownloadStatus.failed:
        return [
          const SizedBox(height: 4),
          Text(
            task.error ?? 'Download failed.',
            style: text.bodySmall?.copyWith(color: scheme.error),
          ),
          if (task.selected != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ),
          ],
        ];
    }
  }
}

class _BusyRow extends StatelessWidget {
  const _BusyRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

class _VariantTile extends StatelessWidget {
  const _VariantTile({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final DownloadVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final size = variant.sizeBytes;
    final sizeLabel = size == null
        ? 'Size unknown'
        : '${variant.sizeIsEstimate ? '≈ ' : ''}${formatBytes(size)}'
              '${variant.sizeIsEstimate ? ' (estimated)' : ''}';
    final details = <String>[
      if (variant.resolution != null) variant.resolution!,
      sizeLabel,
    ];
    return ListTile(
      dense: true,
      selected: selected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(variant.label, style: text.bodyLarge),
      subtitle: Text(
        details.join('  ·  '),
        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      onTap: onTap,
    );
  }
}
