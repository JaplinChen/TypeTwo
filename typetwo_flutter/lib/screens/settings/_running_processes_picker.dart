import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../platform/process_picker_service.dart';

class RestrictionModeSelector extends StatelessWidget {
  const RestrictionModeSelector({
    super.key,
    required this.s,
    required this.restricted,
    required this.onChanged,
  });

  final AppStrings s;
  final bool restricted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment<bool>(
              value: false,
              icon: const Icon(Icons.public, size: 18),
              label: Text(s.processModeAll),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: const Icon(Icons.lock_outline, size: 18),
              label: Text(s.processModeRestricted),
            ),
          ],
          selected: {restricted},
          onSelectionChanged: (value) => onChanged(value.first),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                restricted ? Icons.filter_alt_outlined : Icons.all_inclusive,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  restricted ? s.processModeRestrictedDesc : s.processModeAllDesc,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RunningProcessesPicker extends StatelessWidget {
  const RunningProcessesPicker({
    super.key,
    required this.s,
    required this.loading,
    required this.loadError,
    required this.processes,
    required this.allowedProcesses,
    required this.onAdd,
  });

  final AppStrings s;
  final bool loading;
  final String? loadError;
  final List<RunningProcessInfo> processes;
  final List<String> allowedProcesses;
  final void Function(String processName) onAdd;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (loadError != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          s.processDetectFailed,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    if (processes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(s.noRunningProcesses,
            style: const TextStyle(color: Colors.grey)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: processes.map((proc) {
          final added = allowedProcesses.any(
            (item) => item.toLowerCase() == proc.processName.toLowerCase(),
          );
          final label = proc.windowTitle.isEmpty
              ? proc.processName
              : '${proc.processName}  ·  ${proc.windowTitle}';
          return ActionChip(
            avatar: Icon(
              added ? Icons.check_circle : Icons.add_circle_outline,
              size: 18,
            ),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(label, overflow: TextOverflow.ellipsis),
            ),
            onPressed: added ? null : () => onAdd(proc.processName),
          );
        }).toList(),
      ),
    );
  }
}
