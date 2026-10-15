import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'locale_cubit.dart';

/// Lightweight, dependency-free translation layer. Reads the current
/// [AppLanguage] from [LocaleCubit] and returns the matching string.
///
/// Usage in a widget's build: `final s = AppStrings.of(context);` then `s.settings`.
/// Because it `watch`es the cubit, the widget rebuilds when the language changes.
///
/// New strings: add a getter with its four translations. Migrate screens to use
/// these getters instead of hardcoded literals so they translate.
class AppStrings {
  final AppLanguage lang;
  const AppStrings(this.lang);

  static AppStrings of(BuildContext context) =>
      AppStrings(context.watch<LocaleCubit>().state);

  String _t(String en, String ur, String hi, String ar) {
    switch (lang) {
      case AppLanguage.urdu:
        return ur;
      case AppLanguage.hindi:
        return hi;
      case AppLanguage.arabic:
        return ar;
      case AppLanguage.english:
        return en;
    }
  }

  // ── Bottom navigation ──
  String get navHome => _t('Home', 'ہوم', 'होम', 'الرئيسية');
  String get navTournaments => _t('Tournaments', 'ٹورنامنٹ', 'टूर्नामेंट', 'البطولات');
  String get navRecords => _t('Records', 'ریکارڈ', 'रिकॉर्ड', 'السجلات');
  String get navProfile => _t('Profile', 'پروفائل', 'प्रोफ़ाइल', 'الملف الشخصي');

  // ── Language screen ──
  String get language => _t('Language', 'زبان', 'भाषा', 'اللغة');
  String get languageSubtitle => _t(
        'Choose your app language. Urdu & Arabic display right-to-left.',
        'اپنی ایپ کی زبان منتخب کریں۔ اردو اور عربی دائیں سے بائیں دکھائی دیتی ہیں۔',
        'अपनी ऐप की भाषा चुनें। उर्दू और अरबी दाएँ-से-बाएँ दिखती हैं।',
        'اختر لغة التطبيق. تُعرض الأردية والعربية من اليمين إلى اليسار.',
      );

  // ── Settings ──
  String get settings => _t('Settings', 'ترتیبات', 'सेटिंग्स', 'الإعدادات');
  String get account => _t('Account', 'اکاؤنٹ', 'खाता', 'الحساب');
  String get preferences => _t('Preferences', 'ترجیحات', 'प्राथमिकताएँ', 'التفضيلات');
  String get support => _t('Support', 'سپورٹ', 'सहायता', 'الدعم');
  String get editProfile => _t('Edit profile', 'پروفائل میں ترمیم', 'प्रोफ़ाइल संपादित करें', 'تعديل الملف الشخصي');
  String get notifications => _t('Notifications', 'اطلاعات', 'सूचनाएँ', 'الإشعارات');
  String get privacy => _t('Privacy', 'رازداری', 'गोपनीयता', 'الخصوصية');
  String get contactUs => _t('Contact us', 'ہم سے رابطہ کریں', 'संपर्क करें', 'اتصل بنا');
  String get aboutApp => _t('About PigeonFly', 'پیجن فلائی کے بارے میں', 'पिजनफ्लाई के बारे में', 'حول PigeonFly');
  String get logOut => _t('Log out', 'لاگ آؤٹ', 'लॉग आउट', 'تسجيل الخروج');

  // ── Common actions ──
  String get save => _t('Save', 'محفوظ کریں', 'सहेजें', 'حفظ');
  String get cancel => _t('Cancel', 'منسوخ', 'रद्द करें', 'إلغاء');
  String get rtl => _t('RTL', 'دائیں سے بائیں', 'दाएँ-से-बाएँ', 'يمين لليسار');
  String get seeAll => _t('See all', 'سب دیکھیں', 'सभी देखें', 'عرض الكل');
  String get follow => _t('Follow', 'فالو', 'फ़ॉलो', 'متابعة');
  String get following => _t('Following', 'فالو کر رہے ہیں', 'फ़ॉलो कर रहे हैं', 'تتابع');

  // ── Profile ──
  String get flyer => _t('Flyer', 'فلائر', 'फ़्लायर', 'مربّي');
  String get tournaments => _t('Tournaments', 'ٹورنامنٹ', 'टूर्नामेंट', 'البطولات');
  String get followers => _t('Followers', 'فالوورز', 'फ़ॉलोअर्स', 'المتابِعون');
  String get followingLabel => _t('Following', 'فالوئنگ', 'फ़ॉलोइंग', 'المتابَعون');
  String get myTournaments => _t('My Tournaments', 'میرے ٹورنامنٹ', 'मेरे टूर्नामेंट', 'بطولاتي');
  String get myPosts => _t('My Posts', 'میری پوسٹس', 'मेरी पोस्ट', 'منشوراتي');
  String get myRecords => _t('My Records', 'میرے ریکارڈ', 'मेरे रिकॉर्ड', 'سجلاتي');

  // ── Home ──
  String get liveNow => _t('Live now', 'ابھی لائیو', 'अभी लाइव', 'مباشر الآن');
  String get featuredTournament => _t('Featured tournament', 'نمایاں ٹورنامنٹ', 'फ़ीचर्ड टूर्नामेंट', 'بطولة مميزة');
  String get trendingTournaments => _t('Trending tournaments', 'مقبول ٹورنامنٹ', 'ट्रेंडिंग टूर्नामेंट', 'بطولات رائجة');
  String get feedCommunity => _t('Feed & Community Updates', 'فیڈ اور کمیونٹی اپڈیٹس', 'फ़ीड और समुदाय अपडेट', 'الموجز وتحديثات المجتمع');
  String get exploreAll => _t('Explore all', 'سب دریافت کریں', 'सभी देखें', 'استكشف الكل');
  String get shareLoftHint => _t('Share something about your loft…', 'اپنے لوفٹ کے بارے میں کچھ شیئر کریں…', 'अपने लॉफ़्ट के बारे में कुछ साझा करें…', 'شارك شيئًا عن برجك…');
  String get noPostsInFeed => _t('No posts yet in feed', 'فیڈ میں ابھی کوئی پوسٹ نہیں', 'फ़ीड में अभी कोई पोस्ट नहीं', 'لا منشورات بعد');

  // ── Records ──
  String get noRecordsYet => _t('No records yet', 'ابھی کوئی ریکارڈ نہیں', 'अभी कोई रिकॉर्ड नहीं', 'لا سجلات بعد');
  String get addRecordHint => _t('Add a record to track your flights.', 'اپنی اڑانوں کا ریکارڈ رکھنے کے لیے ریکارڈ شامل کریں۔', 'अपनी उड़ानों को ट्रैक करने के लिए रिकॉर्ड जोड़ें।', 'أضف سجلاً لتتبّع رحلاتك.');
  String get newRecord => _t('New record', 'نیا ریکارڈ', 'नया रिकॉर्ड', 'سجل جديد');
  String get addFirstRecord => _t('Add your first record', 'اپنا پہلا ریکارڈ شامل کریں', 'अपना पहला रिकॉर्ड जोड़ें', 'أضف أول سجل لك');
  String get live => _t('LIVE', 'لائیو', 'लाइव', 'مباشر');
  String get ended => _t('ENDED', 'ختم', 'समाप्त', 'انتهى');
  String get privateLabel => _t('PRIVATE', 'نجی', 'निजी', 'خاص');

  // ── Posts ──
  String get noPostsYet => _t('No posts yet', 'ابھی کوئی پوسٹ نہیں', 'अभी कोई पोस्ट नहीं', 'لا منشورات بعد');
  String get newPost => _t('New post', 'نئی پوسٹ', 'नई पोस्ट', 'منشور جديد');
  String get createFirstPost => _t('Create your first post', 'اپنی پہلی پوسٹ بنائیں', 'अपनी पहली पोस्ट बनाएँ', 'أنشئ أول منشور لك');

  // ── Notifications ──
  String get notificationsTitle => _t('Notifications', 'اطلاعات', 'सूचनाएँ', 'الإشعارات');
  String get markAll => _t('Mark all', 'سب پڑھا ہوا', 'सभी पढ़ा हुआ', 'تحديد الكل');
  String get noNotifications => _t('No notifications yet', 'ابھی کوئی اطلاع نہیں', 'अभी कोई सूचना नहीं', 'لا إشعارات بعد');

  // ── Find friends ──
  String get findFriends => _t('Find friends', 'دوست تلاش کریں', 'दोस्त खोजें', 'ابحث عن أصدقاء');
  String get searchPeople => _t('Search people', 'لوگ تلاش کریں', 'लोग खोजें', 'ابحث عن أشخاص');
  String get suggestedForYou => _t('Suggested for you', 'آپ کے لیے تجاویز', 'आपके लिए सुझाव', 'مقترحة لك');
  String get noPeopleFound => _t('No people found', 'کوئی شخص نہیں ملا', 'कोई व्यक्ति नहीं मिला', 'لم يُعثر على أشخاص');
  String get searchNameHint => _t('Search name or @username…', 'نام یا @یوزرنیم تلاش کریں…', 'नाम या @यूज़रनेम खोजें…', 'ابحث بالاسم أو @المعرّف…');
}
