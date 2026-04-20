import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_config.dart';
import '../../providers/config_provider.dart';
import '../../services/translate_service.dart';

const _providers = ['Ollama', 'OpenAI', 'Azure OpenAI', 'Gemini'];
const _needsApiKey = {'OpenAI', 'Azure OpenAI', 'Gemini'};

const _defaults = {
  'Ollama': (
    endpoint: 'http://127.0.0.1:11434/api/chat',
    model: 'translategemma'
  ),
  'OpenAI': (
    endpoint: 'https://api.openai.com/v1/chat/completions',
    model: 'gpt-4o'
  ),
  'Azure OpenAI': (
    endpoint:
        'https://<resource>.openai.azure.com/openai/deployments/<deployment>/chat/completions?api-version=2024-02-01',
    model: 'gpt-4o'
  ),
  'Gemini': (
    endpoint:
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    model: 'gemini-1.5-flash'
  ),
};

class EngineTab extends StatefulWidget {
  const EngineTab({super.key});

  @override
  State<EngineTab> createState() => _EngineTabState();
}

class _EngineTabState extends State<EngineTab> {
  late TextEditingController _endpoint;
  late TextEditingController _model;
  late TextEditingController _apiKey;
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
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  AppConfig get _cfg => context.read<ConfigProvider>().config;

  void _commit() {
    final provider = context.read<ConfigProvider>();
    provider.update(provider.config.copyWith(
      endpoint: _endpoint.text.trim(),
      model: _model.text.trim(),
      apiKey: _apiKey.text.trim(),
    ));
  }

  Future<void> _testConnection() async {
    _commit();
    setState(() {
      _connStatus = '測試中…';
      _connOk = false;
    });
    final (ok, msg) = await TranslateService.checkConnection(
        _cfg.provider, _endpoint.text.trim(), _apiKey.text.trim());
    setState(() {
      _connOk = ok;
      _connStatus = ok ? '✓ 正常' : '✗ 失敗: $msg';
    });
  }

  Future<void> _fetchModels() async {
    _commit();
    setState(() => _fetchingModels = true);
    try {
      final models = await TranslateService.fetchModels(
          _cfg.provider, _endpoint.text.trim(), _apiKey.text.trim());
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('找到 ${models.length} 個模型'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: ListView(
              children: models
                  .map((m) => ListTile(
                        dense: true,
                        title: Text(m),
                        onTap: () {
                          _model.text = m;
                          final p = context.read<ConfigProvider>();
                          p.update(p.config.copyWith(model: m));
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
        SnackBar(content: Text('取得模型失敗: $e')),
      );
    } finally {
      if (mounted) setState(() => _fetchingModels = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(
      builder: (_, prov, __) {
        final cfg = prov.config;
        final showKey = _needsApiKey.contains(cfg.provider);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('引擎類型'),
            DropdownButtonFormField<String>(
              value: cfg.provider,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _providers
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                final d = _defaults[v];
                if (d != null) {
                  _endpoint.text = d.endpoint;
                  _model.text = d.model;
                }
                prov.update(cfg.copyWith(
                  provider: v,
                  endpoint: d?.endpoint ?? cfg.endpoint,
                  model: d?.model ?? cfg.model,
                ));
              },
            ),
            const SizedBox(height: 16),
            _label('伺服器位址'),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _endpoint,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onChanged: (_) => _commit(),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _testConnection,
                child: const Text('測試連線'),
              ),
            ]),
            if (_connStatus.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _connStatus,
                style: TextStyle(color: _connOk ? Colors.green : Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            _label('模型名稱'),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _model,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
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
                    : const Text('取得模型'),
              ),
            ]),
            if (showKey) ...[
              const SizedBox(height: 16),
              _label('API 金鑰'),
              TextField(
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
            ],
            const SizedBox(height: 16),
            _label('翻譯風格（精準 ↔ 流暢）'),
            Row(children: [
              const Text('精準', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Expanded(
                child: Slider(
                  value: cfg.temperature.clamp(0.0, 1.0),
                  onChanged: (v) => prov.update(cfg.copyWith(temperature: v)),
                  onChangeEnd: (_) => _commit(),
                ),
              ),
              const Text('流暢', style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(
                width: 36,
                child: Text(
                  cfg.temperature.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ]),
          ],
        );
      },
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
