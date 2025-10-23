import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive_utils.dart';
import '../models/user_registration_data.dart';
import '../widgets/responsive_layout.dart';

/// Экран улучшенной регистрации
class EnhancedRegistrationScreen extends ConsumerStatefulWidget {
  const EnhancedRegistrationScreen({super.key});

  @override
  ConsumerState<EnhancedRegistrationScreen> createState() =>
      _EnhancedRegistrationScreenState();
}

class _EnhancedRegistrationScreenState
    extends ConsumerState<EnhancedRegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  // Контроллеры для полей
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _innController = TextEditingController();
  final _ogrnController = TextEditingController();
  final _kppController = TextEditingController();
  final _legalAddressController = TextEditingController();
  final _actualAddressController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _correspondentAccountController = TextEditingController();
  final _bikController = TextEditingController();
  final _bioController = TextEditingController();

  // Состояние формы
  UserType _selectedUserType = UserType.customer;
  DateTime? _selectedBirthDate;
  final bool _agreeToTerms = false;
  final bool _agreeToPrivacy = false;
  final bool _agreeToMarketing = false;
  final List<String> _selectedSpecializations = [];
  final List<DocumentData> _documents = [];

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _innController.dispose();
    _ogrnController.dispose();
    _kppController.dispose();
    _legalAddressController.dispose();
    _actualAddressController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _correspondentAccountController.dispose();
    _bikController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
        largeDesktop: _buildLargeDesktopLayout(context),
      );

  Widget _buildMobileLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Регистрация'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildBasicInfoPage(),
                  _buildUserTypePage(),
                  _buildPersonalInfoPage(),
                  _buildBusinessInfoPage(),
                  _buildSpecialistInfoPage(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      );

  Widget _buildTabletLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Регистрация'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: ResponsiveContainer(
          child: Column(
            children: [
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildBasicInfoPage(),
                    _buildUserTypePage(),
                    _buildPersonalInfoPage(),
                    _buildBusinessInfoPage(),
                    _buildSpecialistInfoPage(),
                  ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      );

  Widget _buildDesktopLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Регистрация'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: ResponsiveContainer(
          child: Row(
            children: [
              // Левая панель с прогрессом
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProgressIndicator(),
                    const SizedBox(height: 20),
                    _buildPageNavigation(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Основной контент
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        children: [
                          _buildBasicInfoPage(),
                          _buildUserTypePage(),
                          _buildPersonalInfoPage(),
                          _buildBusinessInfoPage(),
                          _buildSpecialistInfoPage(),
                        ],
                      ),
                    ),
                    _buildNavigationButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildLargeDesktopLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Регистрация'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: ResponsiveContainer(
          child: Row(
            children: [
              // Левая панель
              SizedBox(
                width: 350,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProgressIndicator(),
                    const SizedBox(height: 20),
                    _buildPageNavigation(),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Основной контент
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        children: [
                          _buildBasicInfoPage(),
                          _buildUserTypePage(),
                          _buildPersonalInfoPage(),
                          _buildBusinessInfoPage(),
                          _buildSpecialistInfoPage(),
                        ],
                      ),
                    ),
                    _buildNavigationButtons(),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Правая панель с подсказками
              SizedBox(
                width: 300,
                child: Column(
                    children: [const SizedBox(height: 20), _buildHelpPanel()]),
              ),
            ],
          ),
        ),
      );

  Widget _buildProgressIndicator() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText('Шаг ${_currentPage + 1} из $_totalPages',
                    isSubtitle: true),
                ResponsiveText(
                  '${((_currentPage + 1) / _totalPages * 100).round()}%',
                  isSubtitle: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              backgroundColor: Colors.grey[300],
              valueColor:
                  AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          ],
        ),
      );

  Widget _buildPageNavigation() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText('Навигация', isTitle: true),
            const SizedBox(height: 16),
            ...List.generate(_totalPages, (index) {
              final pageNames = [
                'Основная информация',
                'Тип пользователя',
                'Личные данные',
                'Бизнес информация',
                'Информация специалиста',
              ];

              return ListTile(
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: index <= _currentPage
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: index <= _currentPage
                          ? Colors.white
                          : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: ResponsiveText(
                  pageNames[index],
                  style: TextStyle(
                    color:
                        index <= _currentPage ? Colors.black : Colors.grey[600],
                    fontWeight: index == _currentPage
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              );
            }),
          ],
        ),
      );

  Widget _buildHelpPanel() {
    final helpTexts = [
      'Введите основную информацию для создания аккаунта',
      'Выберите тип пользователя для настройки профиля',
      'Заполните личные данные для верификации',
      'Укажите бизнес-информацию для ИП/самозанятых',
      'Добавьте специализации и портфолио',
    ];

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveText('Помощь', isTitle: true),
          const SizedBox(height: 16),
          ResponsiveText(helpTexts[_currentPage], isSubtitle: true),
          const SizedBox(height: 16),
          const Icon(Icons.help_outline, size: 48, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText('Основная информация', isTitle: true),
            const SizedBox(height: 24),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                hintText: 'Введите ваш email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Введите корректный email';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Пароль
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Пароль *',
                hintText: 'Введите пароль',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите пароль';
                }
                if (value.length < 8) {
                  return 'Пароль должен содержать минимум 8 символов';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Подтверждение пароля
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Подтвердите пароль *',
                hintText: 'Повторите пароль',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Подтвердите пароль';
                }
                if (value != _passwordController.text) {
                  return 'Пароли не совпадают';
                }
                return null;
              },
            ),
          ],
        ),
      );

  Widget _buildUserTypePage() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText('Тип пользователя', isTitle: true),
            const SizedBox(height: 24),

            // Выбор типа пользователя
            RadioGroup<UserType>(
              value: _selectedUserType,
              onChanged: (value) {
                setState(() {
                  _selectedUserType = value;
                });
              },
              children: UserType.values
                  .map(
                    (type) => Card(
                      child: RadioListTile<UserType>(
                        title: Text(_getUserTypeTitle(type)),
                        subtitle: Text(_getUserTypeDescription(type)),
                        value: type,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );

  Widget _buildPersonalInfoPage() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText('Личные данные', isTitle: true),
            const SizedBox(height: 24),

            // Имя
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Имя *',
                hintText: 'Введите ваше имя',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите имя';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Фамилия
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Фамилия *',
                hintText: 'Введите вашу фамилию',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите фамилию';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Отчество
            TextFormField(
              controller: _middleNameController,
              decoration: const InputDecoration(
                labelText: 'Отчество',
                hintText: 'Введите ваше отчество (необязательно)',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Телефон
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон *',
                hintText: '+7 (999) 123-45-67',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите телефон';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Дата рождения
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.now().subtract(const Duration(days: 365 * 25)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _selectedBirthDate = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата рождения *',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedBirthDate != null
                      ? '${_selectedBirthDate!.day}.${_selectedBirthDate!.month}.${_selectedBirthDate!.year}'
                      : 'Выберите дату рождения',
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildBusinessInfoPage() {
    if (!_isBusinessUser()) {
      return const SizedBox.shrink();
    }

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveText('Бизнес информация', isTitle: true),
          const SizedBox(height: 24),

          // Название бизнеса
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Название бизнеса *',
              hintText: 'Введите название вашего бизнеса',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (_isBusinessUser() && (value == null || value.isEmpty)) {
                return 'Введите название бизнеса';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // ИНН
          TextFormField(
            controller: _innController,
            decoration: const InputDecoration(
              labelText: 'ИНН *',
              hintText: 'Введите ИНН',
              prefixIcon: Icon(Icons.credit_card),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_isBusinessUser() && (value == null || value.isEmpty)) {
                return 'Введите ИНН';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // ОГРН (для ИП и организаций)
          if (_selectedUserType == UserType.individualEntrepreneur ||
              _selectedUserType == UserType.organization)
            TextFormField(
              controller: _ogrnController,
              decoration: const InputDecoration(
                labelText: 'ОГРН',
                hintText: 'Введите ОГРН',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

          if (_selectedUserType == UserType.individualEntrepreneur ||
              _selectedUserType == UserType.organization)
            const SizedBox(height: 16),

          // КПП (только для организаций)
          if (_selectedUserType == UserType.organization)
            TextFormField(
              controller: _kppController,
              decoration: const InputDecoration(
                labelText: 'КПП',
                hintText: 'Введите КПП',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

          if (_selectedUserType == UserType.organization)
            const SizedBox(height: 16),

          // Юридический адрес
          TextFormField(
            controller: _legalAddressController,
            decoration: const InputDecoration(
              labelText: 'Юридический адрес *',
              hintText: 'Введите юридический адрес',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (value) {
              if (_isBusinessUser() && (value == null || value.isEmpty)) {
                return 'Введите юридический адрес';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Фактический адрес
          TextFormField(
            controller: _actualAddressController,
            decoration: const InputDecoration(
              labelText: 'Фактический адрес',
              hintText: 'Введите фактический адрес (если отличается)',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistInfoPage() {
    if (!_isSpecialistUser()) {
      return const SizedBox.shrink();
    }

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveText('Информация специалиста', isTitle: true),
          const SizedBox(height: 24),

          // Био
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'О себе',
              hintText: 'Расскажите о себе и своем опыте',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),

          const SizedBox(height: 16),

          // Специализации
          const ResponsiveText('Специализации *', isSubtitle: true),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getSpecializationOptions().map((specialization) {
              final isSelected =
                  _selectedSpecializations.contains(specialization);
              return FilterChip(
                label: Text(specialization),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSpecializations.add(specialization);
                    } else {
                      _selectedSpecializations.remove(specialization);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_currentPage > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Назад'),
                ),
              ),
            if (_currentPage > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _canProceedToNextPage() ? _nextPage : null,
                child: Text(
                    _currentPage == _totalPages - 1 ? 'Завершить' : 'Далее'),
              ),
            ),
          ],
        ),
      );

  bool _canProceedToNextPage() {
    switch (_currentPage) {
      case 0: // Основная информация
        return _emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty &&
            _passwordController.text == _confirmPasswordController.text;
      case 1: // Тип пользователя
        return true; // Всегда можно выбрать тип
      case 2: // Личные данные
        return _firstNameController.text.isNotEmpty &&
            _lastNameController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty &&
            _selectedBirthDate != null;
      case 3: // Бизнес информация
        if (!_isBusinessUser()) return true;
        return _businessNameController.text.isNotEmpty &&
            _innController.text.isNotEmpty &&
            _legalAddressController.text.isNotEmpty;
      case 4: // Информация специалиста
        if (!_isSpecialistUser()) return true;
        return _selectedSpecializations.isNotEmpty;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeRegistration();
    }
  }

  void _completeRegistration() {
    // TODO(developer): Реализовать завершение регистрации
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Регистрация завершена!')));
  }

  bool _isBusinessUser() =>
      _selectedUserType == UserType.individualEntrepreneur ||
      _selectedUserType == UserType.selfEmployed ||
      _selectedUserType == UserType.organization;

  bool _isSpecialistUser() =>
      _selectedUserType == UserType.specialist ||
      _selectedUserType == UserType.individualEntrepreneur ||
      _selectedUserType == UserType.selfEmployed ||
      _selectedUserType == UserType.organization;

  String _getUserTypeTitle(UserType type) {
    switch (type) {
      case UserType.customer:
        return 'Клиент';
      case UserType.specialist:
        return 'Специалист';
      case UserType.individualEntrepreneur:
        return 'Индивидуальный предприниматель';
      case UserType.selfEmployed:
        return 'Самозанятый';
      case UserType.organization:
        return 'Организация';
    }
  }

  String _getUserTypeDescription(UserType type) {
    switch (type) {
      case UserType.customer:
        return 'Ищу специалистов для мероприятий';
      case UserType.specialist:
        return 'Предоставляю услуги для мероприятий';
      case UserType.individualEntrepreneur:
        return 'ИП, предоставляющий услуги';
      case UserType.selfEmployed:
        return 'Самозанятый специалист';
      case UserType.organization:
        return 'Организация, предоставляющая услуги';
    }
  }

  List<String> _getSpecializationOptions() => [
        'Фотограф',
        'Видеограф',
        'Ведущий',
        'Музыкант',
        'DJ',
        'Декоратор',
        'Кейтеринг',
        'Аниматор',
        'Флорист',
        'Стилист',
        'Визажист',
        'Парикмахер',
        'Танцор',
        'Актер',
        'Другое',
      ];
}
