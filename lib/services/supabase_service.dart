import 'dart:typed_data';

import 'package:event_marketplace_app/models/social_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Получение текущего пользователя
  static User? get currentUser => _client.auth.currentUser;

  // Получение профиля пользователя по ID
  static Future<Profile?> getProfile(String userId) async {
    try {
      final response =
          await _client.from('profiles').select().eq('id', userId).single();

      return Profile.fromJson(response);
    } catch (e) {
      debugPrint('Error getting profile: $e');
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
      debugPrint('Error getting profile by username: $e');
      return null;
    }
  }

  // Получение топ специалистов недели
  static Future<List<WeeklyLeader>> getWeeklyLeaders(
      {String? city, int limit = 10,}) async {
    try {
      final response = await _client.rpc(
        'get_weekly_leaders',
        params: {'city_filter': city, 'limit_count': limit},
      );

      return (response as List)
          .map((json) => WeeklyLeader.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting weekly leaders: $e');
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
      debugPrint('Error checking follow status: $e');
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
      debugPrint('Error following user: $e');
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
      debugPrint('Error unfollowing user: $e');
      return false;
    }
  }

  // Получение количества подписчиков
  static Future<int> getFollowersCount(String userId) async {
    try {
      final response =
          await _client.from('follows').select('id').eq('following_id', userId);

      return response.length;
    } catch (e) {
      debugPrint('Error getting followers count: $e');
      return 0;
    }
  }

  // Получение количества подписок
  static Future<int> getFollowingCount(String userId) async {
    try {
      final response =
          await _client.from('follows').select('id').eq('follower_id', userId);

      return response.length;
    } catch (e) {
      debugPrint('Error getting following count: $e');
      return 0;
    }
  }

  // Получение или создание чата
  static Future<String?> getOrCreateChat(String otherUserId) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return null;

      final response = await _client.rpc(
        'get_or_create_chat',
        params: {'user1_id': currentUserId, 'user2_id': otherUserId},
      );

      return response.toString();
    } catch (e) {
      debugPrint('Error getting or creating chat: $e');
      return null;
    }
  }

  // Получение списка чатов пользователя
  static Future<List<ChatListItem>> getChatsList() async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return [];

      final response = await _client.from('chat_participants').select('''
            chat_id,
            chats!inner(id, created_at, updated_at),
            profiles!inner(id, username, name, avatar_url)
          ''').eq('user_id', currentUserId);

      final chats = <ChatListItem>[];

      for (final item in response) {
        final chatId = item['chat_id'] as String;

        // Получаем второго участника
        final participants = await _client
            .from('chat_participants')
            .select('profiles!inner(id, username, name, avatar_url)')
            .eq('chat_id', chatId)
            .neq('user_id', currentUserId);

        if (participants.isNotEmpty) {
          final otherUser =
              participants.first['profiles'] as Map<String, dynamic>;

          // Получаем последнее сообщение
          final lastMessage = await _client
              .from('messages')
              .select('text, created_at')
              .eq('chat_id', chatId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          chats.add(
            ChatListItem(
              chatId: chatId,
              otherUser: Profile.fromJson(otherUser),
              lastMessage: lastMessage?['text'] as String?,
              lastMessageTime: lastMessage?['created_at'] as String?,
              updatedAt: item['chats']['updated_at'] as String,
            ),
          );
        }
      }

      // Сортируем по времени последнего обновления
      chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return chats;
    } catch (e) {
      debugPrint('Error getting chats list: $e');
      return [];
    }
  }

  // Получение сообщений чата
  static Future<List<Message>> getChatMessages(String chatId) async {
    try {
      final response = await _client.from('messages').select('''
            id,
            text,
            created_at,
            sender_id,
            profiles!inner(username, name, avatar_url)
          ''').eq('chat_id', chatId).order('created_at', ascending: true);

      return (response as List).map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
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
      await _client.from('chats').update(
          {'updated_at': DateTime.now().toIso8601String()},).eq('id', chatId);

      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
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
      debugPrint('Error getting followers: $e');
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
      debugPrint('Error getting following: $e');
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

      return (response as List).map((json) => Profile.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Realtime подписка на новые сообщения
  static RealtimeChannel subscribeToMessages(
    String chatId,
    Function(Map<String, dynamic>) onNewMessage,
  ) {
    final channel = _client.channel('chat_$chatId');

    channel
        .onPostgresChanges(
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
        )
        .subscribe();

    return channel;
  }

  // =============================================
  // ИДЕИ/ПОСТЫ
  // =============================================

  // Получение идей с пагинацией
  static Future<List<Idea>> getIdeas(
      {int limit = 20, int offset = 0, String? category,}) async {
    try {
      final query = _client
          .from('ideas')
          .select('''
            *,
            profiles!inner(id, username, name, avatar_url)
          ''')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // if (category != null) {
      //   query = query.eq('category', category);
      // }

      final response = await query;

      return (response as List).map((json) => Idea.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting ideas: $e');
      return [];
    }
  }

  // Создание идеи
  static Future<Idea?> createIdea({
    required String type,
    String? content,
    List<String> mediaUrls = const [],
    String? category,
  }) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return null;

      final response = await _client.from('ideas').insert({
        'user_id': currentUserId,
        'type': type,
        'content': content,
        'media_urls': mediaUrls,
        'category': category,
        'is_public': true,
      }).select('''
        *,
        profiles!inner(id, username, name, avatar_url)
      ''').single();

      return Idea.fromJson(response);
    } catch (e) {
      debugPrint('Error creating idea: $e');
      return null;
    }
  }

  // Лайк идеи
  static Future<bool> likeIdea(String ideaId) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return false;

      await _client
          .from('idea_likes')
          .insert({'idea_id': ideaId, 'user_id': currentUserId});

      return true;
    } catch (e) {
      debugPrint('Error liking idea: $e');
      return false;
    }
  }

  // Убрать лайк идеи
  static Future<bool> unlikeIdea(String ideaId) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return false;

      await _client
          .from('idea_likes')
          .delete()
          .eq('idea_id', ideaId)
          .eq('user_id', currentUserId);

      return true;
    } catch (e) {
      debugPrint('Error unliking idea: $e');
      return false;
    }
  }

  // Проверка лайка
  static Future<bool> isIdeaLiked(String ideaId) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return false;

      final response = await _client
          .from('idea_likes')
          .select('id')
          .eq('idea_id', ideaId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking idea like: $e');
      return false;
    }
  }

  // =============================================
  // ЗАЯВКИ
  // =============================================

  // Получение заявок пользователя
  static Future<List<Request>> getUserRequests({
    required String userId,
    bool isCreatedBy = true,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final column = isCreatedBy ? 'created_by' : 'assigned_to';

      final response = await _client
          .from('requests')
          .select('''
            *,
            creator:profiles!created_by(id, username, name, avatar_url),
            assignee:profiles!assigned_to(id, username, name, avatar_url)
          ''')
          .eq(column, userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Request.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting user requests: $e');
      return [];
    }
  }

  // Создание заявки
  static Future<Request?> createRequest({
    required String title,
    String? description,
    String? category,
    double? budget,
    DateTime? deadline,
    String? location,
  }) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return null;

      final response = await _client.from('requests').insert({
        'created_by': currentUserId,
        'title': title,
        'description': description,
        'category': category,
        'budget': budget,
        'deadline': deadline?.toIso8601String(),
        'location': location,
        'status': 'open',
      }).select('''
        *,
        creator:profiles!created_by(id, username, name, avatar_url)
      ''').single();

      return Request.fromJson(response);
    } catch (e) {
      debugPrint('Error creating request: $e');
      return null;
    }
  }

  // Обновление статуса заявки
  static Future<bool> updateRequestStatus(
      String requestId, String status,) async {
    try {
      await _client
          .from('requests')
          .update({'status': status}).eq('id', requestId);

      return true;
    } catch (e) {
      debugPrint('Error updating request status: $e');
      return false;
    }
  }

  // Назначение исполнителя
  static Future<bool> assignRequest(String requestId, String assigneeId) async {
    try {
      await _client
          .from('requests')
          .update({'assigned_to': assigneeId, 'status': 'in_progress'}).eq(
              'id', requestId,);

      return true;
    } catch (e) {
      debugPrint('Error assigning request: $e');
      return false;
    }
  }

  // =============================================
  // ПРОФИЛЬ
  // =============================================

  // Обновление профиля
  static Future<bool> updateProfile({
    String? name,
    String? bio,
    String? city,
    List<String>? skills,
    String? avatarUrl,
  }) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return false;

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (bio != null) updateData['bio'] = bio;
      if (city != null) updateData['city'] = city;
      if (skills != null) updateData['skills'] = skills;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      await _client.from('profiles').update(updateData).eq('id', currentUserId);

      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Загрузка аватара
  static Future<String?> uploadAvatar(
      String filePath, List<int> fileBytes,) async {
    try {
      final currentUserId = currentUser?.id;
      if (currentUserId == null) return null;

      final fileName =
          '${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'avatars/$fileName';

      await _client.storage
          .from('avatars')
          .uploadBinary(filePath, Uint8List.fromList(fileBytes));

      final publicUrl = _client.storage.from('avatars').getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }
}
