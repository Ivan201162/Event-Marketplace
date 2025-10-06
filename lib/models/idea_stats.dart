/// Статистика идеи
class IdeaStats {
  const IdeaStats({
    required this.ideaId,
    required this.likesCount,
    required this.commentsCount,
    required this.savesCount,
    required this.viewsCount,
  });

  /// Создать из Map
  factory IdeaStats.fromMap(Map<String, dynamic> map) => IdeaStats(
        ideaId: map['ideaId'] as String? ?? '',
        likesCount: map['likesCount'] as int? ?? 0,
        commentsCount: map['commentsCount'] as int? ?? 0,
        savesCount: map['savesCount'] as int? ?? 0,
        viewsCount: map['viewsCount'] as int? ?? 0,
      );
  final String ideaId;
  final int likesCount;
  final int commentsCount;
  final int savesCount;
  final int viewsCount;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'ideaId': ideaId,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'savesCount': savesCount,
        'viewsCount': viewsCount,
      };

  /// Создать копию с изменениями
  IdeaStats copyWith({
    String? ideaId,
    int? likesCount,
    int? commentsCount,
    int? savesCount,
    int? viewsCount,
  }) =>
      IdeaStats(
        ideaId: ideaId ?? this.ideaId,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        savesCount: savesCount ?? this.savesCount,
        viewsCount: viewsCount ?? this.viewsCount,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IdeaStats &&
        other.ideaId == ideaId &&
        other.likesCount == likesCount &&
        other.commentsCount == commentsCount &&
        other.savesCount == savesCount &&
        other.viewsCount == viewsCount;
  }

  @override
  int get hashCode =>
      ideaId.hashCode ^
      likesCount.hashCode ^
      commentsCount.hashCode ^
      savesCount.hashCode ^
      viewsCount.hashCode;

  @override
  String toString() =>
      'IdeaStats(ideaId: $ideaId, likesCount: $likesCount, commentsCount: $commentsCount, savesCount: $savesCount, viewsCount: $viewsCount)';
}
