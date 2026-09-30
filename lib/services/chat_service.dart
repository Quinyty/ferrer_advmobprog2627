import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final currentUid = _firebaseAuth.currentUser?.uid;
    return _firestore.collection('chat_users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUid)
          .map((doc) => {...doc.data(), 'uid': doc.id})
          .toList();
    });
  }

  Future<void> sendMessage(String receiverId, String message) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('Sign in with Firebase to chat.');
    if (receiverId.isEmpty || receiverId == user.uid) {
      throw ArgumentError('Choose another signed-in user to chat with.');
    }

    final timestamp = Timestamp.now();
    final ids = [user.uid, receiverId]..sort();
    final room = _firestore.collection('chat_rooms').doc(ids.join('_'));
    final messageDoc = room.collection('messages').doc();
    final newMessage = MessageModel(
      senderId: user.uid,
      senderEmail: user.email ?? '',
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      status: 'sent',
    );

    final batch = _firestore.batch();
    batch.set(room, {
      'members': ids,
      'lastMessage': message,
      'updatedAt': timestamp,
    }, SetOptions(merge: true));
    batch.set(messageDoc, newMessage.toMap());
    await batch.commit();
  }

  Future<void> markMessagesSeen(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> messages,
  ) async {
    final currentUid = _firebaseAuth.currentUser?.uid;
    if (currentUid == null) return;

    final batch = _firestore.batch();
    var updates = 0;
    for (final message in messages) {
      final data = message.data();
      if (data['receiverId'] == currentUid && data['status'] != 'seen') {
        batch.update(message.reference, {
          'status': 'seen',
          'seenAt': FieldValue.serverTimestamp(),
        });
        updates++;
      }
    }
    if (updates > 0) await batch.commit();
  }

  Future<void> ensureChatRoom(String receiverId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('Sign in with Firebase to chat.');
    if (receiverId.isEmpty || receiverId == user.uid) {
      throw ArgumentError('Choose another signed-in user to chat with.');
    }

    final members = [user.uid, receiverId]..sort();
    await _firestore.collection('chat_rooms').doc(members.join('_')).set({
      'members': members,
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessage(
    String userID,
    String otherUserID,
  ) {
    final ids = [userID, otherUserID]..sort();
    final chatRoomID = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('chat_users')
        .where('emailAddress', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return (q.docs.first.data()['uid'] ?? '').toString();
  }
}
