import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/enhanced_chat.dart';
import 'package:flutter/foundation.dart';
import '../models/enhanced_message.dart';
import 'package:flutter/foundation.dart';
import '../services/enhanced_chats_service.dart';
import 'package:flutter/foundation.dart';
import '../widgets/message_bubble_widget.dart';
import 'package:flutter/foundation.dart';
import '../widgets/message_input_widget.dart';
import 'package:flutter/foundation.dart';

/// Р Р°СЃС€РёСЂРµРЅРЅС‹Р№ СЌРєСЂР°РЅ С‡Р°С‚Р°
class EnhancedChatScreen extends ConsumerStatefulWidget {
  const EnhancedChatScreen({
    super.key,
    required this.chatId,
  });

  final String chatId;

  @override
  ConsumerState<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends ConsumerState<EnhancedChatScreen> {
  final EnhancedChatsService _chatsService = EnhancedChatsService();
  final ScrollController _scrollController = ScrollController();

  EnhancedChat? _chat;
  List<EnhancedMessage> _messages = [];
  bool _isLoading = true;
  String? _error;
  MessageReply? _replyTo;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadChat();
    _loadMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    try {
      // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РїРѕР»СѓС‡РµРЅРёРµ С‡Р°С‚Р° РїРѕ ID
      // РџРѕРєР° С‡С‚Рѕ СЃРѕР·РґР°С‘Рј Р·Р°РіР»СѓС€РєСѓ
      setState(() {
        _chat = _createMockChat();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РїРѕР»СѓС‡РµРЅРёРµ СЃРѕРѕР±С‰РµРЅРёР№
      // РџРѕРєР° С‡С‚Рѕ СЃРѕР·РґР°С‘Рј Р·Р°РіР»СѓС€РєСѓ
      setState(() {
        _messages = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  EnhancedChat _createMockChat() => EnhancedChat(
        id: widget.chatId,
        type: ChatType.direct,
        members: [
          ChatMember(
            userId: 'user_1',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 1)),
            isOnline: true,
          ),
          ChatMember(
            userId: 'user_2',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 1)),
            lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        name: 'РўРµСЃС‚РѕРІС‹Р№ С‡Р°С‚',
        lastMessage: ChatLastMessage(
          id: '1',
          senderId: 'user_1',
          text: 'РџСЂРёРІРµС‚! РљР°Рє РґРµР»Р°?',
          type: MessageType.text,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('РћС€РёР±РєР°')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('РћС€РёР±РєР°: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _loadChat();
                  _loadMessages();
                },
                child: const Text('РџРѕРІС‚РѕСЂРёС‚СЊ'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Р§Р°С‚ РЅРµ РЅР°Р№РґРµРЅ')),
        body: const Center(child: Text('Р§Р°С‚ РЅРµ РЅР°Р№РґРµРЅ')),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // РЎРїРёСЃРѕРє СЃРѕРѕР±С‰РµРЅРёР№
          Expanded(
            child: _buildMessagesList(),
          ),

          // РРЅРґРёРєР°С‚РѕСЂ РїРµС‡Р°С‚Рё
          if (_isTyping) _buildTypingIndicator(),

          // РџРѕР»Рµ РІРІРѕРґР° СЃРѕРѕР±С‰РµРЅРёР№
          MessageInputWidget(
            onSendMessage: _sendTextMessage,
            onSendMedia: _sendMediaMessage,
            onSendVoice: _sendVoiceMessage,
            onSendDocument: _sendDocumentMessage,
            replyTo: _replyTo,
            onCancelReply: _cancelReply,
            isTyping: _isTyping,
            onTypingChanged: _onTypingChanged,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chat!.name ?? 'Р§Р°С‚',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_chat!.type == ChatType.direct) ...[
                    Text(
                      _getOnlineStatus(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _startVideoCall,
            tooltip: 'Р’РёРґРµРѕР·РІРѕРЅРѕРє',
          ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: _startVoiceCall,
            tooltip: 'Р“РѕР»РѕСЃРѕРІРѕР№ Р·РІРѕРЅРѕРє',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'search',
                child: ListTile(
                  leading: Icon(Icons.search),
                  title: Text('РџРѕРёСЃРє'),
                ),
              ),
              const PopupMenuItem(
                value: 'media',
                child: ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('РњРµРґРёР°С„Р°Р№Р»С‹'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('РќР°СЃС‚СЂРѕР№РєРё'),
                ),
              ),
              const PopupMenuItem(
                value: 'pin',
                child: ListTile(
                  leading: Icon(Icons.push_pin),
                  title: Text('Р—Р°РєСЂРµРїРёС‚СЊ'),
                ),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: ListTile(
                  leading: Icon(Icons.volume_off),
                  title: Text('Р—Р°РіР»СѓС€РёС‚СЊ'),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'РќР°С‡РЅРёС‚Рµ РѕР±С‰РµРЅРёРµ',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'РћС‚РїСЂР°РІСЊС‚Рµ РїРµСЂРІРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isCurrentUser = message.senderId == 'current_user'; // TODO: РџРѕР»СѓС‡РёС‚СЊ РёР· РїСЂРѕРІР°Р№РґРµСЂР°
        final showAvatar =
            index == _messages.length - 1 || _messages[index + 1].senderId != message.senderId;

        return MessageBubbleWidget(
          message: message,
          isCurrentUser: isCurrentUser,
          showAvatar: showAvatar,
          onTap: () => _onMessageTap(message),
          onLongPress: () => _onMessageLongPress(message),
          onReply: () => _replyToMessage(message),
          onForward: () => _forwardMessage(message),
          onEdit: () => _editMessage(message),
          onDelete: () => _deleteMessage(message),
          onReact: (emoji) => _reactToMessage(message, emoji),
        );
      },
    );
  }

  Widget _buildTypingIndicator() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 40), // РћС‚СЃС‚СѓРї РґР»СЏ РІС‹СЂР°РІРЅРёРІР°РЅРёСЏ СЃ СЃРѕРѕР±С‰РµРЅРёСЏРјРё
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'РџРµС‡Р°С‚Р°РµС‚',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  String _getOnlineStatus() {
    final otherMember = _chat!.members.firstWhere(
      (member) => member.userId != 'current_user', // TODO: РџРѕР»СѓС‡РёС‚СЊ РёР· РїСЂРѕРІР°Р№РґРµСЂР°
      orElse: () => _chat!.members.first,
    );

    if (otherMember.isOnline) {
      return 'Р’ СЃРµС‚Рё';
    } else if (otherMember.lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(otherMember.lastSeen!);

      if (difference.inMinutes < 60) {
        return 'Р‘С‹Р»(Р°) РІ СЃРµС‚Рё ${difference.inMinutes} РјРёРЅ РЅР°Р·Р°Рґ';
      } else if (difference.inHours < 24) {
        return 'Р‘С‹Р»(Р°) РІ СЃРµС‚Рё ${difference.inHours} С‡ РЅР°Р·Р°Рґ';
      } else {
        return 'Р‘С‹Р»(Р°) РІ СЃРµС‚Рё ${difference.inDays} РґРЅ РЅР°Р·Р°Рґ';
      }
    } else {
      return 'РќРµ РІ СЃРµС‚Рё';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'search':
        _searchMessages();
        break;
      case 'media':
        _showMediaFiles();
        break;
      case 'settings':
        _showChatSettings();
        break;
      case 'pin':
        _pinChat();
        break;
      case 'mute':
        _muteChat();
        break;
    }
  }

  void _onMessageTap(EnhancedMessage message) {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РѕР±СЂР°Р±РѕС‚РєСѓ РЅР°Р¶Р°С‚РёСЏ РЅР° СЃРѕРѕР±С‰РµРЅРёРµ
  }

  void _onMessageLongPress(EnhancedMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildMessageActionsSheet(message),
    );
  }

  Widget _buildMessageActionsSheet(EnhancedMessage message) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('РћС‚РІРµС‚РёС‚СЊ'),
              onTap: () {
                Navigator.pop(context);
                _replyToMessage(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('РџРµСЂРµСЃР»Р°С‚СЊ'),
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(message);
              },
            ),
            if (message.senderId == 'current_user') ...[
              // TODO: РџРѕР»СѓС‡РёС‚СЊ РёР· РїСЂРѕРІР°Р№РґРµСЂР°
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('РЈРґР°Р»РёС‚СЊ', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('РљРѕРїРёСЂРѕРІР°С‚СЊ'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message);
              },
            ),
          ],
        ),
      );

  void _sendTextMessage(String text) {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РѕС‚РїСЂР°РІРєСѓ С‚РµРєСЃС‚РѕРІРѕРіРѕ СЃРѕРѕР±С‰РµРЅРёСЏ
    debugPrint('РћС‚РїСЂР°РІРєР° С‚РµРєСЃС‚РѕРІРѕРіРѕ СЃРѕРѕР±С‰РµРЅРёСЏ: $text');
  }

  void _sendMediaMessage(
    List<MessageAttachment> attachments, {
    String? caption,
  }) {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РѕС‚РїСЂР°РІРєСѓ РјРµРґРёР° СЃРѕРѕР±С‰РµРЅРёСЏ
    debugPrint('РћС‚РїСЂР°РІРєР° РјРµРґРёР° СЃРѕРѕР±С‰РµРЅРёСЏ: ${attachments.length} С„Р°Р№Р»РѕРІ');
  }

  void _sendVoiceMessage(MessageAttachment voiceAttachment) {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РѕС‚РїСЂР°РІРєСѓ РіРѕР»РѕСЃРѕРІРѕРіРѕ СЃРѕРѕР±С‰РµРЅРёСЏ
    debugPrint('РћС‚РїСЂР°РІРєР° РіРѕР»РѕСЃРѕРІРѕРіРѕ СЃРѕРѕР±С‰РµРЅРёСЏ');
  }

  void _sendDocumentMessage(List<MessageAttachment> documents) {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РѕС‚РїСЂР°РІРєСѓ РґРѕРєСѓРјРµРЅС‚РѕРІ
    debugPrint('РћС‚РїСЂР°РІРєР° РґРѕРєСѓРјРµРЅС‚РѕРІ: ${documents.length} С„Р°Р№Р»РѕРІ');
  }

  void _replyToMessage(EnhancedMessage message) {
    setState(() {
      _replyTo = MessageReply(
        messageId: message.id,
        senderId: message.senderId,
        text: message.text,
        type: message.type,
      );
    });
  }

  void _cancelReply() {
    setState(() {
      _replyTo = null;
    });
  }

  void _forwardMessage(EnhancedMessage message) {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РїРµСЂРµСЃС‹Р»РєСѓ СЃРѕРѕР±С‰РµРЅРёСЏ
    debugPrint('РџРµСЂРµСЃС‹Р»РєР° СЃРѕРѕР±С‰РµРЅРёСЏ: ${message.id}');
  }

  void _editMessage(EnhancedMessage message) {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ СЂРµРґР°РєС‚РёСЂРѕРІР°РЅРёРµ СЃРѕРѕР±С‰РµРЅРёСЏ
    debugPrint('Р РµРґР°РєС‚РёСЂРѕРІР°РЅРёРµ СЃРѕРѕР±С‰РµРЅРёСЏ: ${message.id}');
  }

  void _deleteMessage(EnhancedMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('РЈРґР°Р»РёС‚СЊ СЃРѕРѕР±С‰РµРЅРёРµ'),
        content: const Text('Р’С‹ СѓРІРµСЂРµРЅС‹, С‡С‚Рѕ С…РѕС‚РёС‚Рµ СѓРґР°Р»РёС‚СЊ СЌС‚Рѕ СЃРѕРѕР±С‰РµРЅРёРµ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('РћС‚РјРµРЅР°'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ СѓРґР°Р»РµРЅРёРµ СЃРѕРѕР±С‰РµРЅРёСЏ
            },
            child: const Text('РЈРґР°Р»РёС‚СЊ'),
          ),
        ],
      ),
    );
  }

  void _reactToMessage(EnhancedMessage message, String emoji) {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ СЂРµР°РєС†РёСЋ РЅР° СЃРѕРѕР±С‰РµРЅРёРµ
    debugPrint('Р РµР°РєС†РёСЏ РЅР° СЃРѕРѕР±С‰РµРЅРёРµ: $emoji');
  }

  void _copyMessage(EnhancedMessage message) {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РєРѕРїРёСЂРѕРІР°РЅРёРµ СЃРѕРѕР±С‰РµРЅРёСЏ
    debugPrint('РљРѕРїРёСЂРѕРІР°РЅРёРµ СЃРѕРѕР±С‰РµРЅРёСЏ');
  }

  void _onTypingChanged(bool isTyping) {
    setState(() {
      _isTyping = isTyping;
    });
  }

  void _startVideoCall() {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РІРёРґРµРѕР·РІРѕРЅРѕРє
    debugPrint('РќР°С‡Р°Р»Рѕ РІРёРґРµРѕР·РІРѕРЅРєР°');
  }

  void _startVoiceCall() {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РіРѕР»РѕСЃРѕРІРѕР№ Р·РІРѕРЅРѕРє
    debugPrint('РќР°С‡Р°Р»Рѕ РіРѕР»РѕСЃРѕРІРѕРіРѕ Р·РІРѕРЅРєР°');
  }

  void _searchMessages() {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РїРѕРёСЃРє РїРѕ СЃРѕРѕР±С‰РµРЅРёСЏРј
    debugPrint('РџРѕРёСЃРє РїРѕ СЃРѕРѕР±С‰РµРЅРёСЏРј');
  }

  void _showMediaFiles() {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РїРѕРєР°Р· РјРµРґРёР°С„Р°Р№Р»РѕРІ
    debugPrint('РџРѕРєР°Р· РјРµРґРёР°С„Р°Р№Р»РѕРІ');
  }

  void _showChatSettings() {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РЅР°СЃС‚СЂРѕР№РєРё С‡Р°С‚Р°
    debugPrint('РќР°СЃС‚СЂРѕР№РєРё С‡Р°С‚Р°');
  }

  void _pinChat() {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ Р·Р°РєСЂРµРїР»РµРЅРёРµ С‡Р°С‚Р°
    debugPrint('Р—Р°РєСЂРµРїР»РµРЅРёРµ С‡Р°С‚Р°');
  }

  void _muteChat() {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ Р·Р°РіР»СѓС€РµРЅРёРµ С‡Р°С‚Р°
    debugPrint('Р—Р°РіР»СѓС€РµРЅРёРµ С‡Р°С‚Р°');
  }
}

