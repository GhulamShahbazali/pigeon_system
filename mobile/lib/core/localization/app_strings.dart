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
}
