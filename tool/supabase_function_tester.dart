import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Скрипт для тестирования функций Supabase
/// 
/// Запуск: dart run tool/supabase_function_tester.dart
void main() async {
  print('🧪 Начинаем тестирование функций Supabase...');
  
  try {
    // Инициализация Supabase
    // ВАЖНО: Замените на ваши реальные данные из Supabase проекта!
    await Supabase.initialize(
      url: 'https://your-project-id.supabase.co', // ЗАМЕНИТЕ НА ВАШ URL
      anonKey: 'your-anon-key-here', // ЗАМЕНИТЕ НА ВАШ КЛЮЧ
    );
    
    final supabase = Supabase.instance.client;
    
    // Тест 1: Получение профилей
    print('\n📋 Тест 1: Получение профилей');
    await _testGetProfiles(supabase);
    
    // Тест 2: Получение лидеров недели
    print('\n🏆 Тест 2: Получение лидеров недели');
    await _testGetWeeklyLeaders(supabase);
    
    // Тест 3: Проверка подписок
    print('\n🔗 Тест 3: Проверка подписок');
    await _testFollows(supabase);
    
    // Тест 4: Получение чатов
    print('\n💬 Тест 4: Получение чатов');
    await _testGetChats(supabase);
    
    // Тест 5: Получение сообщений
    print('\n📨 Тест 5: Получение сообщений');
    await _testGetMessages(supabase);
    
    // Тест 6: Поиск пользователей
    print('\n🔍 Тест 6: Поиск пользователей');
    await _testSearchUsers(supabase);
    
    print('\n✅ Все тесты завершены!');
    
  } catch (e) {
    print('❌ Ошибка при тестировании: $e');
    exit(1);
  }
}

/// Тест получения профилей
Future<void> _testGetProfiles(SupabaseClient supabase) async {
  try {
    final profiles = await supabase.from('profiles').select();
    print('  ✅ Получено профилей: ${profiles.length}');
    
    if (profiles.isNotEmpty) {
      final firstProfile = profiles.first;
      print('  📝 Первый профиль: ${firstProfile['name']} (@${firstProfile['username']})');
    }
  } catch (e) {
    print('  ❌ Ошибка получения профилей: $e');
  }
}

/// Тест получения лидеров недели
Future<void> _testGetWeeklyLeaders(SupabaseClient supabase) async {
  try {
    // Тест функции get_weekly_leaders
    final leaders = await supabase.rpc<List<Map<String, dynamic>>>('get_weekly_leaders', params: {
      'city_filter': null,
      'limit_count': 5,
    });
    
    print('  ✅ Получено лидеров: ${leaders.length}');
    
    for (final leader in leaders as List<Map<String, dynamic>>) {
      print('  🏅 ${leader['name']} - ${leader['score_7d']} очков');
    }
  } catch (e) {
    print('  ❌ Ошибка получения лидеров: $e');
  }
}

/// Тест проверки подписок
Future<void> _testFollows(SupabaseClient supabase) async {
  try {
    // Получаем все подписки
    final follows = await supabase.from('follows').select();
    print('  ✅ Всего подписок: ${follows.length}');
    
    // Проверяем подписчиков конкретного пользователя
    final followers = await supabase
        .from('follows')
        .select('profiles!inner(*)')
        .eq('following_id', 'user1');
    
    print('  👥 Подписчиков у user1: ${followers.length}');
    
    // Проверяем подписки конкретного пользователя
    final following = await supabase
        .from('follows')
        .select('profiles!inner(*)')
        .eq('follower_id', 'user1');
    
    print('  ➡️ Подписок у user1: ${following.length}');
  } catch (e) {
    print('  ❌ Ошибка проверки подписок: $e');
  }
}

/// Тест получения чатов
Future<void> _testGetChats(SupabaseClient supabase) async {
  try {
    final chats = await supabase.from('chats').select();
    print('  ✅ Всего чатов: ${chats.length}');
    
    // Получаем участников чатов
    final participants = await supabase.from('chat_participants').select();
    print('  👥 Всего участников чатов: ${participants.length}');
  } catch (e) {
    print('  ❌ Ошибка получения чатов: $e');
  }
}

/// Тест получения сообщений
Future<void> _testGetMessages(SupabaseClient supabase) async {
  try {
    final messages = await supabase
        .from('messages')
        .select('''
          id,
          text,
          created_at,
          sender_id,
          profiles!inner(username, name, avatar_url)
        ''')
        .eq('chat_id', 'chat1')
        .order('created_at', ascending: true);
    
    print('  ✅ Сообщений в chat1: ${messages.length}');
    
    for (final message in messages) {
      final sender = message['profiles'];
      print('  💬 ${sender['name']}: ${message['text']}');
    }
  } catch (e) {
    print('  ❌ Ошибка получения сообщений: $e');
  }
}

/// Тест поиска пользователей
Future<void> _testSearchUsers(SupabaseClient supabase) async {
  try {
    // Поиск по имени
    final searchResults = await supabase
        .from('profiles')
        .select()
        .or('name.ilike.%Александр%,username.ilike.%alex%')
        .limit(5);
    
    print('  ✅ Найдено пользователей по запросу "Александр": ${searchResults.length}');
    
    for (final user in searchResults) {
      print('  🔍 ${user['name']} (@${user['username']})');
    }
  } catch (e) {
    print('  ❌ Ошибка поиска пользователей: $e');
  }
}
