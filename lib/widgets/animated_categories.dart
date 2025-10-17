import 'package:flutter/material.dart';

/// Анимированные категории специалистов
class AnimatedCategories extends StatefulWidget {
  const AnimatedCategories({
    super.key,
    required this.onCategorySelected,
  });

  final ValueChanged<String> onCategorySelected;

  @override
  State<AnimatedCategories> createState() => _AnimatedCategoriesState();
}

class _AnimatedCategoriesState extends State<AnimatedCategories> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;

  String _selectedCategory = 'Все';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Все', 'icon': '🎯', 'color': Colors.blue},
    {'name': 'Свадьбы', 'icon': '💒', 'color': Colors.pink},
    {'name': 'Корпоративы', 'icon': '🏢', 'color': Colors.blue},
    {'name': 'Дни рождения', 'icon': '🎂', 'color': Colors.orange},
    {'name': 'Детские праздники', 'icon': '🎈', 'color': Colors.purple},
    {'name': 'Выпускные', 'icon': '🎓', 'color': Colors.green},
    {'name': 'Фотографы', 'icon': '📸', 'color': Colors.indigo},
    {'name': 'Видеографы', 'icon': '🎬', 'color': Colors.red},
    {'name': 'DJ', 'icon': '🎵', 'color': Colors.purple},
    {'name': 'Ведущие', 'icon': '🎤', 'color': Colors.teal},
    {'name': 'Декораторы', 'icon': '🎨', 'color': Colors.amber},
    {'name': 'Аниматоры', 'icon': '🎭', 'color': Colors.cyan},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Создаем анимации для каждого элемента
    _itemControllers = List.generate(
      _categories.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      ),
    );

    _itemAnimations = _itemControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();

    // Запускаем анимации с задержкой
    _animationController.forward();
    _startItemAnimations();
  }

  void _startItemAnimations() {
    for (int i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _itemControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Категории',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _itemAnimations[index],
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _itemAnimations[index].value,
                      child: _buildCategoryItem(index),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(int index) {
    final category = _categories[index];
    final isSelected = category['name'] == _selectedCategory;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category['name'] as String;
        });
        widget.onCategorySelected(category['name'] as String);
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (category['color'] as Color).withOpacity(0.2)
              : (category['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (category['color'] as Color).withOpacity(
              isSelected ? 0.5 : 0.3,
            ),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (category['color'] as Color).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                category['icon'] as String,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category['name'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? (category['color'] as Color) : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
