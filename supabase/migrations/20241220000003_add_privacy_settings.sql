-- Add privacy_settings column to profiles table
ALTER TABLE profiles 
ADD COLUMN privacy_settings JSONB DEFAULT '{
  "profileVisibility": "public",
  "allowMessages": true,
  "showEmail": false,
  "showPhone": false,
  "notifications": {
    "newFollowers": true,
    "newMessages": true,
    "newLikes": true,
    "newComments": true
  }
}'::jsonb;

-- Add index for privacy settings queries
CREATE INDEX idx_profiles_privacy_settings ON profiles USING GIN (privacy_settings);
