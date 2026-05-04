part of 'engine_tab.dart';

extension _EngineTabBuilder on _EngineTabState {
  // ignore: invalid_use_of_protected_member
  void _set(VoidCallback fn) => setState(fn);

  Widget _buildProviderSection(String provider, AppStrings s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                _set(() {
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
        ],
      );

  List<Widget> _buildEndpointSection(
      String provider, bool showEndpoint, AppStrings s) {
    if (!showEndpoint) return const [];
    return [
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
    ];
  }

  Widget _buildModelSection(AppStrings s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      );

  Widget _buildFallbackModelsSection(String provider, AppStrings s) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      _set(() {
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
                              _set(() =>
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
        ],
      );

  Widget _buildThinkingMode(AppStrings s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              _set(() => _thinkingMode = v.first);
              _commit();
            },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      );

  List<Widget> _buildApiKeySection(
      String provider, bool showKey, bool showEndpoint, AppStrings s) {
    if (!showKey) return const [];
    return [
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
            label: Text(s.getApiKey,
                style: const TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    _set(() => _apiKeyVisible = !_apiKeyVisible),
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
    ];
  }

  Widget _buildTemperatureSection(AppStrings s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _sectionLabel(s.translationStyle),
          Row(children: [
            Text(s.precise,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Expanded(
              child: Slider(
                value: _temperature.clamp(0.0, 1.0),
                onChanged: (v) {
                  _set(() => _temperature = v);
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

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child:
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

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
}
