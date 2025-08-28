import 'package:flutter/material.dart';

class AppBottomBar extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback? onRefresh;
  final VoidCallback? onOpenFilters;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onClearSearch;

  const AppBottomBar({
    super.key,
    required this.searchController,
    this.onRefresh,
    this.onOpenFilters,
    this.onSearchSubmitted,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).dividerColor;

    return Material(
      elevation: 6,
      color: barColor,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderColor)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              // Search
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSearchSubmitted,
                    decoration: InputDecoration(
                      hintText: 'Search news…',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: (searchController.text.isEmpty)
                          ? null
                          : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close),
                        onPressed: onClearSearch,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filters button (single entry point)
              OutlinedButton.icon(
                onPressed: onOpenFilters,
                icon: const Icon(Icons.tune),
                label: const Text('Filters'),
              ),
              const SizedBox(width: 4),
              // Refresh (optional)
              if (onRefresh != null)
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
