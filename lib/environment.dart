// ignore_for_file: constant_identifier_names

class Environment {
  static const appName = "Pay1c";
  static const appVersion = "2.0.0";

  static String defaultLangCode = "en";
  static String defaultLanguageName = "English";

  static String defaultPhoneDialCode = "234"; //don't put + here
  static String defaultCountryCode = "NG";
  static int maxMobileNumberDigit = 10; // Specify the required mobile number digits without country code
  static int maxPinNumberDigit = 6; // Specify the required max pin number digits
  static int maxAllowPrecision = 10; // Specify the required allow precision for amount of digits

  static const int otpResendDuration = 120;
  //Is Color from Internet
  static const bool IS_COLOR_FROM_INTERNET = false;

  //Onboard
  static const bool ENABLE_ONBOARD = true;
  //DEV MODE ==> false if production
  static const bool DEV_MODE = false;

  // API END POINT URL
  static const MAIN_API_URL = DEV_MODE ? TEST_API_URL : LIVE_API_URL; // Don't touch here

  static const LIVE_API_URL = 'https://pay.edubest.com.ng'; //Live end Point URL

  static const TEST_API_URL = 'https://pay.edubest.com.ng'; //Local or demo or test URL

  // API END POINT URL END
}
