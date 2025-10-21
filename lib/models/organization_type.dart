/// Organization type enum
enum OrganizationType {
  individual, // Физическое лицо
  individualEntrepreneur, // ИП
  selfEmployed, // Самозанятый
  legalEntity, // Юридическое лицо
  professionalIncome, // Профессиональный доход
  simplifiedTax, // УСН
  vat, // НДС
}

/// Organization type extensions
extension OrganizationTypeExtension on OrganizationType {
  /// Get display name for organization type
  String get displayName {
    switch (this) {
      case OrganizationType.individual:
        return 'Физическое лицо';
      case OrganizationType.individualEntrepreneur:
        return 'Индивидуальный предприниматель';
      case OrganizationType.selfEmployed:
        return 'Самозанятый';
      case OrganizationType.legalEntity:
        return 'Юридическое лицо';
      case OrganizationType.professionalIncome:
        return 'Профессиональный доход';
      case OrganizationType.simplifiedTax:
        return 'Упрощенная система налогообложения';
      case OrganizationType.vat:
        return 'НДС';
    }
  }

  /// Get short name for organization type
  String get shortName {
    switch (this) {
      case OrganizationType.individual:
        return 'ФЛ';
      case OrganizationType.individualEntrepreneur:
        return 'ИП';
      case OrganizationType.selfEmployed:
        return 'СЗ';
      case OrganizationType.legalEntity:
        return 'ЮЛ';
      case OrganizationType.professionalIncome:
        return 'ПД';
      case OrganizationType.simplifiedTax:
        return 'УСН';
      case OrganizationType.vat:
        return 'НДС';
    }
  }

  /// Get tax rate for organization type
  double get taxRate {
    switch (this) {
      case OrganizationType.individual:
        return 0.13; // 13% НДФЛ
      case OrganizationType.individualEntrepreneur:
        return 0.06; // 6% УСН
      case OrganizationType.selfEmployed:
        return 0.04; // 4% для самозанятых
      case OrganizationType.legalEntity:
        return 0.20; // 20% налог на прибыль
      case OrganizationType.professionalIncome:
        return 0.13; // 13% НДФЛ
      case OrganizationType.simplifiedTax:
        return 0.06; // 6% УСН
      case OrganizationType.vat:
        return 0.20; // 20% НДС
    }
  }

  /// Check if organization type requires VAT
  bool get requiresVat {
    switch (this) {
      case OrganizationType.legalEntity:
      case OrganizationType.vat:
        return true;
      default:
        return false;
    }
  }

  /// Check if organization type is tax exempt
  bool get isTaxExempt {
    switch (this) {
      case OrganizationType.selfEmployed:
        return true;
      default:
        return false;
    }
  }
}
