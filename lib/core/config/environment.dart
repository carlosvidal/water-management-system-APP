import 'package:flutter/foundation.dart';

/// Environment configuration for different build modes
class Environment {
  /// Get the current environment based on build mode
  static EnvironmentType get current {
    // You can override this with --dart-define=ENVIRONMENT=production
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

    switch (environment.toLowerCase()) {
      case 'production':
      case 'prod':
        return EnvironmentType.production;
      case 'staging':
      case 'stg':
        return EnvironmentType.staging;
      case 'development':
      case 'dev':
      default:
        return EnvironmentType.development;
    }
  }

  /// Get API base URL based on current environment
  static String get apiBaseUrl {
    switch (current) {
      case EnvironmentType.production:
        return 'https://api.consumos.online/api';
      case EnvironmentType.staging:
        return 'https://staging-api.consumos.online/api'; // Ajusta si tienes staging
      case EnvironmentType.development:
        // For Android Emulator use 10.0.2.2, for iOS Simulator use localhost
        if (defaultTargetPlatform == TargetPlatform.android) {
          return 'http://10.0.2.2:3000/api';
        } else {
          return 'http://localhost:3000/api';
        }
    }
  }

  /// Check if we're in production
  static bool get isProduction => current == EnvironmentType.production;

  /// Check if we're in development
  static bool get isDevelopment => current == EnvironmentType.development;

  /// Check if we're in staging
  static bool get isStaging => current == EnvironmentType.staging;

  /// Environment name for display
  static String get name {
    switch (current) {
      case EnvironmentType.production:
        return 'Production';
      case EnvironmentType.staging:
        return 'Staging';
      case EnvironmentType.development:
        return 'Development';
    }
  }
}

enum EnvironmentType {
  development,
  staging,
  production,
}
