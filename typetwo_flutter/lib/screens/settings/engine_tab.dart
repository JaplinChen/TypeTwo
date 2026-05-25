import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_constants.dart';
import '../../providers/config_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/provider_service.dart';

part 'engine_tab_builder.dart';
part '_engine_fallback_models.dart';

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
    final runtime = cfg.providerRuntime;
    _endpoint = TextEditingController(text: runtime.endpoint);
    _model = TextEditingController(text: runtime.model);
    _apiKey = TextEditingController(text: runtime.apiKey);
    _temperature = runtime.temperature;
    _thinkingMode = runtime.thinkingMode;
    _providerOrder = List<String>.from(runtime.providerOrder);
    _fallbackModelsList = List<String>.from(runtime.fallbackModels);
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
    final updatedConfigs = _providerConfigsWithCurrentDraft(p);
    p.updateQuiet(p.config.copyWith(
      endpoint: _endpoint.text.trim(),
      model: _model.text.trim(),
      fallbackModels: List<String>.from(_fallbackModelsList),
      apiKey: _apiKey.text.trim(),
      temperature: _temperature,
      thinkingMode: _thinkingMode,
      providerOrder: List<String>.from(_providerOrder),
      providerConfigs: updatedConfigs,
    ));
  }

  void _selectProvider(String v) {
    final p = context.read<ConfigProvider>();
    final updatedConfigs = _providerConfigsWithCurrentDraft(p);
    final saved = updatedConfigs[v];
    final d = kProviderDefaults[v];
    final fallbackDefaults = kProviderFallbackDefaults[v] ?? const <String>[];
    final newEndpoint = saved?['endpoint'] as String? ?? d?.endpoint ?? '';
    final newModel = saved?['model'] as String? ?? d?.model ?? '';
    final newApiKey = saved?['apiKey'] as String? ?? '';
    final newFallbacks = saved != null
        ? (saved['fallbackModels'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            List<String>.from(fallbackDefaults)
        : List<String>.from(fallbackDefaults);
    final newThinkingMode = saved?['thinkingMode'] as String? ?? 'quick';
    _endpoint.text = newEndpoint;
    _model.text = newModel;
    _apiKey.text = newApiKey;
    setState(() {
      _connStatus = '';
      _connOk = false;
      _fallbackModelsList = newFallbacks;
      _thinkingMode = newThinkingMode;
    });
    p.update(p.config.copyWith(
      provider: v,
      endpoint: newEndpoint,
      model: newModel,
      fallbackModels: newFallbacks,
      apiKey: newApiKey,
      thinkingMode: newThinkingMode,
      providerOrder: List<String>.from(_providerOrder),
      providerConfigs: updatedConfigs,
    ));
  }

  Map<String, Map<String, dynamic>> _providerConfigsWithCurrentDraft(
    ConfigProvider p,
  ) {
    final runtime = p.config.providerRuntime;
    return {
      for (final e in runtime.providerConfigs.entries)
        e.key: Map<String, dynamic>.from(e.value),
      runtime.provider: {
        'apiKey': _apiKey.text.trim(),
        'endpoint': _endpoint.text.trim(),
        'model': _model.text.trim(),
        'fallbackModels': List<String>.from(_fallbackModelsList),
        'thinkingMode': _thinkingMode,
      },
    };
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
    final runtime = cfg.providerRuntime;
    final (ok, msg) = await ProviderService.checkConnection(runtime.provider,
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
      final runtime = cfg.providerRuntime;
      final models = await ProviderService.fetchModels(
          runtime.provider, _endpoint.text.trim(), _apiKey.text.trim());
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
            _buildProviderSection(provider, s),
            ..._buildEndpointSection(provider, showEndpoint, s),
            _buildModelSection(s),
            _buildFallbackModelsSection(provider, s),
            if (provider.toLowerCase() == 'gemini') _buildThinkingMode(s),
            ..._buildApiKeySection(provider, showKey, showEndpoint, s),
            _buildTemperatureSection(s),
          ],
        );
      },
    );
  }
}
