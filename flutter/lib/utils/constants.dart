class AppConstants {
  // Replace with your deployed backend URL
  static const String apiBaseUrl = 'https://carguardian-api.onrender.com';

  // API endpoints
  static const String analyzeEndpoint   = '/api/damage/analyze';
  static const String assistantEndpoint = '/api/assistant/query';
  static const String fleetSummary      = '/api/fleet/summary';
  static const String serviceEndpoint   = '/api/fleet';

  // Notification IDs
  static const int insuranceNotifId = 1;
  static const int serviceNotifId   = 2;
  static const int oilChangeNotifId = 3;

  // Health score thresholds
  static const int healthGood    = 80;
  static const int healthFair    = 50;
  static const int healthPoor    = 0;

  // Fuel types
  static const List<String> fuelTypes = [
    'Petrol', 'Diesel', 'CNG', 'LPG', 'Electric', 'Hybrid'
  ];
}
