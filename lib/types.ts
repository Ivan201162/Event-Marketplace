export interface Profile {
  id: string
  username: string
  name: string
  avatar_url?: string
  city?: string
  bio?: string
  skills: string[]
  links: string[]
  is_public: boolean
  created_at: string
  updated_at: string
}

export interface Post {
  id: string
  user_id: string
  type: 'text' | 'photo' | 'video' | 'reel'
  content?: string
  media_urls: string[]
  likes_count: number
  comments_count: number
  created_at: string
  updated_at: string
  profile?: Profile
}

export interface Comment {
  id: string
  post_id: string
  user_id: string
  content: string
  created_at: string
  profile?: Profile
}

export interface Follow {
  id: string
  follower_id: string
  following_id: string
  created_at: string
}

export interface PostLike {
  id: string
  post_id: string
  user_id: string
  created_at: string
}

export interface WeeklyStats {
  user_id: string
  username: string
  name: string
  avatar_url?: string
  score_7d: number
  posts_count: number
  likes_received: number
}

export interface SearchResult {
  id: string
  username: string
  name: string
  avatar_url?: string
  city?: string
  skills: string[]
  bio?: string
}
