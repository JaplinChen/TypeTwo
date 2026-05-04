part of 'engine_tab.dart';

extension _EngineFallbackModels on _EngineTabState {
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
}
