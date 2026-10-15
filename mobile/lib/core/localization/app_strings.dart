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

  /// Non-reactive read — for one-shot contexts (bottom sheets, dialogs, tap
  /// callbacks) where `watch` can't be used.
  static AppStrings read(BuildContext context) =>
      AppStrings(context.read<LocaleCubit>().state);

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

  // ── Tournament card + My Tournaments ──
  String get byAuthor => _t('by', 'بذریعہ', 'द्वारा', 'بواسطة');
  String get pigeonsUnit => _t('pigeons', 'کبوتر', 'कबूतर', 'حمام');
  String get followedTab => _t('Followed', 'فالو شدہ', 'फ़ॉलो किए', 'المتابَعة');
  String get failedLoadTournaments => _t('Failed to load tournaments', 'ٹورنامنٹ لوڈ نہیں ہو سکے', 'टूर्नामेंट लोड नहीं हो सके', 'تعذّر تحميل البطولات');
  String get retry => _t('Retry', 'دوبارہ', 'पुनः प्रयास', 'إعادة');
  String get noTournamentsCreated => _t('No tournaments created yet', 'ابھی کوئی ٹورنامنٹ نہیں بنایا', 'अभी कोई टूर्नामेंट नहीं बनाया', 'لم تُنشئ أي بطولة بعد');
  String get noFollowedTournaments => _t('No followed tournaments yet', 'ابھی کوئی فالو شدہ ٹورنامنٹ نہیں', 'अभी कोई फ़ॉलो किया टूर्नामेंट नहीं', 'لا بطولات متابَعة بعد');
  String get tournamentsCreatedHint => _t('Tournaments you create will show up here.', 'آپ کے بنائے ٹورنامنٹ یہاں نظر آئیں گے۔', 'आपके बनाए टूर्नामेंट यहाँ दिखेंगे।', 'ستظهر هنا البطولات التي تنشئها.');
  String get followedTournamentsHint => _t('Tournaments you follow and tournaments created by flyers you follow will show up here.', 'جو ٹورنامنٹ آپ فالو کرتے ہیں اور جن فلائرز کو فالو کرتے ہیں ان کے بنائے ٹورنامنٹ یہاں نظر آئیں گے۔', 'जिन टूर्नामेंट को आप फ़ॉलो करते हैं और जिन फ़्लायर्स को फ़ॉलो करते हैं उनके बनाए टूर्नामेंट यहाँ दिखेंगे।', 'ستظهر هنا البطولات التي تتابعها وبطولات من تتابعهم.');

  // ── Messages / inbox ──
  String get messagesTitle => _t('Messages', 'پیغامات', 'संदेश', 'الرسائل');
  String get messageRequests => _t('Message requests', 'پیغام کی درخواستیں', 'संदेश अनुरोध', 'طلبات المراسلة');
  String get peopleWhoWantToChat => _t('People who want to chat', 'جو لوگ بات کرنا چاہتے ہیں', 'जो लोग चैट करना चाहते हैं', 'أشخاص يريدون المحادثة');
  String get noConversations => _t('No conversations yet', 'ابھی کوئی گفتگو نہیں', 'अभी कोई बातचीत नहीं', 'لا محادثات بعد');
  String get startChatHint => _t("Start a chat from someone's profile.", 'کسی کی پروفائل سے گفتگو شروع کریں۔', 'किसी की प्रोफ़ाइल से चैट शुरू करें।', 'ابدأ محادثة من ملف أحدهم.');
  String get tapToOpenChat => _t('Tap to open chat', 'چیٹ کھولنے کے لیے دبائیں', 'चैट खोलने के लिए टैप करें', 'اضغط لفتح المحادثة');

  // ── Edit profile ──
  String get nameLabel => _t('Name', 'نام', 'नाम', 'الاسم');
  String get usernameLabel => _t('Username', 'یوزرنیم', 'यूज़रनेम', 'اسم المستخدم');
  String get bioLabel => _t('Bio', 'تعارف', 'परिचय', 'نبذة');
  String get cityLabel => _t('City', 'شہر', 'शहर', 'المدينة');
  String get bioHint => _t('Tell people about your loft…', 'لوگوں کو اپنے لوفٹ کے بارے میں بتائیں…', 'लोगों को अपने लॉफ़्ट के बारे में बताएँ…', 'أخبر الناس عن برجك…');
  String get profileUpdated => _t('Profile updated successfully!', 'پروفائل کامیابی سے اپڈیٹ ہو گئی!', 'प्रोफ़ाइल सफलतापूर्वक अपडेट हुई!', 'تم تحديث الملف بنجاح!');

  // ── Notifications & Privacy settings ──
  String get notifPrivacyTitle => _t('Notifications & Privacy', 'اطلاعات اور رازداری', 'सूचनाएँ और गोपनीयता', 'الإشعارات والخصوصية');
  String get pushNotifications => _t('Push notifications', 'پش اطلاعات', 'पुश सूचनाएँ', 'إشعارات الدفع');
  String get allowPush => _t('Allow push', 'پش کی اجازت', 'पुश की अनुमति', 'السماح بالإشعارات');
  String get masterSwitch => _t('Master switch', 'مرکزی سوئچ', 'मुख्य स्विच', 'المفتاح الرئيسي');
  String get newFollowerToggle => _t('New follower', 'نیا فالوور', 'नया फ़ॉलोअर', 'متابِع جديد');
  String get likesOnContent => _t('Likes on my content', 'میرے مواد پر پسند', 'मेरी सामग्री पर लाइक', 'الإعجابات على محتواي');
  String get tournamentUpdates => _t('Tournament I follow updates', 'جو ٹورنامنٹ فالو کرتا ہوں اس کی اپڈیٹس', 'जिन टूर्नामेंट को फ़ॉलो करता हूँ उनके अपडेट', 'تحديثات البطولات التي أتابعها');
  String get liveRecordFollow => _t('Live record from people I follow', 'جن کو فالو کرتا ہوں ان کے لائیو ریکارڈ', 'जिन्हें फ़ॉलो करता हूँ उनके लाइव रिकॉर्ड', 'السجلات المباشرة لمن أتابعهم');
  String get privateAccount => _t('Private account', 'نجی اکاؤنٹ', 'निजी खाता', 'حساب خاص');
  String get privateAccountSubtitle => _t('Only approved followers can see your profile and records', 'صرف منظور شدہ فالوورز آپ کی پروفائل اور ریکارڈ دیکھ سکتے ہیں', 'केवल स्वीकृत फ़ॉलोअर आपकी प्रोफ़ाइल और रिकॉर्ड देख सकते हैं', 'يمكن للمتابعين المعتمدين فقط رؤية ملفك وسجلاتك');

  // ── Create post ──
  String get publish => _t('Publish', 'شائع کریں', 'प्रकाशित करें', 'نشر');
  String get publishPost => _t('Publish post', 'پوسٹ شائع کریں', 'पोस्ट प्रकाशित करें', 'نشر المنشور');
  String get publishing => _t('Publishing…', 'شائع ہو رہا ہے…', 'प्रकाशित हो रहा है…', 'جارٍ النشر…');
  String get publicLabel => _t('Public', 'عوامی', 'सार्वजनिक', 'عام');
  String get addPhoto => _t('Add photo', 'تصویر شامل کریں', 'फ़ोटो जोड़ें', 'إضافة صورة');
  String get writeSomethingToPost => _t('Write something to post', 'پوسٹ کرنے کے لیے کچھ لکھیں', 'पोस्ट करने के लिए कुछ लिखें', 'اكتب شيئًا للنشر');

  // ── Create New sheet ──
  String get createNew => _t('Create New', 'نیا بنائیں', 'नया बनाएँ', 'إنشاء جديد');
  String get tournamentSubtitle => _t('Single or multi-day competition', 'ایک یا کئی دن کا مقابلہ', 'एक या कई-दिन की प्रतियोगिता', 'منافسة ليوم أو عدة أيام');
  String get dailyFlightRecord => _t('Daily Flight Record', 'روزانہ فلائٹ ریکارڈ', 'दैनिक उड़ान रिकॉर्ड', 'سجل الطيران اليومي');
  String get recordSubtitle => _t('Track your loft routine live or private', 'اپنے لوفٹ کا معمول لائیو یا نجی ٹریک کریں', 'अपने लॉफ़्ट की दिनचर्या लाइव या निजी ट्रैक करें', 'تتبّع روتين برجك مباشرةً أو بشكل خاص');
  String get newPostTitle => _t('New Post', 'نئی پوسٹ', 'नई पोस्ट', 'منشور جديد');
  String get postSubtitle => _t('Share flight photos and updates', 'فلائٹ کی تصاویر اور اپڈیٹس شیئر کریں', 'उड़ान की तस्वीरें और अपडेट साझा करें', 'شارك صور الطيران والتحديثات');

  // ── Tournaments tab ──
  String get tabAll => _t('All', 'سب', 'सभी', 'الكل');
  String get tabUpcoming => _t('Upcoming', 'آنے والے', 'आगामी', 'القادمة');
  String get tabOngoing => _t('Ongoing', 'جاری', 'चालू', 'الجارية');
  String get tabPast => _t('Past', 'ماضی', 'पिछले', 'السابقة');
  String get newTournament => _t('New Tournament', 'نیا ٹورنامنٹ', 'नया टूर्नामेंट', 'بطولة جديدة');
  String get organizer => _t('Organizer', 'منتظم', 'आयोजक', 'المنظّم');
  String get noUpcomingTournaments => _t('No upcoming tournaments.', 'کوئی آنے والا ٹورنامنٹ نہیں۔', 'कोई आगामी टूर्नामेंट नहीं।', 'لا بطولات قادمة.');
  String get noOngoingTournaments => _t('No tournaments running right now.', 'ابھی کوئی ٹورنامنٹ جاری نہیں۔', 'अभी कोई टूर्नामेंट चालू नहीं।', 'لا بطولات جارية الآن.');
  String get noPastTournaments => _t('No past tournaments yet.', 'ابھی کوئی ماضی کا ٹورنامنٹ نہیں۔', 'अभी कोई पिछला टूर्नामेंट नहीं।', 'لا بطولات سابقة بعد.');
  String get noTournaments => _t('No tournaments found.', 'کوئی ٹورنامنٹ نہیں ملا۔', 'कोई टूर्नामेंट नहीं मिला।', 'لم يُعثر على بطولات.');
  String get tournamentsHint => _t('Tournaments organized by users will show up here.', 'صارفین کے منظم کردہ ٹورنامنٹ یہاں نظر آئیں گے۔', 'उपयोगकर्ताओं द्वारा आयोजित टूर्नामेंट यहाँ दिखेंगे।', 'ستظهر هنا البطولات التي ينظّمها المستخدمون.');

  // ── Records tab ──
  String get recordsTitle => _t('Records', 'ریکارڈ', 'रिकॉर्ड', 'السجلات');
  String get myRecordsTab => _t('My records', 'میرے ریکارڈ', 'मेरे रिकॉर्ड', 'سجلاتي');
  String get noFlightRecords => _t('No flight records logged yet', 'ابھی کوئی فلائٹ ریکارڈ درج نہیں', 'अभी कोई उड़ान रिकॉर्ड दर्ज नहीं', 'لا سجلات طيران بعد');
  String get logLoftHint => _t('Log your loft routine using the + button above.', 'اوپر + بٹن سے اپنے لوفٹ کا معمول درج کریں۔', 'ऊपर + बटन से अपने लॉफ़्ट का रिकॉर्ड जोड़ें।', 'سجّل روتين برجك باستخدام زر + بالأعلى.');
  String get youreLive => _t("You're live now", 'آپ ابھی لائیو ہیں', 'आप अभी लाइव हैं', 'أنت مباشر الآن');
  String get noFlyersLive => _t('No flyers live right now', 'ابھی کوئی فلائر لائیو نہیں', 'अभी कोई फ़्लायर लाइव नहीं', 'لا مربّين مباشرين الآن');
  String get noFlyersLiveHint => _t('When accounts you follow go live with flights, they appear here.', 'جن اکاؤنٹس کو آپ فالو کرتے ہیں وہ لائیو ہوں تو یہاں نظر آئیں گے۔', 'जिन खातों को आप फ़ॉलो करते हैं वे लाइव होने पर यहाँ दिखेंगे।', 'عندما يبث من تتابعهم مباشرةً يظهرون هنا.');
  String get liveNowBadge => _t('LIVE NOW', 'ابھی لائیو', 'अभी लाइव', 'مباشر الآن');
  String get pigeons => _t('Pigeons', 'کبوتر', 'कबूतर', 'الحمام');
  String get flyTimeLabel => _t('Fly Time', 'اڑان کا وقت', 'उड़ान समय', 'وقت الطيران');
  String get average => _t('Average', 'اوسط', 'औसत', 'المعدّل');
  String get tryAgain => _t('Try Again', 'دوبارہ کوشش کریں', 'पुनः प्रयास करें', 'حاول مرة أخرى');
  String landedOf(int a, int b) => _t('$a of $b landed', '$b میں سے $a واپس', '$b में से $a लौटे', '$a من $b عادت');

  // ── Find friends ──
  String get findFriends => _t('Find friends', 'دوست تلاش کریں', 'दोस्त खोजें', 'ابحث عن أصدقاء');
  String get searchPeople => _t('Search people', 'لوگ تلاش کریں', 'लोग खोजें', 'ابحث عن أشخاص');
  String get suggestedForYou => _t('Suggested for you', 'آپ کے لیے تجاویز', 'आपके लिए सुझाव', 'مقترحة لك');
  String get noPeopleFound => _t('No people found', 'کوئی شخص نہیں ملا', 'कोई व्यक्ति नहीं मिला', 'لم يُعثر على أشخاص');
  String get searchNameHint => _t('Search name or @username…', 'نام یا @یوزرنیم تلاش کریں…', 'नाम या @यूज़रनेम खोजें…', 'ابحث بالاسم أو @المعرّف…');
}
