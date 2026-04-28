import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_constants.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/provider_service.dart';

class EngineTab extends StatefulWidget {
  const EngineTab({super.key});

  @override
  State<EngineTab> createState() => _EngineTabState();
}

class _EngineTabState extends State<EngineTab> {
  late TextEditingController _endpoint;
  late TextEditingController _model;
  late TextEditingController _apiKey;
  late double _temperature;
  late String _thinkingMode;
  late List<String> _providerOrder;
  late List<String> _fallbackModelsList;
  bool _apiKeyVisible = false;
  String _connStatus = '';
  bool _connOk = false;
  bool _fetchingModels = false;

  @override
  void initState() {
    super.initState();
    final cfg = context.read<ConfigProvider>().config;
    _endpoint = TextEditingController(text: cfg.endpoint);
    _model = TextEditingController(text: cfg.model);
    _apiKey = TextEditingController(text: cfg.apiKey);
    _temperature = cfg.temperature;
    _thinkingMode = cfg.thinkingMode;
    _providerOrder = List<String>.from(cfg.providerOrder);
    _fallbackModelsList = List<String>.from(cfg.fallbackModels);
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  void _commit() {
    final p = context.read<ConfigProvider>();
    p.updateQuiet(p.config.copyWith(
      endpoint: _endpoint.text.trim(),
      model: _model.text.trim(),
      fallbackModels: List<String>.from(_fallbackModelsList),
      apiKey: _apiKey.text.trim(),
      temperature: _temperature,
      thinkingMode: _thinkingMode,
      providerOrder: List<String>.from(_providerOrder),
    ));
  }

  String _fallbackHint(String provider) {
    switch (provider.toLowerCase()) {
      case 'ollama':
        return 'translategemma:4b, translategemma:12b, qwen3:8b';
      case 'openai':
        return 'gpt-4.1-mini, gpt-4.1';
      case 'azure openai':
        return 'gpt-4.1-mini, gpt-4.1';
      case 'gemini':
        return 'gemini-2.0-flash, gemini-1.5-flash';
      default:
        return '';
    }
  }

  void _selectProvider(String v) {
    final d = kProviderDefaults[v];
    final fallbackDefaults = kProviderFallbackDefaults[v] ?? const <String>[];
    if (d != null) {
      _endpoint.text = d.endpoint;
      _model.text = d.model;
    }
    setState(() {
      _connStatus = '';
      _connOk = false;
      _fallbackModelsList = List<String>.from(fallbackDefaults);
    });
    final p = context.read<ConfigProvider>();
    p.update(p.config.copyWith(
      provider: v,
      endpoint: d?.endpoint ?? p.config.endpoint,
      model: d?.model ?? p.config.model,
      fallbackModels: fallbackDefaults,
      providerOrder: List<String>.from(_providerOrder),
    ));
  }

  Future<void> _editFallbackModel(int? index) async {
    final s = context.read<LocaleProvider>().strings;
    final ctrl = TextEditingController(
      text: index != null ? _fallbackModelsList[index] : '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(index != null ? _fallbackModelsList[index] : s.add),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result.isEmpty) return;
    setState(() {
      if (index != null) {
        _fallbackModelsList[index] = result;
      } else {
        _fallbackModelsList.add(result);
      }
    });
    _commit();
  }

  Future<void> _testConnection() async {
    final s = context.read<LocaleProvider>().strings;
    _commit();
    setState(() {
      _connStatus = s.testing;
      _connOk = false;
    });
    final cfg = context.read<ConfigProvider>().config;
    final (ok, msg) = await ProviderService.checkConnection(cfg.provider,
        _endpoint.text.trim(), _apiKey.text.trim(), _model.text.trim());
    setState(() {
      _connOk = ok;
      _connStatus = ok ? s.connOk : '${s.connFailed}$msg';
    });
  }

  Future<void> _fetchModels() async {
    final s = context.read<LocaleProvider>().strings;
    _commit();
    setState(() => _fetchingModels = true);
    try {
      final cfg = context.read<ConfigProvider>().config;
      final models = await ProviderService.fetchModels(
          cfg.provider, _endpoint.text.trim(), _apiKey.text.trim());
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(s.foundModels(models.length)),
          content: SizedBox(
            width: 300,
            height: 300,
            child: ListView(
              children: models
                  .map((m) => ListTile(
                        dense: true,
                        title: Text(m.$1),
                        subtitle: m.$2.isNotEmpty
                            ? Text(m.$2,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey))
                            : null,
                        onTap: () {
                          _model.text = m.$1;
                          final p = context.read<ConfigProvider>();
                          p.update(p.config.copyWith(model: m.$1));
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.getModelsFailed}$e')),
      );
    } finally {
      if (mounted) setState(() => _fetchingModels = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
    return Selector<ConfigProvider, String>(
      selector: (_, p) => p.config.provider,
      builder: (context, provider, __) {
        final showKey = kNeedsApiKey.contains(provider);
        final showEndpoint = !kNoEndpoint.contains(provider);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionLabel(s.engineType),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _providerOrder.removeAt(oldIndex);
                    _providerOrder.insert(newIndex, item);
                  });
                  _commit();
                },
                children: [
                  for (var i = 0; i < _providerOrder.length; i++)
                    ListTile(
                      key: ValueKey(_providerOrder[i]),
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      leading: ReorderableDragStartListener(
                        index: i,
                        child: const Icon(Icons.drag_handle,
                            color: Colors.grey, size: 20),
                      ),
                      title: Text(_providerOrder[i]),
                      trailing: _providerOrder[i] == provider
                          ? const Icon(Icons.check, size: 16)
                          : null,
                      onTap: () => _selectProvider(_providerOrder[i]),
                    ),
                ],
              ),
            ),
            if (showEndpoint) ...[
              const SizedBox(height: 16),
              _sectionLabel(s.serverAddress),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _endpoint,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    onChanged: (_) => _commit(),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _testConnection,
                  child: Text(s.testConnection),
                ),
              ]),
              if (_connStatus.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _connStatus,
                  style: TextStyle(color: _connOk ? Colors.green : Colors.red),
                ),
              ],
            ],
            const SizedBox(height: 16),
            _sectionLabel(s.modelName),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _model,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  onChanged: (_) => _commit(),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _fetchingModels ? null : _fetchModels,
                child: _fetchingModels
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(s.getModels),
              ),
            ]),
            const SizedBox(height: 16),
            _sectionLabel(s.fallbackModels),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  if (_fallbackModelsList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _fallbackHint(provider),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _fallbackModelsList.removeAt(oldIndex);
                          _fallbackModelsList.insert(newIndex, item);
                        });
                        _commit();
                      },
                      children: [
                        for (var i = 0; i < _fallbackModelsList.length; i++)
                          ListTile(
                            key: ValueKey('fb_${i}_${_fallbackModelsList[i]}'),
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            leading: ReorderableDragStartListener(
                              index: i,
                              child: const Icon(Icons.drag_handle,
                                  color: Colors.grey, size: 20),
                            ),
                            title: Text(_fallbackModelsList[i]),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                setState(() =>
                                    _fallbackModelsList.removeAt(i));
                                _commit();
                              },
                            ),
                            onTap: () => _editFallbackModel(i),
                          ),
                      ],
                    ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.add, size: 20),
                    title: Text(s.add),
                    onTap: () => _editFallbackModel(null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.fallbackModelsHint,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (provider.toLowerCase() == 'gemini') ...[
              const SizedBox(height: 16),
              _sectionLabel(s.translationMode),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'quick', label: Text(s.modeQuick)),
                  ButtonSegment(value: 'auto', label: Text(s.modeAuto)),
                  ButtonSegment(value: 'thinking', label: Text(s.modeThinking)),
                ],
                selected: {_thinkingMode},
                onSelectionChanged: (v) {
                  setState(() => _thinkingMode = v.first);
                  _commit();
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
            if (showKey) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _sectionLabel(s.apiKey)),
                if (kApiKeyUrls.containsKey(provider))
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(kApiKeyUrls[provider]!),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label:
                        Text(s.getApiKey, style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ]),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _apiKey,
                    obscureText: !_apiKeyVisible,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_apiKeyVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _apiKeyVisible = !_apiKeyVisible),
                      ),
                    ),
                    onChanged: (_) => _commit(),
                  ),
                ),
                if (!showEndpoint) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _testConnection,
                    child: Text(s.verify),
                  ),
                ],
              ]),
              if (!showEndpoint && _connStatus.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _connStatus,
                  style: TextStyle(color: _connOk ? Colors.green : Colors.red),
                ),
              ],
            ],
            const SizedBox(height: 16),
            _sectionLabel(s.translationStyle),
            Row(children: [
              Text(s.precise,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Expanded(
                child: Slider(
                  value: _temperature.clamp(0.0, 1.0),
                  onChanged: (v) {
                    setState(() => _temperature = v);
                    final p = context.read<ConfigProvider>();
                    p.updateQuiet(p.config.copyWith(temperature: v));
                  },
                  onChangeEnd: (_) => _commit(),
                ),
              ),
              Text(s.fluent,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(
                width: 36,
                child: Text(
                  _temperature.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ]),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
