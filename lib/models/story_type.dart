enum StoryType {
  image,
  video,
  text,
}

enum StoryPrivacy {
  public,
  followers,
  private,
}

class StoryTypeInfo {
  final StoryType type;
  final String displayName;
  final String icon;

  const StoryTypeInfo({
    required this.type,
    required this.displayName,
    required this.icon,
  });

  static const List<StoryTypeInfo> allTypes = [
    StoryTypeInfo(
      type: StoryType.image,
      displayName: 'Фото',
      icon: '📷',
    ),
    StoryTypeInfo(
      type: StoryType.video,
      displayName: 'Видео',
      icon: '🎥',
    ),
    StoryTypeInfo(
      type: StoryType.text,
      displayName: 'Текст',
      icon: '📝',
    ),
  ];

  static StoryTypeInfo getByType(StoryType type) {
    return allTypes.firstWhere((info) => info.type == type);
  }
}
