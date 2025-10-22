import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../../src/rust/models/repository.dart';
import '../../../../src/rust/api/git.dart' as rust_api;

class BulkCommitDialog extends HookConsumerWidget {
  final List<RepositoryInfo> repositories;

  const BulkCommitDialog({
    super.key,
    required this.repositories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final isCommitting = useState(false);
    final commitProgress = useState(0);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.commit),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bulk Commit'),
                Text(
                  '${repositories.length} repositories',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Enter commit message for all repositories',
                border: OutlineInputBorder(),
                helperText: 'This message will be used for all selected repositories',
              ),
              maxLines: 5,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            if (isCommitting.value) ...[
              LinearProgressIndicator(
                value: commitProgress.value / repositories.length,
              ),
              const SizedBox(height: 8),
              Text(
                'Committing ${commitProgress.value}/${repositories.length}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Selected repositories:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: repositories.length,
                itemBuilder: (context, idx) {
                  final repo = repositories[idx];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.folder_special, size: 16),
                    title: Text(repo.name),
                    subtitle: Text(
                      repo.path,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isCommitting.value
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: isCommitting.value
              ? null
              : () async {
                  final message = messageController.text.trim();
                  if (message.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a commit message'),
                      ),
                    );
                    return;
                  }

                  isCommitting.value = true;
                  try {
                    final paths = repositories.map((r) => r.path).toList();
                    final commitHashes = await rust_api.commitMultipleRepositories(
                      paths: paths,
                      message: message,
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Successfully committed ${commitHashes.length}/${repositories.length} repositories',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    isCommitting.value = false;
                    commitProgress.value = 0;
                  }
                },
          icon: isCommitting.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(isCommitting.value ? 'Committing...' : 'Commit All'),
        ),
      ],
    );
  }
}
