import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/board_service.dart';

class BoardScreen extends StatefulWidget {
  final String authorName;
  const BoardScreen({super.key, required this.authorName});
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final input = TextEditingController();
  bool saving = false;
  String? error;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> post() async {
    if (saving || input.text.trim().isEmpty) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await BoardService.instance.createMessage(input.text, widget.authorName);
      input.clear();
    } catch (e) {
      if (mounted) setState(() => error = AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> edit(String id, String old) async {
    final updated = await showDialog<String>(
      context: context,
      builder: (_) => _EditMessageDialog(initialText: old),
    );
    if (!mounted || updated == null) return;
    try {
      await BoardService.instance.editMessage(id, updated);
    } catch (e) {
      if (mounted) showError(e);
    }
  }

  Future<void> remove(String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await BoardService.instance.deleteMessage(id);
    } catch (e) {
      if (mounted) showError(e);
    }
  }

  void showError(Object e) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AuthService.errorMessage(e))));

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Board Vault'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: AuthService.instance.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    maxLength: 1000,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Write a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: saving ? null : post,
                  child: Text(saving ? 'Posting...' : 'Post'),
                ),
              ],
            ),
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: BoardService.instance.watchMessages(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Cannot load messages: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Be the first to post!'),
                  );
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final mine = data['authorUid'] == uid;
                    final created = data['createdAt'];
                    final time = created is Timestamp
                        ? created.toDate().toLocal().toString().substring(0, 16)
                        : 'Pending';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: ListTile(
                        title: Text(data['text']?.toString() ?? ''),
                        subtitle: Text(
                          '${data['authorName'] ?? 'Unknown'} · $time${data['editedAt'] == null ? '' : ' · edited'}',
                        ),
                        trailing: mine
                            ? PopupMenuButton<String>(
                                onSelected: (value) => value == 'edit'
                                    ? edit(
                                        doc.id,
                                        data['text']?.toString() ?? '',
                                      )
                                    : remove(doc.id),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// The dialog owns its controller and releases it when its route is disposed.
// Disposing immediately after showDialog returns is too early: the exit
// animation can still be building the TextField.
class _EditMessageDialog extends StatefulWidget {
  const _EditMessageDialog({required this.initialText});

  final String initialText;

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit message'),
    content: TextField(controller: controller, maxLength: 1000, maxLines: 3),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(controller.text),
        child: const Text('Save'),
      ),
    ],
  );
}
