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
  String get addFarm => 'Add land';

  @override
  String get emptyFarmsMessage => 'You haven\'t added a land yet';

  @override
  String get profileLoadError => 'Could not load your profile.';

  @override
  String get farmsLoadError => 'Could not load your lands.';

  @override
  String get deleteFarmTitle => 'Delete land?';

  @override
  String deleteFarmContent(String farmName) {
    return 'This will permanently remove \"$farmName\" and its data.';
  }

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get deleteFarmTooltip => 'Delete land';

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
  String get farmNameLabel => 'Land name';

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

  @override
  String get farmProfileTitle => 'Land profile';

  @override
  String get liveConditionsTitle => 'Live conditions';

  @override
  String get recommendationTitle => 'Recommendation';

  @override
  String get temperatureLabel => 'Temperature';

  @override
  String get humidityLabel => 'Humidity';

  @override
  String get rainfallLabel => 'Rainfall';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String lastUpdatedLabel(String time) {
    return 'Last updated: $time';
  }

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '$count min ago',
    );
    return '$_temp0';
  }

  @override
  String get conditionsLoadError => 'Could not load live conditions.';

  @override
  String get forecastTitle => '7-day forecast';

  @override
  String get forecastLoadError => 'Could not load the forecast.';

  @override
  String get farmDetailLoadError => 'Could not load land details.';

  @override
  String get recommendationLoadError => 'Could not load your recommendation.';

  @override
  String get savePointError => 'Could not save this point. Please try again.';

  @override
  String get comingSoonMessage => 'This feature is coming soon';

  @override
  String get soilReadingTitle => 'Soil reading';

  @override
  String get addPointTitle => 'Add point';

  @override
  String get editPointTitle => 'Edit point';

  @override
  String get nitrogenLabel => 'Nitrogen (N)';

  @override
  String get phosphorusLabel => 'Phosphorus (P)';

  @override
  String get potassiumLabel => 'Potassium (K)';

  @override
  String get phLabel => 'pH';

  @override
  String get savePointButton => 'Save';

  @override
  String get compositePendingMessage =>
      'Add the remaining points to see your composite reading';

  @override
  String get centerPointLabel => 'Center';

  @override
  String cornerPointLabel(int number) {
    return 'Corner $number';
  }

  @override
  String quadrantPointLabel(int number) {
    return 'Quadrant $number';
  }

  @override
  String get recommendationDisabledHint =>
      'Add a soil reading below to unlock your recommendation';

  @override
  String get recommendationPipelinePendingMessage =>
      'Could not generate a recommendation yet — try re-saving a point';

  @override
  String get bestCropsButton => 'Best crops for my land';

  @override
  String get confidenceLabel => 'Confidence';

  @override
  String get yieldEstimateLabel => 'Yield estimate';

  @override
  String get netProfitLabel => 'Net profit';

  @override
  String get profitComingSoonNote => 'Profit estimate coming soon';

  @override
  String get recommendationListTitle => 'Recommended crops';

  @override
  String get selectCropHint =>
      'Select a crop to see seed cost, growing season, and profit estimate';

  @override
  String get growingSeasonLabel => 'Growing season';

  @override
  String get whyThisCropButton => 'Why this crop?';

  @override
  String whyThisCropQuestion(String crop) {
    return 'Why do you recommend $crop for my land?';
  }

  @override
  String get yieldAndCostTitle => 'Yield & price';

  @override
  String get marketPriceLabel => 'Market price';

  @override
  String get costBreakdownTitle => 'Cost breakdown';

  @override
  String get seedCostLabel => 'Seed cost';

  @override
  String get seedCostUnavailableNote =>
      'Seed cost not available for this crop yet';

  @override
  String get fertilizerCostLabel => 'Fertilizer cost';

  @override
  String get fertilizerCostUnavailableNote =>
      'Fertilizer cost not available for this crop yet';

  @override
  String get otherCostLabel => 'Other costs (labor, irrigation, land prep)';

  @override
  String get totalCostLabel => 'Estimated total cost';

  @override
  String get overBudgetLabel => 'Over budget';

  @override
  String overBudgetWarning(String budget, String difference) {
    return 'This exceeds your budget of $budget BDT by $difference BDT.';
  }

  @override
  String get profitEstimateTitle => 'Profit estimate';

  @override
  String get grossRevenueLabel => 'Gross revenue';

  @override
  String get cropDetailLoadError =>
      'Could not load harvest details for this crop';

  @override
  String get chatWithAgentButton => 'Chat with agent';

  @override
  String get farmPickerTitle => 'Chat about which land?';

  @override
  String get farmPickerSubtitle =>
      'The assistant will use this land\'s soil and weather data.';

  @override
  String get farmAssistantTitle => 'Land assistant';

  @override
  String chatGreeting(String farmName) {
    return 'Hi, I\'m your land assistant for $farmName. Ask me anything about your soil, weather, or what to plant this season.';
  }

  @override
  String get quickChipProfit => 'Show profit breakdown';

  @override
  String get quickChipSoil => 'Check soil condition';

  @override
  String get quickChipCrop => 'Suggest another crop';

  @override
  String get messageInputHint => 'Type a message';

  @override
  String get sendTooltip => 'Send';

  @override
  String get chatErrorReply =>
      'Sorry, I couldn\'t process that right now. Please try again.';

  @override
  String get newConversationTooltip => 'New conversation';

  @override
  String get newConversationTitle => 'Start new conversation?';

  @override
  String get newConversationContent =>
      'This will clear your current chat history for this land.';

  @override
  String get startButton => 'Start';

  @override
  String get newConversationError =>
      'Could not start a new conversation. Please try again.';

  @override
  String get viewHistoryButton => 'View history';

  @override
  String get recommendationHistoryTitle => 'Recommendation history';

  @override
  String get noHistoryMessage => 'No recommendations yet.';

  @override
  String get recommendationDetailTitle => 'Recommendation detail';

  @override
  String get compositeReadingLabel => 'Composite reading';

  @override
  String get editFarm => 'Edit land';

  @override
  String get editFarmTooltip => 'Edit land';

  @override
  String get updateFarmError => 'Could not update land. Please try again.';
}
