class AppConstants {
  // UPI Configuration
  // Note: Personal VPAs often have strict transaction limits and may be blocked by some apps for intent-based payments.
  // Recommended: Use a Merchant VPA (e.g., Business Account) for higher success rates.
  static const String canteenVpa = '9860630677@okbizaxis';
  // Tip: If facing "Bank Limit" errors during testing, try paying small amounts (e.g., ₹1 or ₹10) as personal VPAs have strict limits.
  static const String canteenPayeeName = 'PRASANNA CATERERS';

  // Emergency Contacts
  static const String headWardenPhone = '+919823123845'; // Placeholder
  static const String messContractorPhone =
      '+919860630677'; // Inferred from VPA
}
