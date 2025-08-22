import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsWidget extends StatefulWidget { // Klasa wyświetlająca liste komentarzy
  final String reviewId; // ID recenzji, np. brand-model

  const CommentsWidget({super.key, required this.reviewId});

  @override
  State<CommentsWidget> createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  final DatabaseReference commentsRef = FirebaseDatabase.instance.ref().child('comments');
  final TextEditingController _commentController = TextEditingController();

  User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || currentUser == null) return;

    final newCommentRef = commentsRef.child(widget.reviewId).push();
    await newCommentRef.set({
      'userId': currentUser!.uid,
      'userName': currentUser!.displayName ?? currentUser!.email,
      'text': _commentController.text.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _commentController.clear();
  }

  Future<void> _editComment(String commentId, String oldText) async {
    final TextEditingController editController = TextEditingController(text: oldText);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edytuj komentarz"),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Anuluj")),
          ElevatedButton(
            onPressed: () async {
              await commentsRef
                  .child(widget.reviewId)
                  .child(commentId)
                  .update({'text': editController.text});
              Navigator.pop(context);
            },
            child: const Text("Zapisz"),
          )
        ],
      ),
    );
  }

  Future<void> _deleteComment(String commentId) async {
    await commentsRef.child(widget.reviewId).child(commentId).remove();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text("Komentarze", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),

        // Lista komentarzy
        StreamBuilder<DatabaseEvent>(
          stream: commentsRef.child(widget.reviewId).orderByChild('timestamp').onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const Text("Brak komentarzy");
            }

            final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            final comments = data.entries.map((e) {
              final val = Map<String, dynamic>.from(e.value);
              return {
                'id': e.key,
                'userId': val['userId'] ?? '',
                'userName': val['userName'] ?? 'Anonim',
                'text': val['text'] ?? '',
                'timestamp': val['timestamp'] ?? 0,
              };
            }).toList();

            comments.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                final isOwner = currentUser != null && currentUser!.uid == comment['userId'];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(comment['userName']),
                    subtitle: Text(comment['text']),
                    trailing: isOwner
                        ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editComment(comment['id'], comment['text']);
                        } else if (value == 'delete') {
                          _deleteComment(comment['id']);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text("Edytuj")),
                        const PopupMenuItem(value: 'delete', child: Text("Usuń")),
                      ],
                    )
                        : null,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 10),

        // Input dodawana komentarza
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: "Dodaj komentarz...",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: _addComment,
            )
          ],
        )
      ],
    );
  }
}
