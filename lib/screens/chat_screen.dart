import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _searchText = '';

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (auth.loginType != LoginType.firebase || auth.user == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Sign in with Firebase to use chat.'),
        ),
      );
    }

    return Column(
      children: [
        // LAB6 ENHANCEMENT 2: Filter the chat list by name, username, or email.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchChatController,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _searchText = value),
            decoration: InputDecoration(
              hintText: 'Search people',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchChatController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _searchChatController.clear();
                          _searchText = '';
                        });
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        // LAB6 ENHANCEMENT 1: Stream registered users, excluding the current user.
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chatService.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load chat users: ${snapshot.error}'),
                  ),
                );
              }

              final query = _searchText.trim().toLowerCase();
              final users = (snapshot.data ?? []).where((user) {
                return [
                  user['fName'],
                  user['lName'],
                  user['username'],
                  user['emailAddress'],
                ].any(
                  (value) =>
                      value?.toString().toLowerCase().contains(query) ??
                      query.isEmpty,
                );
              }).toList();

              if (users.isEmpty) {
                return Center(
                  child: Text(
                    snapshot.hasData && snapshot.data!.isNotEmpty
                        ? 'No users match your search.'
                        : 'No other Firebase users yet.',
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final firstName = (user['fName'] ?? '').toString();
                  final lastName = (user['lName'] ?? '').toString();
                  final username = (user['username'] ?? '').toString();
                  final title = '$firstName $lastName'.trim().isNotEmpty
                      ? '$firstName $lastName'.trim()
                      : username.isNotEmpty
                      ? username
                      : 'Firebase user';
                  final email = (user['emailAddress'] ?? '').toString();

                  return TweenAnimationBuilder<double>(
                    key: ValueKey(user['uid']),
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(
                      milliseconds: 220 + (index.clamp(0, 8) * 35),
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (context, progress, child) => Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - progress)),
                        child: child,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          title.isEmpty ? '?' : title[0].toUpperCase(),
                        ),
                      ),
                      title: Text(title),
                      subtitle: Text(email.isEmpty ? '@$username' : email),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        PageRouteBuilder<void>(
                          pageBuilder: (_, animation, secondaryAnimation) =>
                              ChatDetailScreen(tappedUser: user),
                          transitionDuration: const Duration(milliseconds: 280),
                          transitionsBuilder:
                              (_, animation, secondaryAnimation, child) {
                                final slide = Tween<Offset>(
                                  begin: const Offset(0.06, 0),
                                  end: Offset.zero,
                                ).chain(CurveTween(curve: Curves.easeOutCubic));
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: animation.drive(slide),
                                    child: child,
                                  ),
                                );
                              },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
