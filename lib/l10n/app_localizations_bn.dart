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
}
