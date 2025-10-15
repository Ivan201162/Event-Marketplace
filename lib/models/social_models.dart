class Profile {
  final String id;
  final String username;
  final String name;
  final String? avatarUrl;
  final String? city;
  final String? bio;
  final List<String> skills;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.username,
    required this.name,
    this.avatarUrl,
    this.city,
    this.bio,
    this.skills = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      city: json['city'] as String?,
      bio: json['bio'] as String?,
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'avatar_url': avatarUrl,
      'city': city,
      'bio': bio,
      'skills': skills,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? username,
    String? name,
    String? avatarUrl,
    String? city,
    String? bio,
    List<String>? skills,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class WeeklyLeader {
  final String userId;
  final String username;
  final String name;
  final String? avatarUrl;
  final String? city;
  final int score7d;

  WeeklyLeader({
    required this.userId,
    required this.username,
    required this.name,
    this.avatarUrl,
    this.city,
    required this.score7d,
  });

  factory WeeklyLeader.fromJson(Map<String, dynamic> json) {
    return WeeklyLeader(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      city: json['city'] as String?,
      score7d: json['score_7d'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'name': name,
      'avatar_url': avatarUrl,
      'city': city,
      'score_7d': score7d,
    };
  }
}

class ChatListItem {
  final String chatId;
  final Profile otherUser;
  final String? lastMessage;
  final String? lastMessageTime;
  final String updatedAt;

  ChatListItem({
    required this.chatId,
    required this.otherUser,
    this.lastMessage,
    this.lastMessageTime,
    required this.updatedAt,
  });

  factory ChatListItem.fromJson(Map<String, dynamic> json) {
    return ChatListItem(
      chatId: json['chat_id'] as String,
      otherUser: Profile.fromJson(json['other_user'] as Map<String, dynamic>),
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] as String?,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'other_user': otherUser.toJson(),
      'last_message': lastMessage,
      'last_message_time': lastMessageTime,
      'updated_at': updatedAt,
    };
  }
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final String? senderUsername;
  final String? senderName;
  final String? senderAvatarUrl;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.senderUsername,
    this.senderName,
    this.senderAvatarUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderUsername: json['profiles']?['username'] as String?,
      senderName: json['profiles']?['name'] as String?,
      senderAvatarUrl: json['profiles']?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'profiles': {
        'username': senderUsername,
        'name': senderName,
        'avatar_url': senderAvatarUrl,
      },
    };
  }

  bool get isFromCurrentUser {
    // Это будет установлено в UI на основе текущего пользователя
    return false;
  }
}

class FollowStats {
  final int followersCount;
  final int followingCount;
  final bool isFollowing;

  FollowStats({
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
  });

  factory FollowStats.fromJson(Map<String, dynamic> json) {
    return FollowStats(
      followersCount: json['followers_count'] as int,
      followingCount: json['following_count'] as int,
      isFollowing: json['is_following'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followers_count': followersCount,
      'following_count': followingCount,
      'is_following': isFollowing,
    };
  }
}

