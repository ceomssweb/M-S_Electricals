import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-owned service that manages language selection & translation state.
class LanguageService extends ChangeNotifier {
  static const String _prefKey = 'app_language_code';

  String _currentLanguageCode = 'en';
  String get currentLanguageCode => _currentLanguageCode;

  String get currentLanguageName {
    switch (_currentLanguageCode) {
      case 'ta':
        return 'Tamil (தமிழ்)';
      case 'hi':
        return 'Hindi (हिंदी)';
      case 'en':
      default:
        return 'English';
    }
  }

  /// Initialize and load saved language from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && _translations.containsKey(savedCode)) {
        _currentLanguageCode = savedCode;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error initializing LanguageService: $e');
    }
  }

  /// Change active language code ('en', 'ta', 'hi')
  Future<void> setLanguage(String code) async {
    if (!_translations.containsKey(code)) return;
    _currentLanguageCode = code;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (e) {
      debugPrint('Error saving language code: $e');
    }
  }

  /// Look up translation string by key with English fallback
  String t(String key) {
    final langMap = _translations[_currentLanguageCode];
    if (langMap != null && langMap.containsKey(key)) {
      return langMap[key]!;
    }
    // Fallback to English
    return _translations['en']?[key] ?? key;
  }

  /// Category name translation helper
  String category(String rawCategory) {
    return t('cat_$rawCategory');
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // Navigation
      'nav_home': 'Home',
      'nav_bookings': 'Bookings',
      'nav_profile': 'Profile',
      'nav_settings': 'Settings',

      // Home Page
      'home_greeting': 'What electrical service do you need today?',
      'home_search_hint': 'Search wiring, AC repair, lighting...',
      'home_categories_title': 'Categories & Shortcuts',
      'home_popular_services': 'Popular Services',
      'home_category_prefix': 'Category: ',
      'home_reset_filters': 'Reset filters',

      // Categories
      'cat_All': 'All',
      'cat_Wiring': 'Wiring',
      'cat_Lighting': 'Lighting',
      'cat_AC': 'AC',
      'cat_Fan': 'Fan',
      'cat_Repair': 'Repair',
      'cat_Inspection': 'Inspection',
      'cat_Emergency': 'Emergency',

      // Auth & Common
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'sign_out': 'Sign Out',
      'welcome_guest': 'Welcome Guest',

      // Profile Page
      'profile_title': 'My Profile',
      'profile_sign_in_title': 'Sign In to View Profile',
      'profile_sign_in_desc':
          'Create an account or sign in to view your profile details, manage saved addresses, and track your bookings.',
      'profile_total_jobs': 'Total Jobs',
      'profile_active_jobs': 'Active',
      'profile_completed_jobs': 'Completed',
      'profile_saved_addresses': 'Saved Addresses',
      'profile_saved_addresses_sub': 'Manage home, office & work addresses',
      'profile_edit_personal_info': 'Edit Personal Info',
      'profile_help_support': 'Help & Support',
      'profile_help_support_sub': '24/7 hotline, FAQs & feedback',
      'profile_app_settings': 'App Settings',
      'profile_app_settings_sub': 'Push & email notifications, language',

      // Settings Page
      'settings_title': 'Settings',
      'settings_account_auth': 'Account & Authentication',
      'settings_account_desc':
          'Sign in to book electrical services faster, manage addresses & track status.',
      'settings_notifications_header': 'Notifications Preferences',
      'settings_push_notifications': 'Push Notifications',
      'settings_push_sub': 'Receive instant booking status alerts',
      'settings_email_notifications': 'Email Notifications',
      'settings_email_sub':
          'Receive invoices and status updates via email',
      'settings_send_test_push': 'Send Test Push Notification',
      'settings_app_preferences': 'App & Preferences',
      'settings_language': 'Language',
      'settings_select_language': 'Select Language',
      'settings_about_app': 'About App',
      'settings_privacy_policy': 'Privacy Policy',

      // Bookings Page
      'bookings_title': 'My Bookings',
      'bookings_search_hint': 'Search bookings by service name...',
      'bookings_empty': 'No matching bookings found.',

      // Booking Statuses
      'status_Pending': 'Pending',
      'status_Confirmed': 'Confirmed',
      'status_Assigned': 'Assigned',
      'status_In Progress': 'In Progress',
      'status_Completed': 'Completed',
      'status_Cancelled': 'Cancelled',
    },
    'ta': {
      // Navigation
      'nav_home': 'முகப்பு',
      'nav_bookings': 'பதிவுகள்',
      'nav_profile': 'சுயவிவரம்',
      'nav_settings': 'அமைப்புகள்',

      // Home Page
      'home_greeting': 'இன்று உங்களுக்கு என்ன மின் சேவை தேவை?',
      'home_search_hint': 'வயரிங், ஏசி பழுது, லைட்டிங் தேடவும்...',
      'home_categories_title': 'பிரிவுகள் & குறுக்குவழிகள்',
      'home_popular_services': 'பிரபலமான சேவைகள்',
      'home_category_prefix': 'பிரிவு: ',
      'home_reset_filters': 'வடிகட்டிகளை மீட்டமை',

      // Categories
      'cat_All': 'அனைத்தும்',
      'cat_Wiring': 'வயரிங்',
      'cat_Lighting': 'விளக்குகள்',
      'cat_AC': 'ஏசி',
      'cat_Fan': 'மின்விசிறி',
      'cat_Repair': 'பழுதுபார்ப்பு',
      'cat_Inspection': 'ஆய்வு',
      'cat_Emergency': 'அவசரம்',

      // Auth & Common
      'sign_in': 'உள்நுழைக',
      'sign_up': 'பதிவுசெய்க',
      'sign_out': 'வெளியேறு',
      'welcome_guest': 'வரவேற்கிறோம்',

      // Profile Page
      'profile_title': 'என் சுயவிவரம்',
      'profile_sign_in_title': 'சுயவிவரத்தைக் காண உள்நுழைக',
      'profile_sign_in_desc':
          'சுயவிவர விவரங்களைக் காண, முகவரிகளை நிர்வகிக்க மற்றும் பதிவுகளைப் பின்தொடர உள்நுழையவும்.',
      'profile_total_jobs': 'மொத்த வேலைகள்',
      'profile_active_jobs': 'செயலில் உள்ளவை',
      'profile_completed_jobs': 'முடிந்தவை',
      'profile_saved_addresses': 'சேமிக்கப்பட்ட முகவரிகள்',
      'profile_saved_addresses_sub': 'வீடு, அலுவலக முகவரிகளை நிர்வகிக்கவும்',
      'profile_edit_personal_info': 'தனிப்பட்ட தகவலைத் திருத்து',
      'profile_help_support': 'உதவி & ஆதரவு',
      'profile_help_support_sub': '24/7 ஹாட்லைன், கேள்விகள் & கருத்துகள்',
      'profile_app_settings': 'செயலி அமைப்புகள்',
      'profile_app_settings_sub': 'அறிவிப்புகள் மற்றும் மொழி',

      // Settings Page
      'settings_title': 'அமைப்புகள்',
      'settings_account_auth': 'கணக்கு & அங்கீகாரம்',
      'settings_account_desc':
          'சேவைகளை எளிதாக பதிவு செய்ய உள்நுழையவும்.',
      'settings_notifications_header': 'அறிவிப்பு விருப்பங்கள்',
      'settings_push_notifications': 'புஷ் அறிவிப்புகள்',
      'settings_push_sub': 'உடனடி நிலவர அறிவிப்புகளைப் பெறுங்கள்',
      'settings_email_notifications': 'மின்னஞ்சல் அறிவிப்புகள்',
      'settings_email_sub': 'ரசீதுகள் மற்றும் அறிவிப்புகளைப் பெறுங்கள்',
      'settings_send_test_push': 'சோதனை அறிவிப்பை அனுப்பு',
      'settings_app_preferences': 'செயலி விருப்பங்கள்',
      'settings_language': 'மொழி',
      'settings_select_language': 'மொழியைத் தேர்ந்தெடுக்கவும்',
      'settings_about_app': 'செயலியைப் பற்றி',
      'settings_privacy_policy': 'தனியுரிமைக் கொள்கை',

      // Bookings Page
      'bookings_title': 'என் பதிவுகள்',
      'bookings_search_hint': 'சேவை பெயரால் தேடவும்...',
      'bookings_empty': 'பதிவுகள் எதுவும் இல்லை.',

      // Booking Statuses
      'status_Pending': 'நிலுவையில்',
      'status_Confirmed': 'உறுதிசெய்யப்பட்டது',
      'status_Assigned': 'ஒதுக்கப்பட்டது',
      'status_In Progress': 'செயல்பாட்டில்',
      'status_Completed': 'நிறைவடைந்தது',
      'status_Cancelled': 'ரத்து செய்யப்பட்டது',
    },
    'hi': {
      // Navigation
      'nav_home': 'होम',
      'nav_bookings': 'बुकिंग',
      'nav_profile': 'प्रोफाइल',
      'nav_settings': 'सेटिंग्स',

      // Home Page
      'home_greeting': 'आज आपको कौन सी इलेक्ट्रिकल सेवा चाहिए?',
      'home_search_hint': 'वायरिंग, एसी मरम्मत, लाइटिंग खोजें...',
      'home_categories_title': 'श्रेणियाँ और शॉर्टकट्स',
      'home_popular_services': 'लोकप्रिय सेवाएं',
      'home_category_prefix': 'श्रेणी: ',
      'home_reset_filters': 'फ़िल्टर रीसेट करें',

      // Categories
      'cat_All': 'सभी',
      'cat_Wiring': 'वायरिंग',
      'cat_Lighting': 'लाइटिंग',
      'cat_AC': 'एसी',
      'cat_Fan': 'पंखा',
      'cat_Repair': 'मरम्मत',
      'cat_Inspection': 'निरीक्षण',
      'cat_Emergency': 'आपातकालीन',

      // Auth & Common
      'sign_in': 'साइन इन',
      'sign_up': 'साइन अप',
      'sign_out': 'साइन आउट',
      'welcome_guest': 'स्वागत है',

      // Profile Page
      'profile_title': 'मेरी प्रोफाइल',
      'profile_sign_in_title': 'प्रोफाइल देखने के लिए साइन इन करें',
      'profile_sign_in_desc':
          'अपनी प्रोफाइल देखने, पते प्रबंधित करने और बुकिंग को ट्रैक करने के लिए साइन इन करें।',
      'profile_total_jobs': 'कुल कार्य',
      'profile_active_jobs': 'सक्रिय',
      'profile_completed_jobs': 'पूरा हुआ',
      'profile_saved_addresses': 'सहेजे गए पते',
      'profile_saved_addresses_sub': 'घर और कार्यालय पते प्रबंधित करें',
      'profile_edit_personal_info': 'व्यक्तिगत जानकारी संपादित करें',
      'profile_help_support': 'सहायता और सहायता',
      'profile_help_support_sub': '24/7 हेल्पलाइन, एफएक्यू और प्रतिक्रिया',
      'profile_app_settings': 'ऐप सेटिंग्स',
      'profile_app_settings_sub': 'सूचनाएं और भाषा',

      // Settings Page
      'settings_title': 'सेटिंग्स',
      'settings_account_auth': 'खाता और प्रमाणीकरण',
      'settings_account_desc':
          'इलेक्ट्रिकल सेवाओं को तेजी से बुक करने के लिए साइन इन करें।',
      'settings_notifications_header': 'सूचना प्राथमिकताएं',
      'settings_push_notifications': 'पुश सूचनाएं',
      'settings_push_sub': 'तुरंत बुकिंग स्थिति अलर्ट प्राप्त करें',
      'settings_email_notifications': 'ईमेल सूचनाएं',
      'settings_email_sub': 'ईमेल द्वारा चालान और अपडेट प्राप्त करें',
      'settings_send_test_push': 'परीक्षण सूचना भेजें',
      'settings_app_preferences': 'ऐप प्राथमिकताएं',
      'settings_language': 'भाषा',
      'settings_select_language': 'भाषा चुनें',
      'settings_about_app': 'ऐप के बारे में',
      'settings_privacy_policy': 'गोपनीयता नीति',

      // Bookings Page
      'bookings_title': 'मेरी बुकिंग',
      'bookings_search_hint': 'सेवा नाम से खोजें...',
      'bookings_empty': 'कोई बुकिंग नहीं मिली।',

      // Booking Statuses
      'status_Pending': 'लंबित',
      'status_Confirmed': 'पुष्टि की गई',
      'status_Assigned': 'सौंपा गया',
      'status_In Progress': 'प्रगति पर',
      'status_Completed': 'पूरा हुआ',
      'status_Cancelled': 'रद्द किया गया',
    },
  };
}
