// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'AgroPlus';

  @override
  String get loginHeadline => 'আপনার অ্যাকাউন্টে লগ ইন করুন';

  @override
  String get emailLabel => 'ইমেইল';

  @override
  String get passwordLabel => 'পাসওয়ার্ড';

  @override
  String get emailRequired => 'ইমেইল আবশ্যক';

  @override
  String get passwordRequired => 'পাসওয়ার্ড আবশ্যক';

  @override
  String get logInButton => 'লগ ইন';

  @override
  String get noAccountRegisterPrompt => 'অ্যাকাউন্ট নেই? নিবন্ধন করুন';

  @override
  String get createAccountTitle => 'অ্যাকাউন্ট তৈরি করুন';

  @override
  String get nameLabel => 'নাম';

  @override
  String get phoneLabel => 'ফোন';

  @override
  String get nameRequired => 'নাম আবশ্যক';

  @override
  String get phoneRequired => 'ফোন নম্বর আবশ্যক';

  @override
  String get passwordTooShort => 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে';

  @override
  String get registerButton => 'নিবন্ধন করুন';

  @override
  String get dashboardTitle => 'ড্যাশবোর্ড';

  @override
  String get logoutTooltip => 'লগ আউট';

  @override
  String get addFarm => 'খামার যোগ করুন';

  @override
  String get emptyFarmsMessage => 'আপনি এখনো কোনো খামার যোগ করেননি';

  @override
  String get profileLoadError => 'আপনার প্রোফাইল লোড করা যায়নি।';

  @override
  String get farmsLoadError => 'আপনার খামারগুলো লোড করা যায়নি।';

  @override
  String get deleteFarmTitle => 'খামারটি মুছবেন?';

  @override
  String deleteFarmContent(String farmName) {
    return 'এটি স্থায়ীভাবে \"$farmName\" এবং এর তথ্য মুছে ফেলবে।';
  }

  @override
  String get cancelButton => 'বাতিল';

  @override
  String get deleteButton => 'মুছুন';

  @override
  String get deleteFarmTooltip => 'খামার মুছুন';

  @override
  String get noChecksYet => 'এখনো কোনো পরীক্ষা হয়নি';

  @override
  String get justNow => 'এইমাত্র';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count দিন আগে',
      one: '$count দিন আগে',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ঘণ্টা আগে',
      one: '$count ঘণ্টা আগে',
    );
    return '$_temp0';
  }

  @override
  String get closeTooltip => 'বন্ধ করুন';

  @override
  String get farmNameLabel => 'খামারের নাম';

  @override
  String get locationLabel => 'অবস্থান';

  @override
  String get locationHint => 'তিস্তা খালের কাছে, কাউনিয়া';

  @override
  String get districtLabel => 'জেলা';

  @override
  String get areaLabel => 'জমির পরিমাণ (একর)';

  @override
  String get areaHint => '4.0';

  @override
  String get soilTypeLabel => 'মাটির ধরন';

  @override
  String get waterAvailabilityLabel => 'সেচের সুবিধা';

  @override
  String get budgetLabel => 'বাজেট (টাকা)';

  @override
  String get budgetHint => '50000';

  @override
  String get targetSeasonLabel => 'লক্ষ্য মৌসুম';

  @override
  String get requiredValidation => 'আবশ্যক';

  @override
  String get positiveNumberValidation => 'অবশ্যই একটি ধনাত্মক সংখ্যা হতে হবে';

  @override
  String get languageToggleTooltip => 'ভাষা পরিবর্তন করুন';

  @override
  String get farmProfileTitle => 'খামারের বিবরণ';

  @override
  String get liveConditionsTitle => 'বর্তমান পরিবেশ';

  @override
  String get recommendationTitle => 'সুপারিশ';

  @override
  String get temperatureLabel => 'তাপমাত্রা';

  @override
  String get humidityLabel => 'আর্দ্রতা';

  @override
  String get rainfallLabel => 'বৃষ্টিপাত';

  @override
  String get refreshTooltip => 'রিফ্রেশ করুন';

  @override
  String lastUpdatedLabel(String time) {
    return 'সর্বশেষ হালনাগাদ: $time';
  }

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count মিনিট আগে',
      one: '$count মিনিট আগে',
    );
    return '$_temp0';
  }

  @override
  String get conditionsLoadError => 'বর্তমান পরিবেশের তথ্য লোড করা যায়নি।';

  @override
  String get farmDetailLoadError => 'খামারের বিবরণ লোড করা যায়নি।';

  @override
  String get recommendationLoadError => 'আপনার সুপারিশ লোড করা যায়নি।';

  @override
  String get savePointError =>
      'এই পয়েন্টটি সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get comingSoonMessage => 'এই ফিচারটি শীঘ্রই আসছে';

  @override
  String get soilReadingTitle => 'মাটির পরীক্ষা';

  @override
  String get addPointTitle => 'পয়েন্ট যোগ করুন';

  @override
  String get editPointTitle => 'পয়েন্ট সম্পাদনা করুন';

  @override
  String get nitrogenLabel => 'নাইট্রোজেন (N)';

  @override
  String get phosphorusLabel => 'ফসফরাস (P)';

  @override
  String get potassiumLabel => 'পটাশিয়াম (K)';

  @override
  String get phLabel => 'pH';

  @override
  String get savePointButton => 'সংরক্ষণ করুন';

  @override
  String get compositePendingMessage =>
      'সমন্বিত ফলাফল দেখতে বাকি পয়েন্টগুলো যোগ করুন';

  @override
  String get centerPointLabel => 'কেন্দ্র';

  @override
  String cornerPointLabel(int number) {
    return 'কোণ $number';
  }

  @override
  String quadrantPointLabel(int number) {
    return 'চতুর্ভাগ $number';
  }

  @override
  String get recommendationDisabledHint =>
      'সুপারিশ আনলক করতে নিচে একটি মাটির পরীক্ষা যোগ করুন';

  @override
  String get recommendationPipelinePendingMessage =>
      'সুপারিশ তৈরি করা যায়নি — একটি পয়েন্ট আবার সংরক্ষণ করার চেষ্টা করুন';

  @override
  String get bestCropsButton => 'আমার খামারের জন্য সেরা ফসল';

  @override
  String get confidenceLabel => 'নির্ভরযোগ্যতা';

  @override
  String get yieldEstimateLabel => 'ফলনের হিসাব';

  @override
  String get netProfitLabel => 'নিট মুনাফা';

  @override
  String get profitComingSoonNote => 'লাভের হিসাব শীঘ্রই আসছে';

  @override
  String get chatWithAgentButton => 'এজেন্টের সাথে চ্যাট করুন';

  @override
  String get farmPickerTitle => 'কোন খামার নিয়ে চ্যাট করবেন?';

  @override
  String get farmPickerSubtitle =>
      'সহায়ক এই খামারের মাটি ও আবহাওয়ার তথ্য ব্যবহার করবে।';

  @override
  String get farmAssistantTitle => 'খামার সহায়ক';

  @override
  String chatGreeting(String farmName) {
    return 'হাই, আমি $farmName-এর জন্য আপনার খামার সহায়ক। মাটি, আবহাওয়া বা এই মৌসুমে কী চাষ করবেন তা নিয়ে যেকোনো প্রশ্ন করতে পারেন।';
  }

  @override
  String get quickChipProfit => 'লাভের হিসাব দেখুন';

  @override
  String get quickChipSoil => 'মাটির অবস্থা পরীক্ষা করুন';

  @override
  String get quickChipCrop => 'অন্য ফসলের পরামর্শ নিন';

  @override
  String get messageInputHint => 'একটি বার্তা লিখুন';

  @override
  String get sendTooltip => 'পাঠান';

  @override
  String get placeholderAgentReply =>
      'আপনার বার্তার জন্য ধন্যবাদ! প্রকৃত খামার সহায়ক উত্তর শীঘ্রই আসছে — আপাতত এটি একটি নমুনা উত্তর।';

  @override
  String get viewHistoryButton => 'ইতিহাস দেখুন';

  @override
  String get recommendationHistoryTitle => 'সুপারিশের ইতিহাস';

  @override
  String get noHistoryMessage => 'এখনো কোনো সুপারিশ নেই।';

  @override
  String get recommendationDetailTitle => 'সুপারিশের বিবরণ';

  @override
  String get compositeReadingLabel => 'সমন্বিত ফলাফল';

  @override
  String get editFarm => 'খামার সম্পাদনা করুন';

  @override
  String get editFarmTooltip => 'খামার সম্পাদনা করুন';

  @override
  String get updateFarmError => 'খামার হালনাগাদ করা যায়নি। আবার চেষ্টা করুন।';
}
