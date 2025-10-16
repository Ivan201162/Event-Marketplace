-- Схема базы данных для социального функционала Event Marketplace

-- 1. Таблица профилей пользователей
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    city VARCHAR(100),
    bio TEXT,
    skills TEXT[], -- массив навыков
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Таблица еженедельной статистики
CREATE TABLE IF NOT EXISTS weekly_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    score_7d INTEGER DEFAULT 0,
    week_start DATE DEFAULT DATE_TRUNC('week', NOW()),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, week_start)
);

-- 3. Таблица подписок
CREATE TABLE IF NOT EXISTS follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    following_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

-- 4. Таблица чатов
CREATE TABLE IF NOT EXISTS chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Таблица участников чатов
CREATE TABLE IF NOT EXISTS chat_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(chat_id, user_id)
);

-- 6. Таблица сообщений
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для оптимизации запросов
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_city ON profiles(city);
CREATE INDEX IF NOT EXISTS idx_weekly_stats_user_id ON weekly_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_weekly_stats_score ON weekly_stats(score_7d DESC);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_chat_id ON chat_participants(chat_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_user_id ON chat_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- RLS (Row Level Security) политики
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Политики для profiles
CREATE POLICY "Profiles are viewable by everyone" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Политики для weekly_stats
CREATE POLICY "Weekly stats are viewable by everyone" ON weekly_stats
    FOR SELECT USING (true);

-- Политики для follows
CREATE POLICY "Follows are viewable by everyone" ON follows
    FOR SELECT USING (true);

CREATE POLICY "Users can manage own follows" ON follows
    FOR ALL USING (auth.uid() = follower_id);

-- Политики для chats
CREATE POLICY "Users can view chats they participate in" ON chats
    FOR SELECT USING (
        id IN (
            SELECT chat_id FROM chat_participants 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create chats" ON chats
    FOR INSERT WITH CHECK (true);

-- Политики для chat_participants
CREATE POLICY "Users can view chat participants" ON chat_participants
    FOR SELECT USING (
        chat_id IN (
            SELECT chat_id FROM chat_participants 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can join chats" ON chat_participants
    FOR INSERT WITH CHECK (true);

-- Политики для messages
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

-- Функции для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chats_updated_at BEFORE UPDATE ON chats
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Функция для получения топ специалистов недели
CREATE OR REPLACE FUNCTION get_weekly_leaders(city_filter TEXT DEFAULT NULL, limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    user_id UUID,
    username VARCHAR(50),
    name VARCHAR(100),
    avatar_url TEXT,
    city VARCHAR(100),
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


