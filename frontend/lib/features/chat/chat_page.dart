import 'package:flutter/material.dart';
import '../../core/utils/responsive_helper.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  final List<ChatConversation> conversations = [
    ChatConversation(
      id: '1',
      name: 'Sarah - Personal Trainer',
      lastMessage: 'Great progress on your squats! 💪',
      avatar: '👩‍🏫',
      unread: 2,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isOnline: true,
    ),
    ChatConversation(
      id: '2',
      name: 'Gym Buddies Group',
      lastMessage: 'Anyone up for a morning workout? 🏋️',
      avatar: '👥',
      unread: 0,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isGroup: true,
    ),
    ChatConversation(
      id: '3',
      name: 'Mike - Accountability Partner',
      lastMessage: 'You: Thanks! See you tomorrow 👋',
      avatar: '👨‍💼',
      unread: 0,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  final List<ChatMessage> currentMessages = [
    ChatMessage(
      id: '1',
      sender: 'Sarah',
      avatar: '👩‍🏫',
      message: 'Hey! How was your workout today?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      isMe: false,
    ),
    ChatMessage(
      id: '2',
      sender: 'You',
      avatar: '👤',
      message: 'It was great! Managed to do 15 more reps than last time',
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      isMe: true,
    ),
    ChatMessage(
      id: '3',
      sender: 'Sarah',
      avatar: '👩‍🏫',
      message: 'Great progress on your squats! 💪',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isMe: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);

    return Row(
      children: [
        // Conversations List
        SizedBox(
          width: isMobile ? double.infinity : 320,
          child: Column(
            children: [
              Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Messages',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) =>
                      _ConversationTile(conv: conversations[index]),
                ),
              ),
            ],
          ),
        ),
        // Chat Detail
        if (!isMobile)
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: currentMessages
                        .map((msg) => _ChatBubble(message: msg))
                        .toList(),
                  ),
                ),
                _ChatInputBar(controller: _messageController),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conv;

  const _ConversationTile({required this.conv});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          Text(conv.avatar, style: const TextStyle(fontSize: 40)),
          if (conv.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(conv.name),
      subtitle: Text(
        conv.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(conv.timestamp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (conv.unread > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${conv.unread}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Opening ${conv.name}')));
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            Text(message.avatar, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: message.isMe
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.message,
              style: TextStyle(
                color: message.isMe
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            Text(message.avatar, style: const TextStyle(fontSize: 20)),
          ],
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;

  const _ChatInputBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

class ChatConversation {
  final String id;
  final String name;
  final String lastMessage;
  final String avatar;
  final int unread;
  final DateTime timestamp;
  final bool isOnline;
  final bool isGroup;

  ChatConversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.avatar,
    required this.unread,
    required this.timestamp,
    this.isOnline = false,
    this.isGroup = false,
  });
}

class ChatMessage {
  final String id;
  final String sender;
  final String avatar;
  final String message;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.avatar,
    required this.message,
    required this.timestamp,
    required this.isMe,
  });
}
