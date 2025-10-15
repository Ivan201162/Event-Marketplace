import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Скрипт для добавления тестовых данных в Supabase
/// 
/// Запуск: dart run tool/supabase_test_data_seeder.dart
void main() async {
  print('🌱 Начинаем добавление тестовых данных в Supabase...');
  
  try {
    // Инициализация Supabase
    // ВАЖНО: Замените на ваши реальные данные из Supabase проекта!
    await Supabase.initialize(
      url: 'https://your-project-id.supabase.co', // ЗАМЕНИТЕ НА ВАШ URL
      anonKey: 'your-anon-key-here', // ЗАМЕНИТЕ НА ВАШ КЛЮЧ
    );
    
    final supabase = Supabase.instance.client;
    
    // 1. Создание тестовых профилей
    print('👥 Создаем тестовые профили...');
    await _createTestProfiles(supabase);
    
    // 2. Создание еженедельной статистики
    print('📊 Создаем статистику...');
    await _createWeeklyStats(supabase);
    
    // 3. Создание подписок
    print('🔗 Создаем подписки...');
    await _createFollows(supabase);
    
    // 4. Создание чатов и сообщений
    print('💬 Создаем чаты и сообщения...');
    await _createChatsAndMessages(supabase);
    
    print('✅ Тестовые данные успешно добавлены!');
    
  } catch (e) {
    print('❌ Ошибка при добавлении тестовых данных: $e');
    exit(1);
  }
}

/// Создание тестовых профилей
Future<void> _createTestProfiles(SupabaseClient supabase) async {
  final profiles = [
    {
      'id': 'user1',
      'username': 'alex_photographer',
      'name': 'Александр Фотографов',
      'avatar_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
      'city': 'Москва',
      'bio': 'Профессиональный фотограф с 5-летним опытом. Специализируюсь на свадебной и портретной фотографии.',
      'skills': ['Фотография', 'Свадьбы', 'Портреты', 'Студийная съемка'],
    },
    {
      'id': 'user2',
      'username': 'maria_dj',
      'name': 'Мария DJ',
      'avatar_url': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
      'city': 'Санкт-Петербург',
      'bio': 'DJ и ведущая мероприятий. Создаю незабываемую атмосферу на ваших праздниках.',
      'skills': ['DJ', 'Ведущая', 'Музыка', 'Звук'],
    },
    {
      'id': 'user3',
      'username': 'dmitry_video',
      'name': 'Дмитрий Видеограф',
      'avatar_url': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
      'city': 'Казань',
      'bio': 'Видеограф и монтажер. Снимаю свадьбы, корпоративы и рекламные ролики.',
      'skills': ['Видеосъемка', 'Монтаж', 'Аэросъемка', 'Цветокоррекция'],
    },
    {
      'id': 'user4',
      'username': 'anna_decorator',
      'name': 'Анна Декоратор',
      'avatar_url': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
      'city': 'Екатеринбург',
      'bio': 'Декоратор и флорист. Создаю красивые интерьеры для ваших мероприятий.',
      'skills': ['Декор', 'Флористика', 'Интерьер', 'Стилизация'],
    },
    {
      'id': 'user5',
      'username': 'sergey_animator',
      'name': 'Сергей Аниматор',
      'avatar_url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
      'city': 'Новосибирск',
      'bio': 'Аниматор и ведущий детских праздников. Делаю детство ярче!',
      'skills': ['Анимация', 'Детские праздники', 'Клоунада', 'Игры'],
    },
    {
      'id': 'user6',
      'username': 'elena_catering',
      'name': 'Елена Кейтеринг',
      'avatar_url': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face',
      'city': 'Краснодар',
      'bio': 'Кейтеринг и организация питания. Вкусная еда для ваших гостей.',
      'skills': ['Кейтеринг', 'Кулинария', 'Организация', 'Сервировка'],
    },
  ];
  
  for (final profile in profiles) {
    try {
      await supabase.from('profiles').upsert(profile);
      print('  ✅ Профиль создан: ${profile['name']}');
    } catch (e) {
      print('  ❌ Ошибка создания профиля ${profile['name']}: $e');
    }
  }
}

/// Создание еженедельной статистики
Future<void> _createWeeklyStats(SupabaseClient supabase) async {
  final stats = [
    {'user_id': 'user1', 'score_7d': 150},
    {'user_id': 'user2', 'score_7d': 120},
    {'user_id': 'user3', 'score_7d': 100},
    {'user_id': 'user4', 'score_7d': 90},
    {'user_id': 'user5', 'score_7d': 80},
    {'user_id': 'user6', 'score_7d': 70},
  ];
  
  for (final stat in stats) {
    try {
      await supabase.from('weekly_stats').upsert(stat);
      print('  ✅ Статистика создана для пользователя ${stat['user_id']}');
    } catch (e) {
      print('  ❌ Ошибка создания статистики: $e');
    }
  }
}

/// Создание подписок
Future<void> _createFollows(SupabaseClient supabase) async {
  final follows = [
    {'follower_id': 'user2', 'following_id': 'user1'},
    {'follower_id': 'user3', 'following_id': 'user1'},
    {'follower_id': 'user4', 'following_id': 'user1'},
    {'follower_id': 'user1', 'following_id': 'user2'},
    {'follower_id': 'user3', 'following_id': 'user2'},
    {'follower_id': 'user1', 'following_id': 'user3'},
    {'follower_id': 'user2', 'following_id': 'user3'},
    {'follower_id': 'user5', 'following_id': 'user4'},
    {'follower_id': 'user6', 'following_id': 'user4'},
  ];
  
  for (final follow in follows) {
    try {
      await supabase.from('follows').upsert(follow);
      print('  ✅ Подписка создана: ${follow['follower_id']} → ${follow['following_id']}');
    } catch (e) {
      print('  ❌ Ошибка создания подписки: $e');
    }
  }
}

/// Создание чатов и сообщений
Future<void> _createChatsAndMessages(SupabaseClient supabase) async {
  // Создание чатов
  final chats = [
    {'id': 'chat1'},
    {'id': 'chat2'},
    {'id': 'chat3'},
  ];
  
  for (final chat in chats) {
    try {
      await supabase.from('chats').upsert(chat);
      print('  ✅ Чат создан: ${chat['id']}');
    } catch (e) {
      print('  ❌ Ошибка создания чата: $e');
    }
  }
  
  // Добавление участников чатов
  final participants = [
    {'chat_id': 'chat1', 'user_id': 'user1'},
    {'chat_id': 'chat1', 'user_id': 'user2'},
    {'chat_id': 'chat2', 'user_id': 'user1'},
    {'chat_id': 'chat2', 'user_id': 'user3'},
    {'chat_id': 'chat3', 'user_id': 'user2'},
    {'chat_id': 'chat3', 'user_id': 'user4'},
  ];
  
  for (final participant in participants) {
    try {
      await supabase.from('chat_participants').upsert(participant);
      print('  ✅ Участник добавлен в чат: ${participant['user_id']} → ${participant['chat_id']}');
    } catch (e) {
      print('  ❌ Ошибка добавления участника: $e');
    }
  }
  
  // Добавление сообщений
  final messages = [
    {
      'chat_id': 'chat1',
      'sender_id': 'user1',
      'text': 'Привет! Интересует фотосъемка свадьбы на 15 июня. Можете рассказать о ваших услугах?',
    },
    {
      'chat_id': 'chat1',
      'sender_id': 'user2',
      'text': 'Здравствуйте! Конечно, расскажу подробнее. Сколько гостей планируется?',
    },
    {
      'chat_id': 'chat1',
      'sender_id': 'user1',
      'text': 'Около 50 гостей. Свадьба будет в загородном клубе.',
    },
    {
      'chat_id': 'chat1',
      'sender_id': 'user2',
      'text': 'Отлично! У меня есть опыт съемки в таких локациях. Пришлю портфолио.',
    },
    {
      'chat_id': 'chat2',
      'sender_id': 'user1',
      'text': 'Добрый день! Нужна видеосъемка корпоратива. Какие у вас расценки?',
    },
    {
      'chat_id': 'chat2',
      'sender_id': 'user3',
      'text': 'Привет! Расценки зависят от продолжительности и сложности. Когда планируется мероприятие?',
    },
    {
      'chat_id': 'chat3',
      'sender_id': 'user2',
      'text': 'Привет! Видела ваши работы по декору. Очень красиво! Можете помочь с оформлением детского дня рождения?',
    },
    {
      'chat_id': 'chat3',
      'sender_id': 'user4',
      'text': 'Спасибо! Конечно помогу. Какой возраст именинника и какая тематика?',
    },
  ];
  
  for (final message in messages) {
    try {
      await supabase.from('messages').insert(message);
      print('  ✅ Сообщение добавлено в чат ${message['chat_id']}');
    } catch (e) {
      print('  ❌ Ошибка добавления сообщения: $e');
    }
  }
}
