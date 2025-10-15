import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social_models.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Получение текущего пользователя
  static User? get currentUser => _client.auth.currentUser;

  // Получение профиля пользователя по ID
  static Future<Profile?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return Profile.fromJson(response);
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  // Получение профиля пользователя по username
  static Future<Profile?> getProfileByUsername(String username) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('username', username)
          .single();
      
      return Profile.fromJson(response);
    } catch (e) {
      print('Error getting profile by username: $e');
      return null;
    }
  }

  // Получение топ специалистов недели
  static Future<List<WeeklyLeader>> getWeeklyLeaders({
    String? city,
    int limit = 10,
  }) async {
    try {
      final response = await _client
          .rpc('get_weekly_leaders', params: {
            'city_filter': city,
            'limit_count': limit,
          });
      
      return (response as List)
          .map((json) => WeeklyLeader.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting weekly leaders: $e');
      return [];
    }
  }

  // Проверка подписки
  static Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final response = await _client
          .from('follows')
          .select('id')
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // Подписка на пользователя
  static Future<bool> followUser(String followingId) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return false;

      await _client.from('follows').insert({
        'follower_id': currentUserId,
        'following_id': followingId,
      });
      
      return true;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  // Отписка от пользователя
  static Future<bool> unfollowUser(String followingId) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return false;

      await _client
          .from('follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', followingId);
      
      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  // Получение количества подписчиков
  static Future<int> getFollowersCount(String userId) async {
    try {
      final response = await _client
          .from('follows')
          .select('id')
          .eq('following_id', userId);
      
      return response.length;
    } catch (e) {
      print('Error getting followers count: $e');
      return 0;
    }
  }

  // Получение количества подписок
  static Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _client
          .from('follows')
          .select('id')
          .eq('follower_id', userId);
      
      return response.length;
    } catch (e) {
      print('Error getting following count: $e');
      return 0;
    }
  }

  // Получение или создание чата
  static Future<String?> getOrCreateChat(String otherUserId) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return null;

      final response = await _client
          .rpc('get_or_create_chat', params: {
            'user1_id': currentUserId,
            'user2_id': otherUserId,
          });
      
      return response.toString();
    } catch (e) {
      print('Error getting or creating chat: $e');
      return null;
    }
  }

  // Получение списка чатов пользователя
  static Future<List<ChatListItem>> getChatsList() async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return [];

      final response = await _client
          .from('chat_participants')
          .select('''
            chat_id,
            chats!inner(id, created_at, updated_at),
            profiles!inner(id, username, name, avatar_url)
          ''')
          .eq('user_id', currentUserId);

      final List<ChatListItem> chats = [];
      
      for (final item in response) {
        final chatId = item['chat_id'] as String;
        
        // Получаем второго участника
        final participants = await _client
            .from('chat_participants')
            .select('profiles!inner(id, username, name, avatar_url)')
            .eq('chat_id', chatId)
            .neq('user_id', currentUserId);
        
        if (participants.isNotEmpty) {
          final otherUser = participants.first['profiles'] as Map<String, dynamic>;
          
          // Получаем последнее сообщение
          final lastMessage = await _client
              .from('messages')
              .select('text, created_at')
              .eq('chat_id', chatId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          
          chats.add(ChatListItem(
            chatId: chatId,
            otherUser: Profile.fromJson(otherUser),
            lastMessage: lastMessage?['text'] as String?,
            lastMessageTime: lastMessage?['created_at'] as String?,
            updatedAt: item['chats']['updated_at'] as String,
          ));
        }
      }
      
      // Сортируем по времени последнего обновления
      chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return chats;
    } catch (e) {
      print('Error getting chats list: $e');
      return [];
    }
  }

  // Получение сообщений чата
  static Future<List<Message>> getChatMessages(String chatId) async {
    try {
      final response = await _client
          .from('messages')
          .select('''
            id,
            text,
            created_at,
            sender_id,
            profiles!inner(username, name, avatar_url)
          ''')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);
      
      return (response as List)
          .map((json) => Message.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting chat messages: $e');
      return [];
    }
  }

  // Отправка сообщения
  static Future<bool> sendMessage(String chatId, String text) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return false;

      await _client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': currentUserId,
        'text': text,
      });
      
      // Обновляем время последнего обновления чата
      await _client
          .from('chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);
      
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Получение подписчиков
  static Future<List<Profile>> getFollowers(String userId) async {
    try {
      final response = await _client
          .from('follows')
          .select('profiles!inner(*)')
          .eq('following_id', userId);
      
      return (response as List)
          .map((json) => Profile.fromJson(json['profiles']))
          .toList();
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  // Получение подписок
  static Future<List<Profile>> getFollowing(String userId) async {
    try {
      final response = await _client
          .from('follows')
          .select('profiles!inner(*)')
          .eq('follower_id', userId);
      
      return (response as List)
          .map((json) => Profile.fromJson(json['profiles']))
          .toList();
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }

  // Поиск пользователей
  static Future<List<Profile>> searchUsers(String query) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .or('name.ilike.%$query%,username.ilike.%$query%,skills.cs.{${query.toLowerCase()}}')
          .limit(20);
      
      return (response as List)
          .map((json) => Profile.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Realtime подписка на новые сообщения
  static RealtimeChannel subscribeToMessages(
    String chatId,
    Function(Map<String, dynamic>) onNewMessage,
  ) {
    final channel = _client.channel('chat_$chatId');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_id',
        value: chatId,
      ),
      callback: (payload) {
        onNewMessage(payload.newRecord);
      },
    ).subscribe();
    
    return channel;
  }
}
