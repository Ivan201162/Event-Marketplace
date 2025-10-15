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

class Idea {
  final String id;
  final String userId;
  final String type; // 'text', 'photo', 'video', 'reel'
  final String? content;
  final List<String> mediaUrls;
  final String? category;
  final bool isPublic;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Profile? author;

  Idea({
    required this.id,
    required this.userId,
    required this.type,
    this.content,
    this.mediaUrls = const [],
    this.category,
    this.isPublic = true,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.author,
  });

  factory Idea.fromJson(Map<String, dynamic> json) {
    return Idea(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      content: json['content'] as String?,
      mediaUrls: (json['media_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      category: json['category'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      author: json['profiles'] != null ? Profile.fromJson(json['profiles'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'content': content,
      'media_urls': mediaUrls,
      'category': category,
      'is_public': isPublic,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Idea copyWith({
    String? id,
    String? userId,
    String? type,
    String? content,
    List<String>? mediaUrls,
    String? category,
    bool? isPublic,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Profile? author,
  }) {
    return Idea(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      category: category ?? this.category,
      isPublic: isPublic ?? this.isPublic,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
    );
  }
}

class Request {
  final String id;
  final String createdBy;
  final String? assignedTo;
  final String title;
  final String? description;
  final String? category;
  final double? budget;
  final String status; // 'open', 'in_progress', 'completed', 'cancelled'
  final DateTime? deadline;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Profile? creator;
  final Profile? assignee;

  Request({
    required this.id,
    required this.createdBy,
    this.assignedTo,
    required this.title,
    this.description,
    this.category,
    this.budget,
    this.status = 'open',
    this.deadline,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
    this.assignee,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['id'] as String,
      createdBy: json['created_by'] as String,
      assignedTo: json['assigned_to'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      budget: json['budget'] != null ? (json['budget'] as num).toDouble() : null,
      status: json['status'] as String? ?? 'open',
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      creator: json['creator'] != null ? Profile.fromJson(json['creator'] as Map<String, dynamic>) : null,
      assignee: json['assignee'] != null ? Profile.fromJson(json['assignee'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'title': title,
      'description': description,
      'category': category,
      'budget': budget,
      'status': status,
      'deadline': deadline?.toIso8601String(),
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Request copyWith({
    String? id,
    String? createdBy,
    String? assignedTo,
    String? title,
    String? description,
    String? category,
    double? budget,
    String? status,
    DateTime? deadline,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    Profile? creator,
    Profile? assignee,
  }) {
    return Request(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creator: creator ?? this.creator,
      assignee: assignee ?? this.assignee,
    );
  }
}

