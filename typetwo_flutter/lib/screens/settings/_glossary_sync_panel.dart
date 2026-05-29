part of 'glossary_tab.dart';

String _syncTargetLabel(AppStrings s, String target) => switch (target) {
      GlossarySyncTargets.typeTwoServer => s.glossarySyncTargetTypeTwo,
      GlossarySyncTargets.webDav => s.glossarySyncTargetWebDav,
      GlossarySyncTargets.oneDrive => s.glossarySyncTargetOneDrive,
      GlossarySyncTargets.dropbox => s.glossarySyncTargetDropbox,
      GlossarySyncTargets.googleDrive => s.glossarySyncTargetGoogleDrive,
      GlossarySyncTargets.synologyDrive => s.glossarySyncTargetSynologyDrive,
      GlossarySyncTargets.fileServer => s.glossarySyncTargetFileServer,
      _ => target,
    };

class _GlossarySyncBar extends StatelessWidget {
  const _GlossarySyncBar({
    required this.s,
    required this.target,
    required this.targetOrder,
    required this.isSyncing,
    required this.canSync,
    required this.needsLogin,
    required this.lastSyncedAt,
    required this.pendingCount,
    required this.onTargetChanged,
    required this.onSync,
  });

  final AppStrings s;
  final String target;
  final List<String> targetOrder;
  final bool isSyncing;
  final bool canSync;
  final bool needsLogin;
  final String? lastSyncedAt;
  final int pendingCount;
  final ValueChanged<String> onTargetChanged;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final baseStatus = lastSyncedAt == null
        ? s.glossaryNeverSynced
        : s.glossaryLastSynced(lastSyncedAt!);
    final statusParts = [
      baseStatus,
      if (needsLogin) s.glossaryLoginRequired,
      if (pendingCount > 0) s.glossaryPendingCount(pendingCount),
    ];
    final status = statusParts.join(' · ');
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
            for (final t in targetOrder)
              DropdownMenuItem(
                value: t,
                child: Text(
                  _syncTargetLabel(s, t),
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
          onPressed: isSyncing || !canSync ? null : onSync,
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
