class AppConstants {
  static const int creditsEasy = 5;
  static const int creditsMedium = 10;
  static const int creditsHard = 20;
  static const int harmonySteadyMin = 50;
  static const int harmonyThrivingMin = 80;
  static const int recurringChoreInstances = 4;

  // New configuration properties required for the harmony scorecard engine
  static const double harmonyChoreWeight = 0.5;
  static const double harmonyPaymentWeight = 0.5;
  static const int harmonyChoreWindowDays = 14;
  static const int harmonyDebtWindowDays = 30;
  static const int harmonySettleWindowDays = 7;
  static const int nudgeCooldownHours = 24;

  // Google Sign-In Web Client ID (serverClientId required by Android Credential Manager)
  static const String googleServerClientId =
      '740240029076-jj2ng4ahetgu1a02dns51ocn0lpj57h1.apps.googleusercontent.com';
}
