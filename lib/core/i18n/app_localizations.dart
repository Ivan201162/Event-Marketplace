import 'package:flutter/material.dart';

/// Локализация приложения
class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('ru', ''),
    Locale('kk', ''), // Казахский
  ];

  // Общие строки
  String get appTitle =>
      _localizedValues[locale.languageCode]?['appTitle'] ?? 'Event Marketplace';
  String get loading =>
      _localizedValues[locale.languageCode]?['loading'] ?? 'Loading...';
  String get error =>
      _localizedValues[locale.languageCode]?['error'] ?? 'Error';
  String get success =>
      _localizedValues[locale.languageCode]?['success'] ?? 'Success';
  String get cancel =>
      _localizedValues[locale.languageCode]?['cancel'] ?? 'Cancel';
  String get confirm =>
      _localizedValues[locale.languageCode]?['confirm'] ?? 'Confirm';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Save';
  String get delete =>
      _localizedValues[locale.languageCode]?['delete'] ?? 'Delete';
  String get edit => _localizedValues[locale.languageCode]?['edit'] ?? 'Edit';
  String get add => _localizedValues[locale.languageCode]?['add'] ?? 'Add';
  String get search =>
      _localizedValues[locale.languageCode]?['search'] ?? 'Search';
  String get filter =>
      _localizedValues[locale.languageCode]?['filter'] ?? 'Filter';
  String get sort => _localizedValues[locale.languageCode]?['sort'] ?? 'Sort';
  String get refresh =>
      _localizedValues[locale.languageCode]?['refresh'] ?? 'Refresh';
  String get retry =>
      _localizedValues[locale.languageCode]?['retry'] ?? 'Retry';
  String get back => _localizedValues[locale.languageCode]?['back'] ?? 'Back';
  String get next => _localizedValues[locale.languageCode]?['next'] ?? 'Next';
  String get previous =>
      _localizedValues[locale.languageCode]?['previous'] ?? 'Previous';
  String get done => _localizedValues[locale.languageCode]?['done'] ?? 'Done';
  String get close =>
      _localizedValues[locale.languageCode]?['close'] ?? 'Close';
  String get open => _localizedValues[locale.languageCode]?['open'] ?? 'Open';
  String get view => _localizedValues[locale.languageCode]?['view'] ?? 'View';
  String get hide => _localizedValues[locale.languageCode]?['hide'] ?? 'Hide';
  String get show => _localizedValues[locale.languageCode]?['show'] ?? 'Show';
  String get select =>
      _localizedValues[locale.languageCode]?['select'] ?? 'Select';
  String get deselect =>
      _localizedValues[locale.languageCode]?['deselect'] ?? 'Deselect';
  String get all => _localizedValues[locale.languageCode]?['all'] ?? 'All';
  String get none => _localizedValues[locale.languageCode]?['none'] ?? 'None';
  String get yes => _localizedValues[locale.languageCode]?['yes'] ?? 'Yes';
  String get no => _localizedValues[locale.languageCode]?['no'] ?? 'No';
  String get ok => _localizedValues[locale.languageCode]?['ok'] ?? 'OK';

  // Навигация
  String get home => _localizedValues[locale.languageCode]?['home'] ?? 'Home';
  String get profile =>
      _localizedValues[locale.languageCode]?['profile'] ?? 'Profile';
  String get settings =>
      _localizedValues[locale.languageCode]?['settings'] ?? 'Settings';
  String get notifications =>
      _localizedValues[locale.languageCode]?['notifications'] ??
      'Notifications';
  String get messages =>
      _localizedValues[locale.languageCode]?['messages'] ?? 'Messages';
  String get favorites =>
      _localizedValues[locale.languageCode]?['favorites'] ?? 'Favorites';
  String get history =>
      _localizedValues[locale.languageCode]?['history'] ?? 'History';
  String get help => _localizedValues[locale.languageCode]?['help'] ?? 'Help';
  String get about =>
      _localizedValues[locale.languageCode]?['about'] ?? 'About';
  String get contact =>
      _localizedValues[locale.languageCode]?['contact'] ?? 'Contact';
  String get support =>
      _localizedValues[locale.languageCode]?['support'] ?? 'Support';
  String get feedback =>
      _localizedValues[locale.languageCode]?['feedback'] ?? 'Feedback';
  String get report =>
      _localizedValues[locale.languageCode]?['report'] ?? 'Report';
  String get share =>
      _localizedValues[locale.languageCode]?['share'] ?? 'Share';
  String get rate => _localizedValues[locale.languageCode]?['rate'] ?? 'Rate';
  String get review =>
      _localizedValues[locale.languageCode]?['review'] ?? 'Review';

  // Аутентификация
  String get login =>
      _localizedValues[locale.languageCode]?['login'] ?? 'Login';
  String get logout =>
      _localizedValues[locale.languageCode]?['logout'] ?? 'Logout';
  String get register =>
      _localizedValues[locale.languageCode]?['register'] ?? 'Register';
  String get signIn =>
      _localizedValues[locale.languageCode]?['signIn'] ?? 'Sign In';
  String get signUp =>
      _localizedValues[locale.languageCode]?['signUp'] ?? 'Sign Up';
  String get signOut =>
      _localizedValues[locale.languageCode]?['signOut'] ?? 'Sign Out';
  String get email =>
      _localizedValues[locale.languageCode]?['email'] ?? 'Email';
  String get password =>
      _localizedValues[locale.languageCode]?['password'] ?? 'Password';
  String get confirmPassword =>
      _localizedValues[locale.languageCode]?['confirmPassword'] ??
      'Confirm Password';
  String get forgotPassword =>
      _localizedValues[locale.languageCode]?['forgotPassword'] ??
      'Forgot Password?';
  String get resetPassword =>
      _localizedValues[locale.languageCode]?['resetPassword'] ??
      'Reset Password';
  String get changePassword =>
      _localizedValues[locale.languageCode]?['changePassword'] ??
      'Change Password';
  String get phoneNumber =>
      _localizedValues[locale.languageCode]?['phoneNumber'] ?? 'Phone Number';
  String get fullName =>
      _localizedValues[locale.languageCode]?['fullName'] ?? 'Full Name';
  String get firstName =>
      _localizedValues[locale.languageCode]?['firstName'] ?? 'First Name';
  String get lastName =>
      _localizedValues[locale.languageCode]?['lastName'] ?? 'Last Name';
  String get username =>
      _localizedValues[locale.languageCode]?['username'] ?? 'Username';
  String get birthday =>
      _localizedValues[locale.languageCode]?['birthday'] ?? 'Birthday';
  String get gender =>
      _localizedValues[locale.languageCode]?['gender'] ?? 'Gender';
  String get male => _localizedValues[locale.languageCode]?['male'] ?? 'Male';
  String get female =>
      _localizedValues[locale.languageCode]?['female'] ?? 'Female';
  String get other =>
      _localizedValues[locale.languageCode]?['other'] ?? 'Other';

  // Специалисты
  String get specialists =>
      _localizedValues[locale.languageCode]?['specialists'] ?? 'Specialists';
  String get specialist =>
      _localizedValues[locale.languageCode]?['specialist'] ?? 'Specialist';
  String get category =>
      _localizedValues[locale.languageCode]?['category'] ?? 'Category';
  String get categories =>
      _localizedValues[locale.languageCode]?['categories'] ?? 'Categories';
  String get service =>
      _localizedValues[locale.languageCode]?['service'] ?? 'Service';
  String get services =>
      _localizedValues[locale.languageCode]?['services'] ?? 'Services';
  String get price =>
      _localizedValues[locale.languageCode]?['price'] ?? 'Price';
  String get priceRange =>
      _localizedValues[locale.languageCode]?['priceRange'] ?? 'Price Range';
  String get rating =>
      _localizedValues[locale.languageCode]?['rating'] ?? 'Rating';
  String get reviews =>
      _localizedValues[locale.languageCode]?['reviews'] ?? 'Reviews';
  String get experience =>
      _localizedValues[locale.languageCode]?['experience'] ?? 'Experience';
  String get portfolio =>
      _localizedValues[locale.languageCode]?['portfolio'] ?? 'Portfolio';
  String get availability =>
      _localizedValues[locale.languageCode]?['availability'] ?? 'Availability';
  String get location =>
      _localizedValues[locale.languageCode]?['location'] ?? 'Location';
  String get distance =>
      _localizedValues[locale.languageCode]?['distance'] ?? 'Distance';
  String get book => _localizedValues[locale.languageCode]?['book'] ?? 'Book';
  String get booking =>
      _localizedValues[locale.languageCode]?['booking'] ?? 'Booking';
  String get bookings =>
      _localizedValues[locale.languageCode]?['bookings'] ?? 'Bookings';
  String get myBookings =>
      _localizedValues[locale.languageCode]?['myBookings'] ?? 'My Bookings';
  String get upcomingBookings =>
      _localizedValues[locale.languageCode]?['upcomingBookings'] ??
      'Upcoming Bookings';
  String get pastBookings =>
      _localizedValues[locale.languageCode]?['pastBookings'] ?? 'Past Bookings';
  String get cancelBooking =>
      _localizedValues[locale.languageCode]?['cancelBooking'] ??
      'Cancel Booking';
  String get rescheduleBooking =>
      _localizedValues[locale.languageCode]?['rescheduleBooking'] ??
      'Reschedule Booking';
  String get confirmBooking =>
      _localizedValues[locale.languageCode]?['confirmBooking'] ??
      'Confirm Booking';

  // События
  String get events =>
      _localizedValues[locale.languageCode]?['events'] ?? 'Events';
  String get event =>
      _localizedValues[locale.languageCode]?['event'] ?? 'Event';
  String get createEvent =>
      _localizedValues[locale.languageCode]?['createEvent'] ?? 'Create Event';
  String get editEvent =>
      _localizedValues[locale.languageCode]?['editEvent'] ?? 'Edit Event';
  String get deleteEvent =>
      _localizedValues[locale.languageCode]?['deleteEvent'] ?? 'Delete Event';
  String get eventTitle =>
      _localizedValues[locale.languageCode]?['eventTitle'] ?? 'Event Title';
  String get eventDescription =>
      _localizedValues[locale.languageCode]?['eventDescription'] ??
      'Event Description';
  String get eventDate =>
      _localizedValues[locale.languageCode]?['eventDate'] ?? 'Event Date';
  String get eventTime =>
      _localizedValues[locale.languageCode]?['eventTime'] ?? 'Event Time';
  String get eventDuration =>
      _localizedValues[locale.languageCode]?['eventDuration'] ??
      'Event Duration';
  String get eventLocation =>
      _localizedValues[locale.languageCode]?['eventLocation'] ??
      'Event Location';
  String get eventAddress =>
      _localizedValues[locale.languageCode]?['eventAddress'] ?? 'Event Address';
  String get eventType =>
      _localizedValues[locale.languageCode]?['eventType'] ?? 'Event Type';
  String get eventSize =>
      _localizedValues[locale.languageCode]?['eventSize'] ?? 'Event Size';
  String get eventBudget =>
      _localizedValues[locale.languageCode]?['eventBudget'] ?? 'Event Budget';
  String get eventStatus =>
      _localizedValues[locale.languageCode]?['eventStatus'] ?? 'Event Status';
  String get eventGuests =>
      _localizedValues[locale.languageCode]?['eventGuests'] ?? 'Event Guests';
  String get eventPhotos =>
      _localizedValues[locale.languageCode]?['eventPhotos'] ?? 'Event Photos';
  String get eventVideos =>
      _localizedValues[locale.languageCode]?['eventVideos'] ?? 'Event Videos';

  // Платежи
  String get payment =>
      _localizedValues[locale.languageCode]?['payment'] ?? 'Payment';
  String get payments =>
      _localizedValues[locale.languageCode]?['payments'] ?? 'Payments';
  String get pay => _localizedValues[locale.languageCode]?['pay'] ?? 'Pay';
  String get paid => _localizedValues[locale.languageCode]?['paid'] ?? 'Paid';
  String get unpaid =>
      _localizedValues[locale.languageCode]?['unpaid'] ?? 'Unpaid';
  String get pending =>
      _localizedValues[locale.languageCode]?['pending'] ?? 'Pending';
  String get completed =>
      _localizedValues[locale.languageCode]?['completed'] ?? 'Completed';
  String get cancelled =>
      _localizedValues[locale.languageCode]?['cancelled'] ?? 'Cancelled';
  String get refunded =>
      _localizedValues[locale.languageCode]?['refunded'] ?? 'Refunded';
  String get amount =>
      _localizedValues[locale.languageCode]?['amount'] ?? 'Amount';
  String get total =>
      _localizedValues[locale.languageCode]?['total'] ?? 'Total';
  String get subtotal =>
      _localizedValues[locale.languageCode]?['subtotal'] ?? 'Subtotal';
  String get tax => _localizedValues[locale.languageCode]?['tax'] ?? 'Tax';
  String get discount =>
      _localizedValues[locale.languageCode]?['discount'] ?? 'Discount';
  String get tip => _localizedValues[locale.languageCode]?['tip'] ?? 'Tip';
  String get currency =>
      _localizedValues[locale.languageCode]?['currency'] ?? 'Currency';
  String get paymentMethod =>
      _localizedValues[locale.languageCode]?['paymentMethod'] ??
      'Payment Method';
  String get creditCard =>
      _localizedValues[locale.languageCode]?['creditCard'] ?? 'Credit Card';
  String get debitCard =>
      _localizedValues[locale.languageCode]?['debitCard'] ?? 'Debit Card';
  String get bankTransfer =>
      _localizedValues[locale.languageCode]?['bankTransfer'] ?? 'Bank Transfer';
  String get cash => _localizedValues[locale.languageCode]?['cash'] ?? 'Cash';
  String get wallet =>
      _localizedValues[locale.languageCode]?['wallet'] ?? 'Wallet';
  String get invoice =>
      _localizedValues[locale.languageCode]?['invoice'] ?? 'Invoice';
  String get receipt =>
      _localizedValues[locale.languageCode]?['receipt'] ?? 'Receipt';

  // Статусы
  String get status =>
      _localizedValues[locale.languageCode]?['status'] ?? 'Status';
  String get active =>
      _localizedValues[locale.languageCode]?['active'] ?? 'Active';
  String get inactive =>
      _localizedValues[locale.languageCode]?['inactive'] ?? 'Inactive';
  String get available =>
      _localizedValues[locale.languageCode]?['available'] ?? 'Available';
  String get unavailable =>
      _localizedValues[locale.languageCode]?['unavailable'] ?? 'Unavailable';
  String get online =>
      _localizedValues[locale.languageCode]?['online'] ?? 'Online';
  String get offline =>
      _localizedValues[locale.languageCode]?['offline'] ?? 'Offline';
  String get verified =>
      _localizedValues[locale.languageCode]?['verified'] ?? 'Verified';
  String get unverified =>
      _localizedValues[locale.languageCode]?['unverified'] ?? 'Unverified';
  String get approved =>
      _localizedValues[locale.languageCode]?['approved'] ?? 'Approved';
  String get rejected =>
      _localizedValues[locale.languageCode]?['rejected'] ?? 'Rejected';
  String get draft =>
      _localizedValues[locale.languageCode]?['draft'] ?? 'Draft';
  String get published =>
      _localizedValues[locale.languageCode]?['published'] ?? 'Published';
  String get archived =>
      _localizedValues[locale.languageCode]?['archived'] ?? 'Archived';

  // Время и дата
  String get today =>
      _localizedValues[locale.languageCode]?['today'] ?? 'Today';
  String get tomorrow =>
      _localizedValues[locale.languageCode]?['tomorrow'] ?? 'Tomorrow';
  String get yesterday =>
      _localizedValues[locale.languageCode]?['yesterday'] ?? 'Yesterday';
  String get thisWeek =>
      _localizedValues[locale.languageCode]?['thisWeek'] ?? 'This Week';
  String get nextWeek =>
      _localizedValues[locale.languageCode]?['nextWeek'] ?? 'Next Week';
  String get lastWeek =>
      _localizedValues[locale.languageCode]?['lastWeek'] ?? 'Last Week';
  String get thisMonth =>
      _localizedValues[locale.languageCode]?['thisMonth'] ?? 'This Month';
  String get nextMonth =>
      _localizedValues[locale.languageCode]?['nextMonth'] ?? 'Next Month';
  String get lastMonth =>
      _localizedValues[locale.languageCode]?['lastMonth'] ?? 'Last Month';
  String get thisYear =>
      _localizedValues[locale.languageCode]?['thisYear'] ?? 'This Year';
  String get nextYear =>
      _localizedValues[locale.languageCode]?['nextYear'] ?? 'Next Year';
  String get lastYear =>
      _localizedValues[locale.languageCode]?['lastYear'] ?? 'Last Year';
  String get morning =>
      _localizedValues[locale.languageCode]?['morning'] ?? 'Morning';
  String get afternoon =>
      _localizedValues[locale.languageCode]?['afternoon'] ?? 'Afternoon';
  String get evening =>
      _localizedValues[locale.languageCode]?['evening'] ?? 'Evening';
  String get night =>
      _localizedValues[locale.languageCode]?['night'] ?? 'Night';

  // Дни недели
  String get monday =>
      _localizedValues[locale.languageCode]?['monday'] ?? 'Monday';
  String get tuesday =>
      _localizedValues[locale.languageCode]?['tuesday'] ?? 'Tuesday';
  String get wednesday =>
      _localizedValues[locale.languageCode]?['wednesday'] ?? 'Wednesday';
  String get thursday =>
      _localizedValues[locale.languageCode]?['thursday'] ?? 'Thursday';
  String get friday =>
      _localizedValues[locale.languageCode]?['friday'] ?? 'Friday';
  String get saturday =>
      _localizedValues[locale.languageCode]?['saturday'] ?? 'Saturday';
  String get sunday =>
      _localizedValues[locale.languageCode]?['sunday'] ?? 'Sunday';

  // Месяцы
  String get january =>
      _localizedValues[locale.languageCode]?['january'] ?? 'January';
  String get february =>
      _localizedValues[locale.languageCode]?['february'] ?? 'February';
  String get march =>
      _localizedValues[locale.languageCode]?['march'] ?? 'March';
  String get april =>
      _localizedValues[locale.languageCode]?['april'] ?? 'April';
  String get may => _localizedValues[locale.languageCode]?['may'] ?? 'May';
  String get june => _localizedValues[locale.languageCode]?['june'] ?? 'June';
  String get july => _localizedValues[locale.languageCode]?['july'] ?? 'July';
  String get august =>
      _localizedValues[locale.languageCode]?['august'] ?? 'August';
  String get september =>
      _localizedValues[locale.languageCode]?['september'] ?? 'September';
  String get october =>
      _localizedValues[locale.languageCode]?['october'] ?? 'October';
  String get november =>
      _localizedValues[locale.languageCode]?['november'] ?? 'November';
  String get december =>
      _localizedValues[locale.languageCode]?['december'] ?? 'December';

  // Ошибки
  String get errorOccurred =>
      _localizedValues[locale.languageCode]?['errorOccurred'] ??
      'An error occurred';
  String get networkError =>
      _localizedValues[locale.languageCode]?['networkError'] ?? 'Network error';
  String get serverError =>
      _localizedValues[locale.languageCode]?['serverError'] ?? 'Server error';
  String get connectionError =>
      _localizedValues[locale.languageCode]?['connectionError'] ??
      'Connection error';
  String get timeoutError =>
      _localizedValues[locale.languageCode]?['timeoutError'] ?? 'Timeout error';
  String get notFoundError =>
      _localizedValues[locale.languageCode]?['notFoundError'] ?? 'Not found';
  String get unauthorizedError =>
      _localizedValues[locale.languageCode]?['unauthorizedError'] ??
      'Unauthorized';
  String get forbiddenError =>
      _localizedValues[locale.languageCode]?['forbiddenError'] ?? 'Forbidden';
  String get validationError =>
      _localizedValues[locale.languageCode]?['validationError'] ??
      'Validation error';
  String get invalidInput =>
      _localizedValues[locale.languageCode]?['invalidInput'] ?? 'Invalid input';
  String get requiredField =>
      _localizedValues[locale.languageCode]?['requiredField'] ??
      'This field is required';
  String get invalidEmail =>
      _localizedValues[locale.languageCode]?['invalidEmail'] ??
      'Invalid email address';
  String get invalidPhone =>
      _localizedValues[locale.languageCode]?['invalidPhone'] ??
      'Invalid phone number';
  String get passwordTooShort =>
      _localizedValues[locale.languageCode]?['passwordTooShort'] ??
      'Password is too short';
  String get passwordMismatch =>
      _localizedValues[locale.languageCode]?['passwordMismatch'] ??
      'Passwords do not match';

  // Успешные операции
  String get successMessage =>
      _localizedValues[locale.languageCode]?['successMessage'] ??
      'Operation completed successfully';
  String get savedSuccessfully =>
      _localizedValues[locale.languageCode]?['savedSuccessfully'] ??
      'Saved successfully';
  String get deletedSuccessfully =>
      _localizedValues[locale.languageCode]?['deletedSuccessfully'] ??
      'Deleted successfully';
  String get updatedSuccessfully =>
      _localizedValues[locale.languageCode]?['updatedSuccessfully'] ??
      'Updated successfully';
  String get createdSuccessfully =>
      _localizedValues[locale.languageCode]?['createdSuccessfully'] ??
      'Created successfully';
  String get sentSuccessfully =>
      _localizedValues[locale.languageCode]?['sentSuccessfully'] ??
      'Sent successfully';
  String get uploadedSuccessfully =>
      _localizedValues[locale.languageCode]?['uploadedSuccessfully'] ??
      'Uploaded successfully';
  String get downloadedSuccessfully =>
      _localizedValues[locale.languageCode]?['downloadedSuccessfully'] ??
      'Downloaded successfully';

  // Подтверждения
  String get confirmDelete =>
      _localizedValues[locale.languageCode]?['confirmDelete'] ??
      'Are you sure you want to delete this item?';
  String get confirmCancel =>
      _localizedValues[locale.languageCode]?['confirmCancel'] ??
      'Are you sure you want to cancel this operation?';
  String get confirmLogout =>
      _localizedValues[locale.languageCode]?['confirmLogout'] ??
      'Are you sure you want to logout?';
  String get confirmExit =>
      _localizedValues[locale.languageCode]?['confirmExit'] ??
      'Are you sure you want to exit?';
  String get unsavedChanges =>
      _localizedValues[locale.languageCode]?['unsavedChanges'] ??
      'You have unsaved changes. Do you want to save them?';
  String get discardChanges =>
      _localizedValues[locale.languageCode]?['discardChanges'] ??
      'Discard changes?';

  // Пустые состояния
  String get noData =>
      _localizedValues[locale.languageCode]?['noData'] ?? 'No data available';
  String get noResults =>
      _localizedValues[locale.languageCode]?['noResults'] ?? 'No results found';
  String get noBookings =>
      _localizedValues[locale.languageCode]?['noBookings'] ??
      'No bookings found';
  String get noSpecialists =>
      _localizedValues[locale.languageCode]?['noSpecialists'] ??
      'No specialists found';
  String get noEvents =>
      _localizedValues[locale.languageCode]?['noEvents'] ?? 'No events found';
  String get noMessages =>
      _localizedValues[locale.languageCode]?['noMessages'] ?? 'No messages';
  String get noNotifications =>
      _localizedValues[locale.languageCode]?['noNotifications'] ??
      'No notifications';
  String get noFavorites =>
      _localizedValues[locale.languageCode]?['noFavorites'] ?? 'No favorites';
  String get noHistory =>
      _localizedValues[locale.languageCode]?['noHistory'] ?? 'No history';
  String get noReviews =>
      _localizedValues[locale.languageCode]?['noReviews'] ?? 'No reviews';
  String get noPhotos =>
      _localizedValues[locale.languageCode]?['noPhotos'] ?? 'No photos';
  String get noVideos =>
      _localizedValues[locale.languageCode]?['noVideos'] ?? 'No videos';

  // Загрузка
  String get loadingData =>
      _localizedValues[locale.languageCode]?['loadingData'] ??
      'Loading data...';
  String get loadingMore =>
      _localizedValues[locale.languageCode]?['loadingMore'] ??
      'Loading more...';
  String get refreshing =>
      _localizedValues[locale.languageCode]?['refreshing'] ?? 'Refreshing...';
  String get uploading =>
      _localizedValues[locale.languageCode]?['uploading'] ?? 'Uploading...';
  String get downloading =>
      _localizedValues[locale.languageCode]?['downloading'] ?? 'Downloading...';
  String get processing =>
      _localizedValues[locale.languageCode]?['processing'] ?? 'Processing...';
  String get saving =>
      _localizedValues[locale.languageCode]?['saving'] ?? 'Saving...';
  String get deleting =>
      _localizedValues[locale.languageCode]?['deleting'] ?? 'Deleting...';
  String get updating =>
      _localizedValues[locale.languageCode]?['updating'] ?? 'Updating...';
  String get creating =>
      _localizedValues[locale.languageCode]?['creating'] ?? 'Creating...';
  String get sending =>
      _localizedValues[locale.languageCode]?['sending'] ?? 'Sending...';

  // Разрешения
  String get permissionRequired =>
      _localizedValues[locale.languageCode]?['permissionRequired'] ??
      'Permission required';
  String get cameraPermission =>
      _localizedValues[locale.languageCode]?['cameraPermission'] ??
      'Camera permission is required';
  String get microphonePermission =>
      _localizedValues[locale.languageCode]?['microphonePermission'] ??
      'Microphone permission is required';
  String get locationPermission =>
      _localizedValues[locale.languageCode]?['locationPermission'] ??
      'Location permission is required';
  String get storagePermission =>
      _localizedValues[locale.languageCode]?['storagePermission'] ??
      'Storage permission is required';
  String get notificationPermission =>
      _localizedValues[locale.languageCode]?['notificationPermission'] ??
      'Notification permission is required';
  String get grantPermission =>
      _localizedValues[locale.languageCode]?['grantPermission'] ??
      'Grant Permission';
  String get openSettings =>
      _localizedValues[locale.languageCode]?['openSettings'] ?? 'Open Settings';

  // Настройки
  String get language =>
      _localizedValues[locale.languageCode]?['language'] ?? 'Language';
  String get theme =>
      _localizedValues[locale.languageCode]?['theme'] ?? 'Theme';
  String get lightTheme =>
      _localizedValues[locale.languageCode]?['lightTheme'] ?? 'Light Theme';
  String get darkTheme =>
      _localizedValues[locale.languageCode]?['darkTheme'] ?? 'Dark Theme';
  String get systemTheme =>
      _localizedValues[locale.languageCode]?['systemTheme'] ?? 'System Theme';
  String get notifications =>
      _localizedValues[locale.languageCode]?['notifications'] ??
      'Notifications';
  String get pushNotifications =>
      _localizedValues[locale.languageCode]?['pushNotifications'] ??
      'Push Notifications';
  String get emailNotifications =>
      _localizedValues[locale.languageCode]?['emailNotifications'] ??
      'Email Notifications';
  String get smsNotifications =>
      _localizedValues[locale.languageCode]?['smsNotifications'] ??
      'SMS Notifications';
  String get privacy =>
      _localizedValues[locale.languageCode]?['privacy'] ?? 'Privacy';
  String get security =>
      _localizedValues[locale.languageCode]?['security'] ?? 'Security';
  String get account =>
      _localizedValues[locale.languageCode]?['account'] ?? 'Account';
  String get profile =>
      _localizedValues[locale.languageCode]?['profile'] ?? 'Profile';
  String get preferences =>
      _localizedValues[locale.languageCode]?['preferences'] ?? 'Preferences';
  String get advanced =>
      _localizedValues[locale.languageCode]?['advanced'] ?? 'Advanced';
  String get about =>
      _localizedValues[locale.languageCode]?['about'] ?? 'About';
  String get version =>
      _localizedValues[locale.languageCode]?['version'] ?? 'Version';
  String get build =>
      _localizedValues[locale.languageCode]?['build'] ?? 'Build';
  String get developer =>
      _localizedValues[locale.languageCode]?['developer'] ?? 'Developer';
  String get license =>
      _localizedValues[locale.languageCode]?['license'] ?? 'License';
  String get termsOfService =>
      _localizedValues[locale.languageCode]?['termsOfService'] ??
      'Terms of Service';
  String get privacyPolicy =>
      _localizedValues[locale.languageCode]?['privacyPolicy'] ??
      'Privacy Policy';
  String get cookiePolicy =>
      _localizedValues[locale.languageCode]?['cookiePolicy'] ?? 'Cookie Policy';

  // Словарь локализованных значений
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Общие строки
      'appTitle': 'Event Marketplace',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',
      'refresh': 'Refresh',
      'retry': 'Retry',
      'back': 'Back',
      'next': 'Next',
      'previous': 'Previous',
      'done': 'Done',
      'close': 'Close',
      'open': 'Open',
      'view': 'View',
      'hide': 'Hide',
      'show': 'Show',
      'select': 'Select',
      'deselect': 'Deselect',
      'all': 'All',
      'none': 'None',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
    },
    'ru': {
      // Общие строки
      'appTitle': 'Маркетплейс Событий',
      'loading': 'Загрузка...',
      'error': 'Ошибка',
      'success': 'Успех',
      'cancel': 'Отмена',
      'confirm': 'Подтвердить',
      'save': 'Сохранить',
      'delete': 'Удалить',
      'edit': 'Редактировать',
      'add': 'Добавить',
      'search': 'Поиск',
      'filter': 'Фильтр',
      'sort': 'Сортировка',
      'refresh': 'Обновить',
      'retry': 'Повторить',
      'back': 'Назад',
      'next': 'Далее',
      'previous': 'Предыдущий',
      'done': 'Готово',
      'close': 'Закрыть',
      'open': 'Открыть',
      'view': 'Просмотр',
      'hide': 'Скрыть',
      'show': 'Показать',
      'select': 'Выбрать',
      'deselect': 'Отменить выбор',
      'all': 'Все',
      'none': 'Ничего',
      'yes': 'Да',
      'no': 'Нет',
      'ok': 'ОК',
    },
    'kk': {
      // Общие строки
      'appTitle': 'Оқиға Нарығы',
      'loading': 'Жүктелуде...',
      'error': 'Қате',
      'success': 'Сәтті',
      'cancel': 'Болдырмау',
      'confirm': 'Растау',
      'save': 'Сақтау',
      'delete': 'Жою',
      'edit': 'Өңдеу',
      'add': 'Қосу',
      'search': 'Іздеу',
      'filter': 'Сүзгі',
      'sort': 'Сұрыптау',
      'refresh': 'Жаңарту',
      'retry': 'Қайталау',
      'back': 'Артқа',
      'next': 'Келесі',
      'previous': 'Алдыңғы',
      'done': 'Дайын',
      'close': 'Жабу',
      'open': 'Ашу',
      'view': 'Көру',
      'hide': 'Жасыру',
      'show': 'Көрсету',
      'select': 'Таңдау',
      'deselect': 'Таңдауды болдырмау',
      'all': 'Барлығы',
      'none': 'Ешқандай',
      'yes': 'Иә',
      'no': 'Жоқ',
      'ok': 'Жарайды',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ru', 'kk'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
