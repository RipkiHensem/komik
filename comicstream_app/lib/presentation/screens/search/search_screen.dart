import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/providers/providers.dart';
import '../../widgets/comic_card.dart';
import '../../widgets/genre_chip.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/error_view.dart';
import '../../widgets/hover_builder.dart';

/// Search screen with genre filters, format, status, and sorting
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchStateProvider).query,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      final current = ref.read(searchStateProvider);
      final newQuery = value.trim();
      if (current.query != newQuery) {
        ref.read(searchStateProvider.notifier).state =
            current.copyWith(query: newQuery);
      }
    });
    setState(() {});
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    final current = ref.read(searchStateProvider);
    ref.read(searchStateProvider.notifier).state = current.copyWith(query: '');
    setState(() {});
  }

  void _resetAllFilters() {
    _debounceTimer?.cancel();
    _searchController.clear();
    ref.read(searchStateProvider.notifier).state = const SearchState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchStateProvider);
    final comics = ref.watch(searchComicsProvider);

    // Keep controller in sync if query changed externally
    if (_searchController.text != searchState.query &&
        !FocusScope.of(context).hasFocus) {
      _searchController.text = searchState.query;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search Bar ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: searchState.query.isNotEmpty
                              ? AppColors.primary.withValues(alpha: 0.6)
                              : AppColors.glassBorder,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari judul, genre, format...',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: _onSearchChanged,
                        onSubmitted: (value) {
                          _debounceTimer?.cancel();
                          final current = ref.read(searchStateProvider);
                          ref.read(searchStateProvider.notifier).state =
                              current.copyWith(query: value.trim());
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter toggle
                  HoverWidget(
                    scale: 1.08,
                    onTap: () => setState(() => _showFilters = !_showFilters),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (_showFilters || searchState.hasActiveFilters)
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (_showFilters || searchState.hasActiveFilters)
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.glassBorder,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: (_showFilters || searchState.hasActiveFilters)
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          if (searchState.hasActiveFilters)
                            Positioned(
                              top: 9,
                              right: 9,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Filters Panel ─────────────────────────────────
            if (_showFilters) ...[
              const SizedBox(height: 12),
              _buildFiltersPanel(searchState),
            ],

            // ── Sort & Results Bar ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    comics.when(
                      data: (list) => searchState.selectedGenres.isNotEmpty
                          ? 'Genre "${searchState.selectedGenres.join(", ")}": ${list.length} komik'
                          : '${list.length} komik ditemukan',
                      loading: () => 'Memuat komik...',
                      error: (_, _) => 'Gagal memuat',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: searchState.selectedGenres.isNotEmpty
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: searchState.selectedGenres.isNotEmpty
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (searchState.hasActiveFilters) ...[
                    const SizedBox(width: 8),
                    HoverWidget(
                      scale: 1.08,
                      onTap: _resetAllFilters,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Sort dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: searchState.sortBy,
                        isDense: true,
                        dropdownColor: AppColors.card,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'latest',
                            child: Text('Terbaru'),
                          ),
                          DropdownMenuItem(
                            value: 'popular',
                            child: Text('Populer'),
                          ),
                          DropdownMenuItem(
                            value: 'rating',
                            child: Text('Rating'),
                          ),
                          DropdownMenuItem(
                            value: 'title',
                            child: Text('A-Z'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(searchStateProvider.notifier).state =
                                searchState.copyWith(sortBy: value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Results Grid ──────────────────────────────────
            Expanded(
              child: comics.when(
                data: (comicList) {
                  if (comicList.isEmpty) {
                    return EmptyView(
                      title: 'Tidak ada komik ditemukan',
                      subtitle: searchState.hasActiveFilters
                          ? (searchState.query.isNotEmpty
                              ? 'Tidak ada komik yang cocok dengan "${searchState.query}".'
                              : 'Tidak ada komik dengan filter yang dipilih.')
                          : 'Belum ada komik yang tersedia.',
                      icon: Icons.search_off_rounded,
                      action: searchState.hasActiveFilters
                          ? ElevatedButton.icon(
                              onPressed: _resetAllFilters,
                              icon: const Icon(
                                Icons.restart_alt_rounded,
                                size: 18,
                              ),
                              label: const Text('Tampilkan Semua Komik'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            )
                          : null,
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: comicList.length,
                    itemBuilder: (context, index) {
                      return ComicCard(
                        comic: comicList[index],
                        onTap: () =>
                            context.go('/comic/${comicList[index].id}'),
                      );
                    },
                  );
                },
                loading: () => const ComicGridShimmer(),
                error: (error, _) => ErrorView(
                  message: 'Gagal memuat hasil pencarian',
                  onRetry: () => ref.invalidate(searchComicsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersPanel(SearchState searchState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Reset button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter & Kategori',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (searchState.hasActiveFilters)
                HoverWidget(
                  scale: 1.08,
                  child: InkWell(
                    onTap: _resetAllFilters,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'Reset Semua',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Genre section
          Text(
            'Genre',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AppConstants.genres.map((genre) {
              final isSelected = searchState.selectedGenres.contains(genre);
              return GenreChip(
                label: genre,
                isSelected: isSelected,
                onTap: () {
                  final genres = Set<String>.from(searchState.selectedGenres);
                  if (isSelected) {
                    genres.remove(genre);
                  } else {
                    genres.add(genre);
                  }
                  ref.read(searchStateProvider.notifier).state =
                      searchState.copyWith(selectedGenres: genres);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Format & Status row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Format',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: AppConstants.formats.map((format) {
                        return GenreChip(
                          label: format,
                          isSelected: searchState.selectedFormat == format,
                          onTap: () {
                            ref.read(searchStateProvider.notifier).state =
                                searchState.copyWith(
                              selectedFormat:
                                  searchState.selectedFormat == format
                                      ? null
                                      : format,
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: AppConstants.statuses.map((status) {
                        return GenreChip(
                          label: status,
                          isSelected: searchState.selectedStatus == status,
                          onTap: () {
                            ref.read(searchStateProvider.notifier).state =
                                searchState.copyWith(
                              selectedStatus:
                                  searchState.selectedStatus == status
                                      ? null
                                      : status,
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
