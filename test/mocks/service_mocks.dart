import 'package:event_marketplace_app/models/post.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/models/story.dart';
import 'package:event_marketplace_app/services/post_service.dart';
import 'package:event_marketplace_app/services/specialist_service.dart';
import 'package:event_marketplace_app/services/story_service.dart';
import 'package:mockito/annotations.dart';

// Генерируем моки
@GenerateMocks([SpecialistService, PostService, StoryService])
void main() {}

// Мок данные для тестов
final mockSpecialist = Specialist(
  id: 'specialist_1',
  userId: 'user_1',
  name: 'Тестовый Специалист',
  category: SpecialistCategory.photographer,
  description: 'Опытный фотограф',
  experienceLevel: ExperienceLevel.intermediate,
  yearsOfExperience: 3,
  price: 5000,
  hourlyRate: 5000,
  rating: 4.8,
  isVerified: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final mockPosts = <Post>[
  Post(
    id: 'post_1',
    specialistId: 'specialist_1',
    text: 'Тестовый пост',
    mediaUrls: ['https://example.com/image1.jpg'],
    likesCount: 10,
    commentsCount: 5,
    createdAt: DateTime.now(),
  ),
];

final mockStories = <Story>[
  Story(
    id: 'story_1',
    specialistId: 'specialist_1',
    title: 'Тестовая история',
    mediaUrl: 'https://example.com/story1.jpg',
    thumbnailUrl: 'https://example.com/story1_thumb.jpg',
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 24)),
    viewsCount: 15,
    metadata: {},
  ),
];
