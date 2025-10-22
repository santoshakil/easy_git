import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../src/rust/models/repository.dart';
import '../../../../src/rust/models/status.dart';
import '../../../../src/rust/api/git.dart' as rust_api;
import '../../../commits/presentation/widgets/commit_dialog.dart';
import '../providers/repositories_provider.dart';
import '../../../../core/theme/app_theme.dart';

class RepositoryDetailPanel extends ConsumerWidget {
  final RepositoryInfo repo;

  const RepositoryDetailPanel({super.key, required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        _buildCompactHeader(context, theme, colorScheme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _buildFileList(repo.files, theme, colorScheme),
              const SizedBox(height: 8),
              if (repo.behind > 0) ...[
                _buildRemoteChanges(repo.behind, theme, colorScheme),
                const SizedBox(height: 8),
              ],
              _buildQuickActions(context, ref, theme, colorScheme),
              if (repo.lastCommit != null) ...[
                const SizedBox(height: 8),
                _buildLastCommit(repo.lastCommit!, theme, colorScheme),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant),
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_special, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  repo.name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (repo.currentBranch != null)
                _Chip(
                  icon: Icons.call_split,
                  label: repo.currentBranch!,
                  color: colorScheme.tertiary,
                ),
              if (repo.isDirty)
                _Chip(
                  icon: Icons.edit,
                  label: '${repo.uncommittedChanges}',
                  color: colorScheme.warning,
                ),
              if (repo.ahead > 0)
                _Chip(
                  icon: Icons.arrow_upward,
                  label: '${repo.ahead}',
                  color: colorScheme.warning,
                ),
              if (repo.behind > 0)
                _Chip(
                  icon: Icons.arrow_downward,
                  label: '${repo.behind}',
                  color: colorScheme.error,
                ),
              if (!repo.isDirty && repo.ahead == 0 && repo.behind == 0)
                _Chip(
                  icon: Icons.check,
                  label: 'clean',
                  color: colorScheme.success,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(List<FileStatus> files, ThemeData theme, ColorScheme colorScheme) {
    if (files.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: colorScheme.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No changes',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.success),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final modified = files.where((f) => f.status == FileStatusKind.modified).toList();
    final untracked = files.where((f) => f.status == FileStatusKind.untracked).toList();
    final deleted = files.where((f) => f.status == FileStatusKind.deleted).toList();
    final renamed = files.where((f) => f.status == FileStatusKind.renamed).toList();
    final added = files.where((f) => f.status == FileStatusKind.added).toList();

    return Card(
      child: Column(
        children: [
          if (modified.isNotEmpty)
            _FileSection(
              title: 'Modified',
              count: modified.length,
              icon: Icons.edit,
              color: colorScheme.warning,
              files: modified,
            ),
          if (untracked.isNotEmpty)
            _FileSection(
              title: 'Untracked',
              count: untracked.length,
              icon: Icons.fiber_new,
              color: Colors.blue,
              files: untracked,
            ),
          if (added.isNotEmpty)
            _FileSection(
              title: 'Added',
              count: added.length,
              icon: Icons.add_circle,
              color: colorScheme.success,
              files: added,
            ),
          if (deleted.isNotEmpty)
            _FileSection(
              title: 'Deleted',
              count: deleted.length,
              icon: Icons.delete,
              color: colorScheme.error,
              files: deleted,
            ),
          if (renamed.isNotEmpty)
            _FileSection(
              title: 'Renamed',
              count: renamed.length,
              icon: Icons.drive_file_rename_outline,
              color: Colors.purple,
              files: renamed,
            ),
        ],
      ),
    );
  }

  Widget _buildRemoteChanges(int behindCount, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      color: colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_download, size: 18, color: colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Remote Changes Available',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_downward, size: 14, color: colorScheme.error),
                      const SizedBox(width: 4),
                      Text(
                        '$behindCount ${behindCount == 1 ? 'commit' : 'commits'} behind',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to get the latest changes from remote',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (repo.isDirty)
              _ActionButton(
                icon: Icons.commit,
                label: 'Commit',
                color: colorScheme.primary,
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => CommitDialog(
                      repoPath: repo.path,
                      repoName: repo.name,
                    ),
                  );
                  if (result == true && context.mounted) {
                    ref.invalidate(repositoriesInfoProvider);
                  }
                },
              ),
            if (repo.isDirty)
              _ActionButton(
                icon: Icons.delete_sweep,
                label: 'Discard',
                color: Colors.red,
                onPressed: () => _discardChanges(context, ref),
              ),
            if (repo.ahead > 0)
              _ActionButton(
                icon: Icons.cloud_upload,
                label: 'Push',
                color: colorScheme.warning,
                onPressed: () => _push(context, ref),
              ),
            if (repo.behind > 0)
              _ActionButton(
                icon: Icons.cloud_download,
                label: 'Pull',
                color: colorScheme.error,
                onPressed: () => _pull(context, ref),
              ),
            _ActionButton(
              icon: Icons.sync,
              label: 'Sync',
              color: colorScheme.tertiary,
              onPressed: () => _sync(context, ref),
            ),
            _ActionButton(
              icon: Icons.refresh,
              label: 'Refresh',
              color: colorScheme.onSurfaceVariant,
              onPressed: () => ref.invalidate(repositoriesInfoProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastCommit(CommitInfo commit, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.commit, size: 14, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  commit.shortHash,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(commit.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              commit.message.split('\n').first,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              commit.author,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _push(BuildContext context, WidgetRef ref) async {
    try {
      await rust_api.pushRepository(path: repo.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pushed successfully'), backgroundColor: Colors.green),
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

  Future<void> _pull(BuildContext context, WidgetRef ref) async {
    try {
      await rust_api.pullRepository(path: repo.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pulled successfully'), backgroundColor: Colors.green),
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

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    try {
      if (repo.behind > 0) await rust_api.pullRepository(path: repo.path);
      if (repo.ahead > 0) await rust_api.pushRepository(path: repo.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Synced successfully'), backgroundColor: Colors.green),
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

  Future<void> _discardChanges(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning, size: 48, color: Colors.orange),
        title: const Text('Discard Changes?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discard all uncommitted changes in:', style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              repo.name,
              style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'This cannot be undone!',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await rust_api.discardRepositoryChanges(path: repo.path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changes discarded'), backgroundColor: Colors.orange),
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

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileSection extends StatefulWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final List<FileStatus> files;

  const _FileSection({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.files,
  });

  @override
  State<_FileSection> createState() => _FileSectionState();
}

class _FileSectionState extends State<_FileSection> {
  var _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: widget.color.withValues(alpha:0.1),
            child: Row(
              children: [
                Icon(widget.icon, size: 14, color: widget.color),
                const SizedBox(width: 6),
                Text(
                  widget.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: widget.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: widget.color,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.files.map((file) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: widget.color, width: 2)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(_getFileIcon(file.path), size: 12, color: widget.color.withValues(alpha:0.7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      file.path,
                      style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  IconData _getFileIcon(String path) {
    if (path.endsWith('.dart')) return Icons.code;
    if (path.endsWith('.rs')) return Icons.code;
    if (path.endsWith('.json')) return Icons.data_object;
    if (path.endsWith('.yaml') || path.endsWith('.yml')) return Icons.settings;
    if (path.endsWith('.md')) return Icons.description;
    if (path.endsWith('.png') || path.endsWith('.jpg')) return Icons.image;
    return Icons.insert_drive_file;
  }
}

class _DiscardConfirmationDialog extends StatefulWidget {
  final String repoName;

  const _DiscardConfirmationDialog({required this.repoName});

  @override
  State<_DiscardConfirmationDialog> createState() => _DiscardConfirmationDialogState();
}

class _DiscardConfirmationDialogState extends State<_DiscardConfirmationDialog> {
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
            'This will permanently delete all uncommitted changes in:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            widget.repoName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This action cannot be undone!',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Type "discard" to confirm:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'discard',
              border: OutlineInputBorder(),
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
          onPressed: _isValid
              ? () => Navigator.of(context).pop(true)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            disabledBackgroundColor: Colors.red.withValues(alpha:0.3),
          ),
          child: const Text('Discard All'),
        ),
      ],
    );
  }
}
