part of 'glossary_tab.dart';

class _GlossarySyncBar extends StatelessWidget {
  const _GlossarySyncBar({
    required this.s,
    required this.target,
    required this.isSyncing,
    required this.lastSyncedAt,
    required this.pendingCount,
    required this.onTargetChanged,
    required this.onSync,
  });

  final AppStrings s;
  final String target;
  final bool isSyncing;
  final String? lastSyncedAt;
  final int pendingCount;
  final ValueChanged<String> onTargetChanged;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final baseStatus = lastSyncedAt == null
        ? s.glossaryNeverSynced
        : s.glossaryLastSynced(lastSyncedAt!);
    final status = pendingCount > 0
        ? '$baseStatus · ${s.glossaryPendingCount(pendingCount)}'
        : baseStatus;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 620;
        final targetPicker = DropdownButtonFormField<String>(
          key: const ValueKey('glossarySyncTargetField'),
          value: GlossarySyncTargets.normalize(target),
          isExpanded: true,
          decoration: InputDecoration(
            labelText: s.glossarySyncTarget,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            DropdownMenuItem(
              value: GlossarySyncTargets.typeTwoServer,
              child: Text(
                s.glossarySyncTargetTypeTwo,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: GlossarySyncTargets.webDav,
              child: Text(
                s.glossarySyncTargetWebDav,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: GlossarySyncTargets.oneDrive,
              child: Text(
                s.glossarySyncTargetOneDrive,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: GlossarySyncTargets.dropbox,
              child: Text(
                s.glossarySyncTargetDropbox,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: GlossarySyncTargets.googleDrive,
              child: Text(
                s.glossarySyncTargetGoogleDrive,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: GlossarySyncTargets.synologyDrive,
              child: Text(
                s.glossarySyncTargetSynologyDrive,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: GlossarySyncTargets.localFolder,
              child: Text(
                s.glossarySyncTargetLocalFolder,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) onTargetChanged(value);
          },
        );
        final syncButton = FilledButton.icon(
          key: const ValueKey('glossarySyncButton'),
          onPressed: isSyncing ? null : onSync,
          icon: isSyncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync, size: 16),
          label: Text(s.glossarySync),
        );
        final statusText = Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              targetPicker,
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: statusText),
                const SizedBox(width: 8),
                syncButton,
              ]),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: 280, child: targetPicker),
            const SizedBox(width: 12),
            Expanded(child: statusText),
            const SizedBox(width: 12),
            syncButton,
          ],
        );
      },
    );
  }
}
