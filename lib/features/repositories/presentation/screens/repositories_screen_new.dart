import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:file_selector/file_selector.dart';
import '../providers/repositories_provider.dart';
import '../widgets/repository_detail_panel.dart';
import '../../../commits/presentation/widgets/bulk_commit_dialog.dart';
import '../../../../src/rust/models/repository.dart';
import '../../../../src/rust/api/git.dart' as rust_api;
import '../../../../core/storage/storage_provider.dart';
import '../../../../core/theme/app_theme.dart';

class RepositoriesScreenNew extends HookConsumerWidget {
  const RepositoriesScreenNew({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoPathsAsync = ref.watch(repositoriesProvider);
    final reposInfoAsync = ref.watch(repositoriesInfoProvider);
    final selectedRepo = useState<RepositoryInfo?>(null);
    final isSelectionMode = ref.watch(selectionModeProvider);
    final selectedRepos = ref.watch(selectedRepositoriesProvider);

    useEffect(() {
      var cancelled = false;
      Future.microtask(() async {
        if (cancelled) return;
        try {
          final storage = await ref.read(appStorageProvider.future);
          if (cancelled) return;
          final lastFolder = storage.getLastOpenedFolder();
          debugPrint('Loading last opened folder: $lastFolder');
          if (lastFolder != null && !cancelled) {
            await ref.read(repositoriesProvider.notifier).scan(lastFolder);
            if (cancelled) return;
            debugPrint('Successfully scanned last folder: $lastFolder');

            debugPrint('Getting repository info list');
            final repos = await ref.read(repositoriesInfoProvider.future);
            if (cancelled) return;
            debugPrint('Got ${repos.length} repositories');
            if (repos.isNotEmpty && !cancelled) {
              debugPrint('Fetching remote state for ${repos.length} repositories');
              try {
                await rust_api.fetchMultipleRepositories(
                  paths: repos.map((r) => r.path).toList(),
                );
                if (cancelled) return;
                debugPrint('Fetch completed successfully');
                ref.invalidate(repositoriesInfoProvider);
              } catch (fetchError, fetchStack) {
                if (!cancelled) {
                  debugPrint('Fetch error: $fetchError\n$fetchStack');
                }
              }
            } else {
              debugPrint('No repositories to fetch');
            }
          }
        } catch (e, stack) {
          if (!cancelled) {
            debugPrint('Error in useEffect: $e\n$stack');
          }
        }
      });
      return () => cancelled = true;
    }, []);

    return Scaffold(
      body: Column(
        children: [
          _buildToolbar(context, ref, reposInfoAsync, selectedRepos, isSelectionMode),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(context, ref, repoPathsAsync, reposInfoAsync, selectedRepo, isSelectionMode, selectedRepos),
                Expanded(
                  child: selectedRepo.value != null
                      ? RepositoryDetailPanel(repo: selectedRepo.value!)
                      : _buildEmptyState(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<RepositoryInfo>> reposInfoAsync,
    Set<String> selectedRepos,
    bool isSelectionMode,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
            Row(
              children: [
                Text(
                  'Easy Git',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 24),
                if (isSelectionMode) ...[
                  Chip(
                    label: Text('${selectedRepos.length} selected'),
                    onDeleted: () {
                      ref.read(selectedRepositoriesProvider.notifier).clear();
                      ref.read(selectionModeProvider.notifier).set(false);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            reposInfoAsync.when(
            data: (repos) {
              return Row(
                children: [
                  if (repos.isNotEmpty) ...[
                    if (!isSelectionMode) ...[
                      FilledButton.tonalIcon(
                        onPressed: () => _syncAll(context, ref, repos),
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync All'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: () => _commitAll(context, ref, repos),
                        icon: const Icon(Icons.commit),
                        label: const Text('Commit All'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: () => _pushAll(context, ref, repos),
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Push All'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: () => _pullAll(context, ref, repos),
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('Pull All'),
                      ),
                      const SizedBox(width: 8),
                      if (repos.any((r) => r.isDirty))
                        FilledButton.tonalIcon(
                          onPressed: () => _discardAll(context, ref, repos),
                          icon: const Icon(Icons.delete_sweep),
                          label: const Text('Discard All'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                            foregroundColor: Colors.red,
                          ),
                        ),
                      if (repos.any((r) => r.isDirty)) const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.checklist),
                        onPressed: () {
                          ref.read(selectionModeProvider.notifier).set(true);
                        },
                        tooltip: 'Selection mode',
                      ),
                    ] else ...[
                      FilledButton.tonalIcon(
                        onPressed: selectedRepos.isEmpty
                            ? null
                            : () => _commitSelected(context, ref, repos, selectedRepos),
                        icon: const Icon(Icons.commit),
                        label: const Text('Commit Selected'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: selectedRepos.isEmpty
                            ? null
                            : () => _pushSelected(context, ref, selectedRepos),
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Push Selected'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: selectedRepos.isEmpty
                            ? null
                            : () => _pullSelected(context, ref, selectedRepos),
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('Pull Selected'),
                      ),
                    ],
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        try {
                          final allRepos = await ref.read(repositoriesInfoProvider.future);
                          if (allRepos.isNotEmpty) {
                            await rust_api.fetchMultipleRepositories(
                              paths: allRepos.map((r) => r.path).toList(),
                            );
                          }
                        } catch (e) {
                          debugPrint('Fetch error: $e');
                        } finally {
                          ref.invalidate(repositoriesInfoProvider);
                        }
                      },
                      tooltip: 'Refresh all',
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () => _openFolder(context, ref),
                    tooltip: 'Open folder',
                  ),
                ],
              );
            },
            loading: () => Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () => _openFolder(context, ref),
                  tooltip: 'Open folder',
                ),
              ],
            ),
            error: (_, _) => Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () => _openFolder(context, ref),
                  tooltip: 'Open folder',
                ),
              ],
            ),
          ),
        ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<String>> repoPathsAsync,
    AsyncValue<List<RepositoryInfo>> reposInfoAsync,
    ValueNotifier<RepositoryInfo?> selectedRepo,
    bool isSelectionMode,
    Set<String> selectedRepos,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: repoPathsAsync.when(
        data: (repoPaths) {
          if (repoPaths.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 64,
                      color: colorScheme.primary.withValues(alpha:0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No repositories',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Open a folder to get started',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _openFolder(context, ref),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Open Folder'),
                    ),
                  ],
                ),
              ),
            );
          }

          return reposInfoAsync.when(
            data: (repos) {
              if (repos.isEmpty) {
                return const Center(child: Text('No repositories found'));
              }

              final sortedRepos = _sortRepositories(repos);
              final needsAttention = sortedRepos.where((r) => r.isDirty || r.ahead > 0 || r.behind > 0).toList();
              final clean = sortedRepos.where((r) => !r.isDirty && r.ahead == 0 && r.behind == 0).toList();

              return ListView(
                children: [
                  if (needsAttention.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Needs Attention',
                      count: needsAttention.length,
                      color: colorScheme.error,
                    ),
                    ...needsAttention.map((repo) {
                      final isSelected = selectedRepo.value?.path == repo.path;
                      final isChecked = selectedRepos.contains(repo.path);
                      return _buildRepoItem(context, ref, repo, isSelected, isChecked, isSelectionMode, selectedRepo, colorScheme, theme);
                    }),
                  ],
                  if (clean.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Clean',
                      count: clean.length,
                      color: colorScheme.success,
                    ),
                    ...clean.map((repo) {
                      final isSelected = selectedRepo.value?.path == repo.path;
                      final isChecked = selectedRepos.contains(repo.path);
                      return _buildRepoItem(context, ref, repo, isSelected, isChecked, isSelectionMode, selectedRepo, colorScheme, theme);
                    }),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $err'),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $err'),
          ),
        ),
      ),
    );
  }

  List<RepositoryInfo> _sortRepositories(List<RepositoryInfo> repos) {
    final sorted = List<RepositoryInfo>.from(repos);
    sorted.sort((a, b) {
      final aNeedsAttention = a.isDirty || a.ahead > 0 || a.behind > 0;
      final bNeedsAttention = b.isDirty || b.ahead > 0 || b.behind > 0;

      if (aNeedsAttention && !bNeedsAttention) return -1;
      if (!aNeedsAttention && bNeedsAttention) return 1;

      if (aNeedsAttention && bNeedsAttention) {
        if (a.isDirty && !b.isDirty) return -1;
        if (!a.isDirty && b.isDirty) return 1;
        if (a.ahead > b.ahead) return -1;
        if (a.ahead < b.ahead) return 1;
        if (a.behind > b.behind) return -1;
        if (a.behind < b.behind) return 1;
      }

      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  Widget _buildRepoItem(
    BuildContext context,
    WidgetRef ref,
    RepositoryInfo repo,
    bool isSelected,
    bool isChecked,
    bool isSelectionMode,
    ValueNotifier<RepositoryInfo?> selectedRepo,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : isChecked
              ? colorScheme.secondaryContainer.withValues(alpha:0.5)
              : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isSelectionMode) {
            ref.read(selectedRepositoriesProvider.notifier).toggle(repo.path);
          } else {
            selectedRepo.value = repo;
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha:0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              if (isSelectionMode)
                Checkbox(
                  value: isChecked,
                  onChanged: (_) {
                    ref.read(selectedRepositoriesProvider.notifier).toggle(repo.path);
                  },
                )
              else
                Icon(
                  Icons.folder_special,
                  color: colorScheme.primary,
                  size: 20,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repo.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (repo.currentBranch != null)
                      Row(
                        children: [
                          Icon(
                            Icons.call_split,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            repo.currentBranch!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (repo.isDirty)
                          _SmallBadge(
                            icon: Icons.edit,
                            label: '${repo.uncommittedChanges}',
                            color: colorScheme.warning,
                          ),
                        if (repo.ahead > 0) ...[
                          const SizedBox(width: 4),
                          _SmallBadge(
                            icon: Icons.arrow_upward,
                            label: '${repo.ahead}',
                            color: colorScheme.warning,
                          ),
                        ],
                        if (repo.behind > 0) ...[
                          const SizedBox(width: 4),
                          _SmallBadge(
                            icon: Icons.arrow_downward,
                            label: '${repo.behind}',
                            color: colorScheme.error,
                          ),
                        ],
                        if (!repo.isDirty && repo.ahead == 0 && repo.behind == 0) ...[
                          const SizedBox(width: 4),
                          _SmallBadge(
                            icon: Icons.check,
                            label: 'clean',
                            color: colorScheme.success,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chevron_left,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha:0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a repository',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a repository from the sidebar to view details',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha:0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFolder(BuildContext context, WidgetRef ref) async {
    try {
      final path = await getDirectoryPath();
      if (path != null) {
        final storage = await ref.read(appStorageProvider.future);
        await storage.addRecentFolder(path);

        ref.read(selectedPathProvider.notifier).set(path);
        await ref.read(repositoriesProvider.notifier).scan(path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _syncAll(BuildContext context, WidgetRef ref, List<RepositoryInfo> repos) async {
    try {
      final allPaths = repos.map((r) => r.path).toList();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fetching remote changes for ${allPaths.length} repositories...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await rust_api.fetchMultipleRepositories(paths: allPaths);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pulling changes from ${allPaths.length} repositories...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await rust_api.pullMultipleRepositories(paths: allPaths);

      ref.invalidate(repositoriesInfoProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final updatedRepos = await ref.read(repositoriesInfoProvider.future);
      final reposNeedingPush = updatedRepos.where((r) => r.ahead > 0).toList();

      if (reposNeedingPush.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pushing changes to ${reposNeedingPush.length} repositories...'),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        await rust_api.pushMultipleRepositories(
          paths: reposNeedingPush.map((r) => r.path).toList(),
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synced all repositories'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(repositoriesInfoProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _commitAll(BuildContext context, WidgetRef ref, List<RepositoryInfo> repos) async {
    final dirtyRepos = repos.where((r) => r.isDirty).toList();
    if (dirtyRepos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No repositories with changes')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => BulkCommitDialog(repositories: dirtyRepos),
    );

    if (result == true && context.mounted) {
      ref.invalidate(repositoriesInfoProvider);
    }
  }

  Future<void> _pushAll(BuildContext context, WidgetRef ref, List<RepositoryInfo> repos) async {
    final reposNeedingPush = repos.where((r) => r.ahead > 0).toList();
    if (reposNeedingPush.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No repositories to push')),
      );
      return;
    }

    try {
      final results = await rust_api.pushMultipleRepositories(
        paths: reposNeedingPush.map((r) => r.path).toList(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pushed ${results.length}/${reposNeedingPush.length} repositories'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(repositoriesInfoProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Push failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pullAll(BuildContext context, WidgetRef ref, List<RepositoryInfo> repos) async {
    final reposNeedingPull = repos.where((r) => r.behind > 0).toList();
    if (reposNeedingPull.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No repositories to pull')),
      );
      return;
    }

    try {
      final results = await rust_api.pullMultipleRepositories(
        paths: reposNeedingPull.map((r) => r.path).toList(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pulled ${results.length}/${reposNeedingPull.length} repositories'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(repositoriesInfoProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pull failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _commitSelected(
    BuildContext context,
    WidgetRef ref,
    List<RepositoryInfo> allRepos,
    Set<String> selectedPaths,
  ) async {
    final selectedReposList = allRepos.where((r) => selectedPaths.contains(r.path) && r.isDirty).toList();
    if (selectedReposList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No selected repositories with changes')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => BulkCommitDialog(repositories: selectedReposList),
    );

    if (result == true && context.mounted) {
      ref.invalidate(repositoriesInfoProvider);
    }
  }

  Future<void> _pushSelected(BuildContext context, WidgetRef ref, Set<String> selectedPaths) async {
    try {
      final results = await rust_api.pushMultipleRepositories(
        paths: selectedPaths.toList(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pushed ${results.length}/${selectedPaths.length} repositories'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(repositoriesInfoProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Push failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pullSelected(BuildContext context, WidgetRef ref, Set<String> selectedPaths) async {
    try {
      final results = await rust_api.pullMultipleRepositories(
        paths: selectedPaths.toList(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pulled ${results.length}/${selectedPaths.length} repositories'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(repositoriesInfoProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pull failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _discardAll(BuildContext context, WidgetRef ref, List<RepositoryInfo> repos) async {
    final dirtyRepos = repos.where((r) => r.isDirty).toList();
    if (dirtyRepos.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _BulkDiscardConfirmationDialog(repositoryCount: dirtyRepos.length),
    );

    if (confirmed == true && context.mounted) {
      try {
        final results = await rust_api.discardMultipleRepositories(
          paths: dirtyRepos.map((r) => r.path).toList(),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Discarded changes in ${results.length}/${dirtyRepos.length} repositories'),
              backgroundColor: Colors.orange,
            ),
          );
          ref.invalidate(repositoriesInfoProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Discard failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha:0.1),
      child: Row(
        children: [
          Icon(
            title == 'Needs Attention' ? Icons.warning : Icons.check_circle,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SmallBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkDiscardConfirmationDialog extends StatefulWidget {
  final int repositoryCount;

  const _BulkDiscardConfirmationDialog({
    required this.repositoryCount,
  });

  @override
  State<_BulkDiscardConfirmationDialog> createState() => _BulkDiscardConfirmationDialogState();
}

class _BulkDiscardConfirmationDialogState extends State<_BulkDiscardConfirmationDialog> {
  final _controller = TextEditingController();
  var _isValid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(Icons.warning, size: 48, color: Colors.red),
      title: const Text('Discard All Changes?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will permanently delete all uncommitted changes in ${widget.repositoryCount} ${widget.repositoryCount == 1 ? 'repository' : 'repositories'}.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action cannot be undone!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Type "discard" to confirm:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'discard',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) {
              setState(() {
                _isValid = value.trim().toLowerCase() == 'discard';
              });
            },
            onSubmitted: (value) {
              if (_isValid) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            disabledBackgroundColor: Colors.grey,
          ),
          child: const Text('Discard All'),
        ),
      ],
    );
  }
}
