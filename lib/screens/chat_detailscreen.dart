import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/chat_service.dart';

final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({super.key, required this.tappedUser});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String> _currentUserIdFuture;
  bool _isSending = false;
  bool _markingSeen = false;
  String? _pendingMessage;

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String> _getCurrentUserId() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) throw StateError('There is no signed-in user.');
    final receiverId = (widget.tappedUser['uid'] ?? '').toString();
    await chatService.ensureChatRoom(receiverId);
    return user.uid;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _pendingMessage = text;
    });

    try {
      await chatService.sendMessage(receiverId, text);
      _msgCtrl.clear();
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          8.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _pendingMessage = null;
        });
      }
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return TimeOfDay.fromDateTime(timestamp.toDate()).format(context);
  }

  Widget _messageBubble({
    required Key animationKey,
    required String text,
    required bool isMine,
    required String status,
    required Timestamp? timestamp,
    String senderEmail = '',
  }) {
    final colors = Theme.of(context).colorScheme;
    final bubbleColor = isMine
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final textColor = isMine ? colors.onPrimaryContainer : colors.onSurface;

    return TweenAnimationBuilder<double>(
      key: animationKey,
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(
            (isMine ? 12 : -12) * (1 - progress),
            8 * (1 - progress),
          ),
          child: child,
        ),
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMine && senderEmail.isNotEmpty) ...[
                Text(
                  senderEmail,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
              ],
              Text(text, style: TextStyle(color: textColor, fontSize: 15)),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status == 'sending'
                          ? 'Sending...'
                          : _formatTime(timestamp),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textColor.withValues(alpha: 0.68),
                      ),
                    ),
                    if (isMine && status != 'sending') ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: status == 'seen' ? 'Seen' : 'Sent',
                        child: Icon(
                          status == 'seen' ? Icons.done_all : Icons.done,
                          size: 15,
                          color: status == 'seen'
                              ? colors.primary
                              : textColor.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                    if (status == 'sending') ...[
                      const SizedBox(width: 6),
                      SizedBox.square(
                        dimension: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: textColor.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // LAB6 ENHANCEMENT 3: Animated bubbles with visible send and seen status.
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName =
        (widget.tappedUser['fName'] ?? widget.tappedUser['username'] ?? 'User')
            .toString();

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(tappedUserName, style: const TextStyle(fontSize: 25)),
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages: ${snapshot.error}',
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (!_markingSeen &&
                        docs.any(
                          (doc) =>
                              doc.data()['receiverId'] == currentUserId &&
                              doc.data()['status'] != 'seen',
                        )) {
                      _markingSeen = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        unawaited(
                          chatService
                              .markMessagesSeen(docs)
                              .catchError((Object error) {
                                debugPrint(
                                  'Could not mark messages seen: $error',
                                );
                              })
                              .whenComplete(() {
                                _markingSeen = false;
                              }),
                        );
                      });
                    }

                    if (docs.isEmpty) {
                      if (_pendingMessage == null) {
                        return const Center(child: Text('No messages yet'));
                      }
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount:
                          docs.length + (_pendingMessage == null ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (_pendingMessage != null && index == 0) {
                          return _messageBubble(
                            animationKey: const ValueKey('pending-message'),
                            text: _pendingMessage!,
                            isMine: true,
                            status: 'sending',
                            timestamp: null,
                          );
                        }

                        final docIndex =
                            index - (_pendingMessage == null ? 0 : 1);
                        final doc = docs[docIndex];
                        final data = doc.data();
                        final msgText = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;
                        return _messageBubble(
                          animationKey: ValueKey(doc.id),
                          text: msgText,
                          isMine: isMe,
                          status: (data['status'] ?? 'sent').toString(),
                          timestamp: data['timestamp'] is Timestamp
                              ? data['timestamp'] as Timestamp
                              : null,
                          senderEmail: (data['senderEmail'] ?? '').toString(),
                        );
                      },
                    );
                  },
                ),
              ),

              // Composer
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          focusNode: _msgFocus,
                          enabled: !_isSending,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) =>
                              _send(currentUserId, tappedUserId),
                          decoration: const InputDecoration(
                            hintText: 'Type a message ...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Send message',
                        onPressed: _isSending
                            ? null
                            : () => _send(currentUserId, tappedUserId),
                        icon: _isSending
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
