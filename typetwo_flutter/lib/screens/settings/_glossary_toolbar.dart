part of 'glossary_tab.dart';

class _GlossaryToolbar extends StatelessWidget {
  const _GlossaryToolbar({
    required this.s,
    required this.searchCtrl,
    required this.isSearching,
    required this.searchQuery,
    required this.totalCount,
    required this.visibleCount,
    required this.exportEnabled,
    required this.onImport,
    required this.onExport,
    required this.onClearSearch,
    required this.onSearchChanged,
  });

  final AppStrings s;
  final TextEditingController searchCtrl;
  final bool isSearching;
  final String searchQuery;
  final int totalCount;
  final int visibleCount;
  final bool exportEnabled;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 860;
          final buttons = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.upload_file, size: 16),
                label: Text(s.importTsv),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: exportEnabled ? onExport : null,
                icon: const Icon(Icons.download, size: 16),
                label: Text(s.exportTsv),
              ),
            ],
          );
          final count = Text(
            isSearching
                ? s.glossaryFilteredCount(visibleCount, totalCount)
                : s.glossaryCount(totalCount),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          );
          final search = SizedBox(
            width: isNarrow ? double.infinity : 280,
            child: TextField(
              key: const ValueKey('glossarySearchField'),
              controller: searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: isSearching
                    ? IconButton(
                        tooltip: s.clear,
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: onClearSearch,
                      )
                    : null,
                hintText: s.searchGlossary,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: onSearchChanged,
            ),
          );
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [buttons, const Spacer(), count]),
                const SizedBox(height: 8),
                search,
              ],
            );
          }
          return Row(
            children: [
              buttons,
              const SizedBox(width: 12),
              search,
              const Spacer(),
              count,
            ],
          );
        },
      ),
    );
  }
}
