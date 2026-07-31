import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

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
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AgroPlus'**
  String get appTitle;

  /// No description provided for @loginHeadline.
  ///
  /// In en, this message translates to:
  /// **'Log in to your account'**
  String get loginHeadline;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @logInButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logInButton;

  /// No description provided for @noAccountRegisterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccountRegisterPrompt;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get phoneRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @logoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutTooltip;

  /// No description provided for @addFarm.
  ///
  /// In en, this message translates to:
  /// **'Add farm'**
  String get addFarm;

  /// No description provided for @emptyFarmsMessage.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added a farm yet'**
  String get emptyFarmsMessage;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile.'**
  String get profileLoadError;

  /// No description provided for @farmsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your farms.'**
  String get farmsLoadError;

  /// No description provided for @deleteFarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete farm?'**
  String get deleteFarmTitle;

  /// No description provided for @deleteFarmContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove \"{farmName}\" and its data.'**
  String deleteFarmContent(String farmName);

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @deleteFarmTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete farm'**
  String get deleteFarmTooltip;

  /// No description provided for @noChecksYet.
  ///
  /// In en, this message translates to:
  /// **'No checks yet'**
  String get noChecksYet;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @closeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeTooltip;

  /// No description provided for @farmNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm name'**
  String get farmNameLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'Near Teesta canal, Kaunia'**
  String get locationHint;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @areaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area (acres)'**
  String get areaLabel;

  /// No description provided for @areaHint.
  ///
  /// In en, this message translates to:
  /// **'4.0'**
  String get areaHint;

  /// No description provided for @soilTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Soil type'**
  String get soilTypeLabel;

  /// No description provided for @waterAvailabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Water availability'**
  String get waterAvailabilityLabel;

  /// No description provided for @budgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget (BDT)'**
  String get budgetLabel;

  /// No description provided for @budgetHint.
  ///
  /// In en, this message translates to:
  /// **'50000'**
  String get budgetHint;

  /// No description provided for @targetSeasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Target season'**
  String get targetSeasonLabel;

  /// No description provided for @requiredValidation.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredValidation;

  /// No description provided for @positiveNumberValidation.
  ///
  /// In en, this message translates to:
  /// **'Must be a positive number'**
  String get positiveNumberValidation;

  /// No description provided for @languageToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch language'**
  String get languageToggleTooltip;

  /// No description provided for @farmProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm profile'**
  String get farmProfileTitle;

  /// No description provided for @liveConditionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Live conditions'**
  String get liveConditionsTitle;

  /// No description provided for @recommendationTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendation'**
  String get recommendationTitle;

  /// No description provided for @temperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureLabel;

  /// No description provided for @humidityLabel.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidityLabel;

  /// No description provided for @rainfallLabel.
  ///
  /// In en, this message translates to:
  /// **'Rainfall'**
  String get rainfallLabel;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @lastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {time}'**
  String lastUpdatedLabel(String time);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} min ago} other{{count} min ago}}'**
  String minutesAgo(int count);

  /// No description provided for @conditionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load live conditions.'**
  String get conditionsLoadError;

  /// No description provided for @farmDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load farm details.'**
  String get farmDetailLoadError;

  /// No description provided for @recommendationLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your recommendation.'**
  String get recommendationLoadError;

  /// No description provided for @savePointError.
  ///
  /// In en, this message translates to:
  /// **'Could not save this point. Please try again.'**
  String get savePointError;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon'**
  String get comingSoonMessage;

  /// No description provided for @soilReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Soil reading'**
  String get soilReadingTitle;

  /// No description provided for @addPointTitle.
  ///
  /// In en, this message translates to:
  /// **'Add point'**
  String get addPointTitle;

  /// No description provided for @editPointTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit point'**
  String get editPointTitle;

  /// No description provided for @nitrogenLabel.
  ///
  /// In en, this message translates to:
  /// **'Nitrogen (N)'**
  String get nitrogenLabel;

  /// No description provided for @phosphorusLabel.
  ///
  /// In en, this message translates to:
  /// **'Phosphorus (P)'**
  String get phosphorusLabel;

  /// No description provided for @potassiumLabel.
  ///
  /// In en, this message translates to:
  /// **'Potassium (K)'**
  String get potassiumLabel;

  /// No description provided for @phLabel.
  ///
  /// In en, this message translates to:
  /// **'pH'**
  String get phLabel;

  /// No description provided for @savePointButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get savePointButton;

  /// No description provided for @compositePendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the remaining points to see your composite reading'**
  String get compositePendingMessage;

  /// No description provided for @centerPointLabel.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get centerPointLabel;

  /// No description provided for @cornerPointLabel.
  ///
  /// In en, this message translates to:
  /// **'Corner {number}'**
  String cornerPointLabel(int number);

  /// No description provided for @quadrantPointLabel.
  ///
  /// In en, this message translates to:
  /// **'Quadrant {number}'**
  String quadrantPointLabel(int number);

  /// No description provided for @recommendationDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Add a soil reading below to unlock your recommendation'**
  String get recommendationDisabledHint;

  /// No description provided for @recommendationPipelinePendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not generate a recommendation yet — try re-saving a point'**
  String get recommendationPipelinePendingMessage;

  /// No description provided for @bestCropsButton.
  ///
  /// In en, this message translates to:
  /// **'Best crops for my farm'**
  String get bestCropsButton;

  /// No description provided for @confidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidenceLabel;

  /// No description provided for @yieldEstimateLabel.
  ///
  /// In en, this message translates to:
  /// **'Yield estimate'**
  String get yieldEstimateLabel;

  /// No description provided for @netProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get netProfitLabel;

  /// No description provided for @profitComingSoonNote.
  ///
  /// In en, this message translates to:
  /// **'Profit estimate coming soon'**
  String get profitComingSoonNote;

  /// No description provided for @chatWithAgentButton.
  ///
  /// In en, this message translates to:
  /// **'Chat with agent'**
  String get chatWithAgentButton;

  /// No description provided for @farmPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat about which farm?'**
  String get farmPickerTitle;

  /// No description provided for @farmPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The assistant will use this farm\'s soil and weather data.'**
  String get farmPickerSubtitle;

  /// No description provided for @farmAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm assistant'**
  String get farmAssistantTitle;

  /// No description provided for @chatGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m your farm assistant for {farmName}. Ask me anything about your soil, weather, or what to plant this season.'**
  String chatGreeting(String farmName);

  /// No description provided for @quickChipProfit.
  ///
  /// In en, this message translates to:
  /// **'Show profit breakdown'**
  String get quickChipProfit;

  /// No description provided for @quickChipSoil.
  ///
  /// In en, this message translates to:
  /// **'Check soil condition'**
  String get quickChipSoil;

  /// No description provided for @quickChipCrop.
  ///
  /// In en, this message translates to:
  /// **'Suggest another crop'**
  String get quickChipCrop;

  /// No description provided for @messageInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get messageInputHint;

  /// No description provided for @sendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendTooltip;

  /// No description provided for @placeholderAgentReply.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your message! Real farm assistant responses are coming soon — for now this is a placeholder reply.'**
  String get placeholderAgentReply;
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
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
