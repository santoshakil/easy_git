import 'package:flutter/material.dart';
import '../../../../src/rust/models/repository.dart';
import '../../../../core/theme/app_theme.dart';

class RepositoryCard extends StatelessWidget {
  final RepositoryInfo repo;
  final VoidCallback? onTap;
  final VoidCallback? onCommit;
  final VoidCallback? onPush;
  final VoidCallback? onPull;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onSelectionToggle;

  const RepositoryCard({
    super.key,
    required this.repo,
    this.onTap,
    this.onCommit,
    this.onPush,
    this.onPull,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: isSelected ? colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: isSelectionMode ? onSelectionToggle : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onSelectionToggle?.call(),
                    )
                  else
                    Icon(
                      Icons.folder_special,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      repo.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (repo.currentBranch != null)
                    Chip(
                      label: Text(repo.currentBranch!),
                      avatar: const Icon(Icons.call_split, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (onCommit != null && repo.isDirty)
                    IconButton(
                      icon: const Icon(Icons.commit),
                      onPressed: onCommit,
                      tooltip: 'Commit changes',
                      iconSize: 20,
                    ),
                  if (onPush != null && repo.ahead > 0)
                    IconButton(
                      icon: const Icon(Icons.cloud_upload),
                      onPressed: onPush,
                      tooltip: 'Push to remote',
                      iconSize: 20,
                    ),
                  if (onPull != null && repo.behind > 0)
                    IconButton(
                      icon: const Icon(Icons.cloud_download),
                      onPressed: onPull,
                      tooltip: 'Pull from remote',
                      iconSize: 20,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                repo.path,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha:0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (repo.uncommittedChanges > 0)
                    _StatusChip(
                      icon: Icons.edit,
                      label: '${repo.uncommittedChanges} modified',
                      color: colorScheme.modified,
                    ),
                  if (repo.untrackedFiles > 0)
                    _StatusChip(
                      icon: Icons.fiber_new,
                      label: '${repo.untrackedFiles} untracked',
                      color: colorScheme.untracked,
                    ),
                  if (repo.ahead > 0)
                    _StatusChip(
                      icon: Icons.cloud_upload,
                      label: '${repo.ahead} ahead',
                      color: colorScheme.warning,
                    ),
                  if (repo.behind > 0)
                    _StatusChip(
                      icon: Icons.cloud_download,
                      label: '${repo.behind} behind',
                      color: colorScheme.error,
                    ),
                  if (!repo.isDirty && repo.ahead == 0 && repo.behind == 0)
                    _StatusChip(
                      icon: Icons.check_circle,
                      label: 'Clean',
                      color: colorScheme.success,
                    ),
                ],
              ),
              if (repo.lastCommit != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.commit,
                      size: 16,
                      color: colorScheme.onSurface.withValues(alpha:0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        repo.lastCommit!.message.split('\n').first,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${repo.lastCommit!.author} • ${_formatTimestamp(repo.lastCommit!.timestamp)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha:0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: color.withValues(alpha:0.5)),
        backgroundColor: color.withValues(alpha:0.1),
      );
}
