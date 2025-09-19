/// Тип идеи для мероприятий
enum IdeaType {
  wedding,
  birthday,
  corporate,
  graduation,
  anniversary,
  holiday,
  conference,
  exhibition,
  concert,
  festival,
  sports,
  charity,
  religious,
  cultural,
  educational,
  entertainment,
  networking,
  teamBuilding,
  productLaunch,
  other,
}

/// Расширение для IdeaType
extension IdeaTypeExtension on IdeaType {
  /// Получить отображаемое имя типа идеи
  String get displayName {
    switch (this) {
      case IdeaType.wedding:
        return 'Свадьба';
      case IdeaType.birthday:
        return 'День рождения';
      case IdeaType.corporate:
        return 'Корпоративное мероприятие';
      case IdeaType.graduation:
        return 'Выпускной';
      case IdeaType.anniversary:
        return 'Юбилей';
      case IdeaType.holiday:
        return 'Праздник';
      case IdeaType.conference:
        return 'Конференция';
      case IdeaType.exhibition:
        return 'Выставка';
      case IdeaType.concert:
        return 'Концерт';
      case IdeaType.festival:
        return 'Фестиваль';
      case IdeaType.sports:
        return 'Спортивное мероприятие';
      case IdeaType.charity:
        return 'Благотворительное мероприятие';
      case IdeaType.religious:
        return 'Религиозное мероприятие';
      case IdeaType.cultural:
        return 'Культурное мероприятие';
      case IdeaType.educational:
        return 'Образовательное мероприятие';
      case IdeaType.entertainment:
        return 'Развлекательное мероприятие';
      case IdeaType.networking:
        return 'Нетворкинг';
      case IdeaType.teamBuilding:
        return 'Тимбилдинг';
      case IdeaType.productLaunch:
        return 'Презентация продукта';
      case IdeaType.other:
        return 'Другое';
    }
  }

  /// Получить описание типа идеи
  String get description {
    switch (this) {
      case IdeaType.wedding:
        return 'Свадебные церемонии и торжества';
      case IdeaType.birthday:
        return 'Дни рождения и юбилеи';
      case IdeaType.corporate:
        return 'Корпоративные мероприятия и встречи';
      case IdeaType.graduation:
        return 'Выпускные вечера и церемонии';
      case IdeaType.anniversary:
        return 'Годовщины и памятные даты';
      case IdeaType.holiday:
        return 'Праздничные мероприятия';
      case IdeaType.conference:
        return 'Конференции и семинары';
      case IdeaType.exhibition:
        return 'Выставки и экспозиции';
      case IdeaType.concert:
        return 'Концерты и музыкальные мероприятия';
      case IdeaType.festival:
        return 'Фестивали и массовые мероприятия';
      case IdeaType.sports:
        return 'Спортивные соревнования и турниры';
      case IdeaType.charity:
        return 'Благотворительные акции и мероприятия';
      case IdeaType.religious:
        return 'Религиозные церемонии и обряды';
      case IdeaType.cultural:
        return 'Культурные мероприятия и фестивали';
      case IdeaType.educational:
        return 'Образовательные семинары и курсы';
      case IdeaType.entertainment:
        return 'Развлекательные мероприятия и шоу';
      case IdeaType.networking:
        return 'Нетворкинг и деловые встречи';
      case IdeaType.teamBuilding:
        return 'Тимбилдинг и корпоративные игры';
      case IdeaType.productLaunch:
        return 'Презентации и запуски продуктов';
      case IdeaType.other:
        return 'Другие типы мероприятий';
    }
  }

  /// Получить иконку для типа идеи
  String get iconName {
    switch (this) {
      case IdeaType.wedding:
        return 'wedding';
      case IdeaType.birthday:
        return 'birthday';
      case IdeaType.corporate:
        return 'corporate';
      case IdeaType.graduation:
        return 'graduation';
      case IdeaType.anniversary:
        return 'anniversary';
      case IdeaType.holiday:
        return 'holiday';
      case IdeaType.conference:
        return 'conference';
      case IdeaType.exhibition:
        return 'exhibition';
      case IdeaType.concert:
        return 'concert';
      case IdeaType.festival:
        return 'festival';
      case IdeaType.sports:
        return 'sports';
      case IdeaType.charity:
        return 'charity';
      case IdeaType.religious:
        return 'religious';
      case IdeaType.cultural:
        return 'cultural';
      case IdeaType.educational:
        return 'educational';
      case IdeaType.entertainment:
        return 'entertainment';
      case IdeaType.networking:
        return 'networking';
      case IdeaType.teamBuilding:
        return 'team_building';
      case IdeaType.productLaunch:
        return 'product_launch';
      case IdeaType.other:
        return 'other';
    }
  }
}
