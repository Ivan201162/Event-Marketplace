-- Полная схема базы данных для Event Marketplace App
-- Включает все необходимые таблицы для многопользовательского тестирования

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- 1. ПРОФИЛИ ПОЛЬЗОВАТЕЛЕЙ
-- =============================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    avatar_url TEXT,
    city TEXT,
    bio TEXT,
    skills TEXT[] DEFAULT '{}',
    links TEXT[] DEFAULT '{}',
    is_public BOOLEAN DEFAULT true,
    can_receive_messages BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 2. ПОДПИСКИ
-- =============================================
CREATE TABLE IF NOT EXISTS follows (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    following_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

-- =============================================
-- 3. ЧАТЫ И СООБЩЕНИЯ
-- =============================================
CREATE TABLE IF NOT EXISTS chats (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_participants (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(chat_id, user_id)
);

CREATE TABLE IF NOT EXISTS messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 4. ПОСТЫ/ИДЕИ/РИЛСЫ
-- =============================================
CREATE TABLE IF NOT EXISTS ideas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    type TEXT CHECK (type IN ('text', 'photo', 'video', 'reel')) NOT NULL,
    content TEXT,
    media_urls TEXT[] DEFAULT '{}',
    category TEXT,
    is_public BOOLEAN DEFAULT true,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS idea_likes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    idea_id UUID REFERENCES ideas(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(idea_id, user_id)
);

CREATE TABLE IF NOT EXISTS idea_comments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    idea_id UUID REFERENCES ideas(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 5. ЗАЯВКИ (REQUESTS)
-- =============================================
CREATE TABLE IF NOT EXISTS requests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    created_by UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    assigned_to UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT,
    budget DECIMAL(10,2),
    status TEXT CHECK (status IN ('open', 'in_progress', 'completed', 'cancelled')) DEFAULT 'open',
    deadline TIMESTAMP WITH TIME ZONE,
    location TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 6. ЕЖЕНЕДЕЛЬНАЯ СТАТИСТИКА
-- =============================================
CREATE TABLE IF NOT EXISTS weekly_stats (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    score_7d INTEGER DEFAULT 0,
    week_start DATE DEFAULT DATE_TRUNC('week', NOW()),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, week_start)
);

-- =============================================
-- ИНДЕКСЫ ДЛЯ ОПТИМИЗАЦИИ
-- =============================================
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_city ON profiles(city);
CREATE INDEX IF NOT EXISTS idx_profiles_is_public ON profiles(is_public);
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_chat_id ON chat_participants(chat_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_user_id ON chat_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ideas_user_id ON ideas(user_id);
CREATE INDEX IF NOT EXISTS idx_ideas_created_at ON ideas(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ideas_category ON ideas(category);
CREATE INDEX IF NOT EXISTS idx_idea_likes_idea_id ON idea_likes(idea_id);
CREATE INDEX IF NOT EXISTS idx_idea_likes_user_id ON idea_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_idea_comments_idea_id ON idea_comments(idea_id);
CREATE INDEX IF NOT EXISTS idx_requests_created_by ON requests(created_by);
CREATE INDEX IF NOT EXISTS idx_requests_assigned_to ON requests(assigned_to);
CREATE INDEX IF NOT EXISTS idx_requests_status ON requests(status);
CREATE INDEX IF NOT EXISTS idx_requests_created_at ON requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_weekly_stats_user_id ON weekly_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_weekly_stats_score ON weekly_stats(score_7d DESC);

-- =============================================
-- ФУНКЦИИ ДЛЯ АВТОМАТИЧЕСКОГО ОБНОВЛЕНИЯ СЧЕТЧИКОВ
-- =============================================
CREATE OR REPLACE FUNCTION update_idea_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE ideas SET likes_count = likes_count + 1 WHERE id = NEW.idea_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE ideas SET likes_count = likes_count - 1 WHERE id = OLD.idea_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_idea_comments_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE ideas SET comments_count = comments_count + 1 WHERE id = NEW.idea_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE ideas SET comments_count = comments_count - 1 WHERE id = OLD.idea_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- ТРИГГЕРЫ
-- =============================================
CREATE TRIGGER trigger_update_idea_likes_count
  AFTER INSERT OR DELETE ON idea_likes
  FOR EACH ROW EXECUTE FUNCTION update_idea_likes_count();

CREATE TRIGGER trigger_update_idea_comments_count
  AFTER INSERT OR DELETE ON idea_comments
  FOR EACH ROW EXECUTE FUNCTION update_idea_comments_count();

CREATE TRIGGER trigger_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_chats_updated_at
  BEFORE UPDATE ON chats
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_ideas_updated_at
  BEFORE UPDATE ON ideas
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_requests_updated_at
  BEFORE UPDATE ON requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE ideas ENABLE ROW LEVEL SECURITY;
ALTER TABLE idea_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE idea_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_stats ENABLE ROW LEVEL SECURITY;

-- =============================================
-- RLS ПОЛИТИКИ
-- =============================================

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
  FOR SELECT USING (is_public = true);

CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Follows policies
CREATE POLICY "Users can view all follows" ON follows
  FOR SELECT USING (true);

CREATE POLICY "Users can create own follows" ON follows
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can delete own follows" ON follows
  FOR DELETE USING (auth.uid() = follower_id);

-- Chats policies
CREATE POLICY "Users can view chats they participate in" ON chats
  FOR SELECT USING (
    id IN (
      SELECT chat_id FROM chat_participants 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create chats" ON chats
  FOR INSERT WITH CHECK (true);

-- Chat participants policies
CREATE POLICY "Users can view chat participants" ON chat_participants
  FOR SELECT USING (
    chat_id IN (
      SELECT chat_id FROM chat_participants 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can join chats" ON chat_participants
  FOR INSERT WITH CHECK (true);

-- Messages policies
CREATE POLICY "Users can view messages in their chats" ON messages
  FOR SELECT USING (
    chat_id IN (
      SELECT chat_id FROM chat_participants 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can send messages to their chats" ON messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND
    chat_id IN (
      SELECT chat_id FROM chat_participants 
      WHERE user_id = auth.uid()
    )
  );

-- Ideas policies
CREATE POLICY "Public ideas are viewable by everyone" ON ideas
  FOR SELECT USING (is_public = true);

CREATE POLICY "Users can view own ideas" ON ideas
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own ideas" ON ideas
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own ideas" ON ideas
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own ideas" ON ideas
  FOR DELETE USING (auth.uid() = user_id);

-- Idea likes policies
CREATE POLICY "Users can view all idea likes" ON idea_likes
  FOR SELECT USING (true);

CREATE POLICY "Users can create own idea likes" ON idea_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own idea likes" ON idea_likes
  FOR DELETE USING (auth.uid() = user_id);

-- Idea comments policies
CREATE POLICY "Users can view all idea comments" ON idea_comments
  FOR SELECT USING (true);

CREATE POLICY "Users can create own idea comments" ON idea_comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own idea comments" ON idea_comments
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own idea comments" ON idea_comments
  FOR DELETE USING (auth.uid() = user_id);

-- Requests policies
CREATE POLICY "Users can view all requests" ON requests
  FOR SELECT USING (true);

CREATE POLICY "Users can create own requests" ON requests
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own requests" ON requests
  FOR UPDATE USING (auth.uid() = created_by OR auth.uid() = assigned_to);

CREATE POLICY "Users can delete own requests" ON requests
  FOR DELETE USING (auth.uid() = created_by);

-- Weekly stats policies
CREATE POLICY "Weekly stats are viewable by everyone" ON weekly_stats
  FOR SELECT USING (true);

-- =============================================
-- ФУНКЦИИ ДЛЯ БИЗНЕС-ЛОГИКИ
-- =============================================

-- Функция для получения топ специалистов недели
CREATE OR REPLACE FUNCTION get_weekly_leaders(city_filter TEXT DEFAULT NULL, limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    name TEXT,
    avatar_url TEXT,
    city TEXT,
    score_7d INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.username,
        p.name,
        p.avatar_url,
        p.city,
        COALESCE(ws.score_7d, 0) as score_7d
    FROM profiles p
    LEFT JOIN weekly_stats ws ON p.id = ws.user_id 
        AND ws.week_start = DATE_TRUNC('week', NOW())
    WHERE (city_filter IS NULL OR p.city = city_filter)
    ORDER BY COALESCE(ws.score_7d, 0) DESC, p.created_at ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Функция для получения или создания чата между двумя пользователями
CREATE OR REPLACE FUNCTION get_or_create_chat(user1_id UUID, user2_id UUID)
RETURNS UUID AS $$
DECLARE
    chat_id UUID;
BEGIN
    -- Ищем существующий чат
    SELECT c.id INTO chat_id
    FROM chats c
    JOIN chat_participants cp1 ON c.id = cp1.chat_id
    JOIN chat_participants cp2 ON c.id = cp2.chat_id
    WHERE cp1.user_id = user1_id AND cp2.user_id = user2_id
    LIMIT 1;
    
    -- Если чат не найден, создаем новый
    IF chat_id IS NULL THEN
        INSERT INTO chats DEFAULT VALUES RETURNING id INTO chat_id;
        
        INSERT INTO chat_participants (chat_id, user_id) VALUES (chat_id, user1_id);
        INSERT INTO chat_participants (chat_id, user_id) VALUES (chat_id, user2_id);
    END IF;
    
    RETURN chat_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- STORAGE BUCKETS
-- =============================================
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('ideas', 'ideas', true) ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Public avatars are viewable by everyone" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload own avatars" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update own avatars" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own avatars" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Public ideas media are viewable by everyone" ON storage.objects
  FOR SELECT USING (bucket_id = 'ideas');

CREATE POLICY "Users can upload own ideas media" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'ideas' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update own ideas media" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'ideas' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own ideas media" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'ideas' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
