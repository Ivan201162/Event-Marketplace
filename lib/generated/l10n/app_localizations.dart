import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Event Marketplace'**
  String get appTitle;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Text for users who don't have an account
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Text for users who already have an account
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Google sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// VK sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign in with VK'**
  String get signInWithVK;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Events tab label
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// Bookings tab label
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings tab label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Search events field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search events...'**
  String get searchEvents;

  /// Filter button text
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Sort button text
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Date field label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Time field label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Location field label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Price characteristic
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Free price label
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// Description field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Category field label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Organizer field label
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizer;

  /// Capacity field label
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// Available spots label
  ///
  /// In en, this message translates to:
  /// **'Available spots'**
  String get availableSpots;

  /// Book event button text
  ///
  /// In en, this message translates to:
  /// **'Book Event'**
  String get bookEvent;

  /// Cancel booking button text
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// Edit event button text
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// Delete event button text
  ///
  /// In en, this message translates to:
  /// **'Delete Event'**
  String get deleteEvent;

  /// Create event button text
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// My events tab label
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get myEvents;

  /// Favorites tab label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Add to favorites button text
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// Remove from favorites button text
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// Reviews tab label
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// Write review button text
  ///
  /// In en, this message translates to:
  /// **'Write Review'**
  String get writeReview;

  /// Rating field label
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// Review title label
  ///
  /// In en, this message translates to:
  /// **'Review Title'**
  String get reviewTitle;

  /// Review content field label
  ///
  /// In en, this message translates to:
  /// **'Review Content'**
  String get reviewContent;

  /// Submit review button text
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// Notifications tab label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Enable notifications setting
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Russian language option
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russian;

  /// Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Edit profile button text
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Yes button text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No data message
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// Try again button text
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Previous button text
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Done button text
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Select button text
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// Upload button text
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// Download button text
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Share button text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Copy button text
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Paste button text
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Cut button text
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// Undo button text
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Redo button text
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// Help button text
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// About button text
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Contact button text
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// Privacy policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy;

  /// Terms of service link text
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get terms;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Build label
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get build;

  /// Last updated label
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// Created by label
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdBy;

  /// All rights reserved text
  ///
  /// In en, this message translates to:
  /// **'All rights reserved'**
  String get allRightsReserved;

  /// Specialists tab label
  ///
  /// In en, this message translates to:
  /// **'Specialists'**
  String get specialists;

  /// Recommendations tab label
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// Chats tab label
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// My bookings tab label
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// Booking requests tab label
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get bookingRequests;

  /// Admin panel tab label
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// Debug tab label
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug;

  /// Search specialists header
  ///
  /// In en, this message translates to:
  /// **'Search Specialists'**
  String get searchSpecialists;

  /// No specialists found message
  ///
  /// In en, this message translates to:
  /// **'No specialists found'**
  String get noSpecialistsFound;

  /// Book specialist button text
  ///
  /// In en, this message translates to:
  /// **'Book Specialist'**
  String get bookSpecialist;

  /// View profile button text
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// Specialist profile header
  ///
  /// In en, this message translates to:
  /// **'Specialist Profile'**
  String get specialistProfile;

  /// Specialization label
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get specialization;

  /// Experience label
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// Portfolio label
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// Availability label
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// Price per hour label
  ///
  /// In en, this message translates to:
  /// **'Price per hour'**
  String get pricePerHour;

  /// Contact specialist button text
  ///
  /// In en, this message translates to:
  /// **'Contact Specialist'**
  String get contactSpecialist;

  /// Booking form header
  ///
  /// In en, this message translates to:
  /// **'Booking Form'**
  String get bookingForm;

  /// Select service placeholder
  ///
  /// In en, this message translates to:
  /// **'Select service'**
  String get selectService;

  /// Select date placeholder
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// Select time placeholder
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// Duration label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Hours unit
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// Additional notes label
  ///
  /// In en, this message translates to:
  /// **'Additional notes'**
  String get additionalNotes;

  /// Create booking button text
  ///
  /// In en, this message translates to:
  /// **'Create Booking'**
  String get createBooking;

  /// Booking created success message
  ///
  /// In en, this message translates to:
  /// **'Booking created successfully'**
  String get bookingCreated;

  /// Booking creation error message
  ///
  /// In en, this message translates to:
  /// **'Booking creation error'**
  String get bookingError;

  /// Chat header
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Type message placeholder
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// Send message button text
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No messages message
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get noMessages;

  /// Start conversation call to action
  ///
  /// In en, this message translates to:
  /// **'Start conversation'**
  String get startConversation;

  /// Chat info header
  ///
  /// In en, this message translates to:
  /// **'Chat Info'**
  String get chatInfo;

  /// Create review header
  ///
  /// In en, this message translates to:
  /// **'Create Review'**
  String get createReview;

  /// Rate quality header
  ///
  /// In en, this message translates to:
  /// **'Rate the quality of work'**
  String get rateQuality;

  /// Excellent rating
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// Good rating
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// Satisfactory rating
  ///
  /// In en, this message translates to:
  /// **'Satisfactory'**
  String get satisfactory;

  /// Poor rating
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// Very poor rating
  ///
  /// In en, this message translates to:
  /// **'Very Poor'**
  String get veryPoor;

  /// Detailed review label
  ///
  /// In en, this message translates to:
  /// **'Detailed Review'**
  String get detailedReview;

  /// Select characteristics header
  ///
  /// In en, this message translates to:
  /// **'Select appropriate characteristics'**
  String get selectCharacteristics;

  /// Professionalism characteristic
  ///
  /// In en, this message translates to:
  /// **'Professionalism'**
  String get professionalism;

  /// Punctuality characteristic
  ///
  /// In en, this message translates to:
  /// **'Punctuality'**
  String get punctuality;

  /// Work quality characteristic
  ///
  /// In en, this message translates to:
  /// **'Work Quality'**
  String get workQuality;

  /// Communication characteristic
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get communication;

  /// Recommend characteristic
  ///
  /// In en, this message translates to:
  /// **'Recommend'**
  String get recommend;

  /// Privacy settings header
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// Public review setting
  ///
  /// In en, this message translates to:
  /// **'Public Review'**
  String get publicReview;

  /// Public review description
  ///
  /// In en, this message translates to:
  /// **'Review will be visible to other users'**
  String get reviewVisibleToOthers;

  /// Review submitted success message
  ///
  /// In en, this message translates to:
  /// **'Review submitted successfully'**
  String get reviewSubmitted;

  /// Review submission error message
  ///
  /// In en, this message translates to:
  /// **'Review submission error'**
  String get reviewError;

  /// Mark all as read button text
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// Clear all notifications button text
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications'**
  String get clearAllNotifications;

  /// No notifications message
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// Notifications place description
  ///
  /// In en, this message translates to:
  /// **'Important notifications will appear here'**
  String get notificationsWillAppearHere;

  /// Contact support button text
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// Choose contact method description
  ///
  /// In en, this message translates to:
  /// **'Choose a convenient way to contact our support service:'**
  String get chooseContactMethod;

  /// Create ticket button text
  ///
  /// In en, this message translates to:
  /// **'Create Ticket'**
  String get createTicket;

  /// Search questions placeholder
  ///
  /// In en, this message translates to:
  /// **'Search questions...'**
  String get searchQuestions;

  /// No questions message
  ///
  /// In en, this message translates to:
  /// **'No questions'**
  String get noQuestions;

  /// Questions place description
  ///
  /// In en, this message translates to:
  /// **'Questions and answers will appear here'**
  String get questionsWillAppearHere;

  /// Nothing found message
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get nothingFound;

  /// Try different query suggestion
  ///
  /// In en, this message translates to:
  /// **'Try changing your search query'**
  String get tryDifferentQuery;

  /// App description
  ///
  /// In en, this message translates to:
  /// **'Event Marketplace is a platform for finding and booking specialists for various events. Find the perfect host, photographer, musician or other specialist for your event.'**
  String get appDescription;

  /// Main features header
  ///
  /// In en, this message translates to:
  /// **'Main Features'**
  String get mainFeatures;

  /// Search specialists feature description
  ///
  /// In en, this message translates to:
  /// **'Find the right specialist by category, location and reviews'**
  String get searchSpecialistsFeature;

  /// Booking feature description
  ///
  /// In en, this message translates to:
  /// **'Book a specialist for a convenient time and date'**
  String get bookingFeature;

  /// Communication feature description
  ///
  /// In en, this message translates to:
  /// **'Communicate with specialists through built-in chat'**
  String get communicationFeature;

  /// Reviews feature description
  ///
  /// In en, this message translates to:
  /// **'Leave reviews and read opinions from other users'**
  String get reviewsFeature;

  /// Payments feature description
  ///
  /// In en, this message translates to:
  /// **'Secure payment system for services'**
  String get paymentsFeature;

  /// Developer info header
  ///
  /// In en, this message translates to:
  /// **'Developer Information'**
  String get developerInfo;

  /// Developer label
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// Support email
  ///
  /// In en, this message translates to:
  /// **'support@eventmarketplace.com'**
  String get supportEmail;

  /// Website label
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Website URL
  ///
  /// In en, this message translates to:
  /// **'www.eventmarketplace.com'**
  String get websiteUrl;

  /// 24/7 support
  ///
  /// In en, this message translates to:
  /// **'24/7'**
  String get support24_7;

  /// Privacy policy header
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Privacy policy text
  ///
  /// In en, this message translates to:
  /// **'The privacy policy of the application will be placed here. This document describes how we collect, use and protect your personal information.'**
  String get privacyPolicyText;

  /// Terms of service header
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Terms of service text
  ///
  /// In en, this message translates to:
  /// **'The terms of use of the application will be placed here. This document describes the rules and conditions for using our platform.'**
  String get termsOfServiceText;

  /// Open source licenses header
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get openSourceLicenses;

  /// Clear all button text
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Clear all notifications confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all notifications?'**
  String get clearAllNotificationsConfirm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
