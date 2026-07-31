// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AgroPlus';

  @override
  String get loginHeadline => 'Log in to your account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get logInButton => 'Log in';

  @override
  String get noAccountRegisterPrompt => 'Don\'t have an account? Register';

  @override
  String get createAccountTitle => 'Create account';

  @override
  String get nameLabel => 'Name';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get phoneRequired => 'Phone is required';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get registerButton => 'Register';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get logoutTooltip => 'Log out';

  @override
  String get addFarm => 'Add farm';

  @override
  String get emptyFarmsMessage => 'You haven\'t added a farm yet';

  @override
  String get profileLoadError => 'Could not load your profile.';

  @override
  String get farmsLoadError => 'Could not load your farms.';

  @override
  String get deleteFarmTitle => 'Delete farm?';

  @override
  String deleteFarmContent(String farmName) {
    return 'This will permanently remove \"$farmName\" and its data.';
  }

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get deleteFarmTooltip => 'Delete farm';

  @override
  String get noChecksYet => 'No checks yet';

  @override
  String get justNow => 'Just now';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '$count day ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '$count hour ago',
    );
    return '$_temp0';
  }

  @override
  String get closeTooltip => 'Close';

  @override
  String get farmNameLabel => 'Farm name';

  @override
  String get locationLabel => 'Location';

  @override
  String get locationHint => 'Near Teesta canal, Kaunia';

  @override
  String get districtLabel => 'District';

  @override
  String get areaLabel => 'Area (acres)';

  @override
  String get areaHint => '4.0';

  @override
  String get soilTypeLabel => 'Soil type';

  @override
  String get waterAvailabilityLabel => 'Water availability';

  @override
  String get budgetLabel => 'Budget (BDT)';

  @override
  String get budgetHint => '50000';

  @override
  String get targetSeasonLabel => 'Target season';

  @override
  String get requiredValidation => 'Required';

  @override
  String get positiveNumberValidation => 'Must be a positive number';

  @override
  String get languageToggleTooltip => 'Switch language';
}
