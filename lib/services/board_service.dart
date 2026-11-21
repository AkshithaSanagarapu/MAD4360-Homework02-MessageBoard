import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BoardService {
  BoardService._();
  static final instance = BoardService._();
  final _messages = FirebaseFirestore.instance.collection('messages');
  final _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages() =>
      _messages.orderBy('createdAt', descending: true).snapshots();

  String newMessageOperationId() => _messages.doc().id;

  Future<void> createMessage(
    String text,
    String authorName, {
    required String operationId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in first.');
    final content = text.trim();
    if (content.isEmpty || content.length > 1000) {
      throw ArgumentError('Message must be 1–1000 characters.');
    }
    // Stable ID for this submission. A second tap on the same operation
    // cannot create a second document.
    final ref = _messages.doc(operationId);
    await ref.set({
      'text': content,
      'authorUid': user.uid,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
      'editedAt': null,
      'schemaVersion': 2,
    });
  }

  Future<void> editMessage(String id, String text) async {
    final content = text.trim();
    if (content.isEmpty || content.length > 1000) {
      throw ArgumentError('Message must be 1–1000 characters.');
    }
    await _messages.doc(id).update({
      'text': content,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessage(String id) => _messages.doc(id).delete();
}
