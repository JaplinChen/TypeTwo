import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../platform/process_picker_service.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';
import '_running_processes_picker.dart';

// Windows-only tab: restrict hotkey to specific process names
class ProcessesTab extends StatefulWidget {
  const ProcessesTab({super.key});

  @override
  State<ProcessesTab> createState() => _ProcessesTabState();
}

class _ProcessesTabState extends State<ProcessesTab> {
  final _entryCtrl = TextEditingController();
  List<RunningProcessInfo> _runningProcesses = const [];
  String? _foregroundProcess;
  String? _loadError;
  bool _loadingProcesses = false;

  @override
  void initState() {
    super.initState();
    _refreshProcessList();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshProcessList() async {
    setState(() {
      _loadingProcesses = true;
      _loadError = null;
    });
    try {
      final foreground = await ProcessPickerService.foregroundProcess();
      final running = await ProcessPickerService.listVisibleProcesses();
      if (!mounted) return;
      setState(() {
        _foregroundProcess = foreground;
        _runningProcesses = running;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'detect_failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingProcesses = false;
        });
      }
    }
  }

  String _normalizeProcessName(String raw) {
    var val = raw.trim();
    if (val.isEmpty) return '';
    val = val.replaceAll('"', '').replaceAll("'", '');
    val = val.replaceAll('\\', '/');
    if (val.contains('/')) {
      val = val.split('/').last;
    }
    return val.trim();
  }

  void _add([String? value]) {
    final val = _normalizeProcessName(value ?? _entryCtrl.text);
    if (val.isEmpty) return;
    final p = context.read<ConfigProvider>();
    final exists = p.config.allowedProcesses.any(
      (proc) => proc.toLowerCase() == val.toLowerCase(),
    );
    if (!exists) {
      p.update(p.config.copyWith(
        allowedProcesses: [...p.config.allowedProcesses, val],
      ));
    }
    if (value == null) {
      _entryCtrl.clear();
    }
    if (!p.config.restrictToAllowedProcesses) {
      p.update(p.config.copyWith(restrictToAllowedProcesses: true));
    }
  }

  Future<void> _pickExeFile() async {
    final s = context.read<LocaleProvider>().strings;
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: s.chooseExeFile,
      type: FileType.custom,
      allowedExtensions: const ['exe'],
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;
    _add(path);
  }

  void _delete(String proc) {
    final p = context.read<ConfigProvider>();
    p.update(p.config.copyWith(
      allowedProcesses:
          p.config.allowedProcesses.where((x) => x != proc).toList(),
    ));
  }

  void _clearAll() {
    final p = context.read<ConfigProvider>();
    p.update(p.config.copyWith(allowedProcesses: []));
  }

  void _setRestrictionMode(bool enabled) {
    final p = context.read<ConfigProvider>();
    p.update(p.config.copyWith(restrictToAllowedProcesses: enabled));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
    return Consumer<ConfigProvider>(builder: (_, prov, __) {
      final procs = prov.config.allowedProcesses;
      final restricted = prov.config.restrictToAllowedProcesses;
      final hotkey = [...prov.config.hotkeyModifiers, prov.config.hotkeyKey]
          .map((part) =>
              part.isEmpty ? part : part[0].toUpperCase() + part.substring(1))
          .join('+');
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.processesTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              s.processesDesc(hotkey),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            RestrictionModeSelector(
              s: s,
              restricted: restricted,
              onChanged: _setRestrictionMode,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    !restricted
                        ? s.processesEmpty
                        : procs.isEmpty
                            ? s.restrictedProcessesEmpty
                            : s.processesCount(procs.length),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                if (restricted && procs.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: Text(s.clear),
                  ),
              ],
            ),
            if (restricted) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if ((_foregroundProcess ?? '').isNotEmpty)
                    FilledButton.icon(
                      onPressed: () => _add(_foregroundProcess),
                      icon: const Icon(Icons.my_location_outlined, size: 18),
                      label: Text(
                        s.foregroundProcessLabel(_foregroundProcess!),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _loadingProcesses ? null : _refreshProcessList,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(s.refreshProcesses),
                  ),
                  OutlinedButton.icon(
                    onPressed: Platform.isWindows ? _pickExeFile : null,
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: Text(s.chooseExeFile),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _entryCtrl,
                    decoration: InputDecoration(
                      labelText: s.processName,
                      hintText: s.processHint,
                      helperText: s.processInputHelp,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _add, child: Text(s.add)),
              ]),
              const SizedBox(height: 16),
              Text(
                s.runningProcessesTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                s.runningProcessesDesc,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              RunningProcessesPicker(
                s: s,
                loading: _loadingProcesses,
                loadError: _loadError,
                processes: _runningProcesses,
                allowedProcesses: procs,
                onAdd: _add,
              ),
            ],
            Expanded(
              child: !restricted
                  ? Center(
                      child: Text(
                        s.processesEmpty,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : procs.isEmpty
                      ? Center(
                          child: Text(
                            s.restrictedProcessesEmpty,
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          itemCount: procs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.apps, size: 18),
                            title: Text(procs[i]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _delete(procs[i]),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      );
    });
  }
}
