import { Database } from './database'

export type Profile = Database['public']['Tables']['profiles']['Row']
export type ProfileInsert = Database['public']['Tables']['profiles']['Insert']
export type ProfileUpdate = Database['public']['Tables']['profiles']['Update']

export type Post = Database['public']['Tables']['posts']['Row']
export type PostInsert = Database['public']['Tables']['posts']['Insert']
export type PostUpdate = Database['public']['Tables']['posts']['Update']

export type Follow = Database['public']['Tables']['follows']['Row']
export type FollowInsert = Database['public']['Tables']['follows']['Insert']

export type PostLike = Database['public']['Tables']['post_likes']['Row']
export type PostLikeInsert = Database['public']['Tables']['post_likes']['Insert']

export type PostComment = Database['public']['Tables']['post_comments']['Row']
export type PostCommentInsert = Database['public']['Tables']['post_comments']['Insert']

export type PostType = 'text' | 'photo' | 'video' | 'reel'

export interface PostWithAuthor extends Post {
  author: Profile
  is_liked?: boolean
  is_following?: boolean
}

export interface ProfileWithStats extends Profile {
  followers_count: number
  following_count: number
  posts_count: number
  is_following?: boolean
}

export interface LeaderboardUser {
  id: string
  username: string
  name: string
  avatar_url: string | null
  city: string | null
  likes_count: number
  followers_count: number
  score: number
}

export interface SearchResult {
  id: string
  username: string
  name: string
  avatar_url: string | null
  city: string | null
  bio: string | null
  skills: string[] | null
}
