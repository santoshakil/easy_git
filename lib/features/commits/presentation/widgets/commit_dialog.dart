import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../../src/rust/api/git.dart' as rust_api;

class CommitDialog extends HookConsumerWidget {
  final String repoPath;
  final String repoName;

  const CommitDialog({
    super.key,
    required this.repoPath,
    required this.repoName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final isCommitting = useState(false);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.commit),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Commit Changes'),
                Text(
                  repoName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Enter commit message',
                border: OutlineInputBorder(),
                helperText: 'Describe what you changed',
              ),
              maxLines: 5,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Repository: $repoPath',
              style: Theme.of(context).textTheme.bodySmall,
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
                    final commitHash = await rust_api.commitRepository(
                      path: repoPath,
                      message: message,
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Committed successfully: ${commitHash.substring(0, 7)}'),
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
                  }
                },
          icon: isCommitting.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(isCommitting.value ? 'Committing...' : 'Commit'),
        ),
      ],
    );
  }
}
