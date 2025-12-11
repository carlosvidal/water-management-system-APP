# Configuración de Entornos

Este proyecto soporta múltiples entornos de desarrollo. La configuración se encuentra en `lib/core/config/environment.dart`.

## Entornos Disponibles

### 🔧 Development (Por defecto)
- **URL API:**
  - Android Emulator: `http://10.0.2.2:3000/api`
  - iOS Simulator: `http://localhost:3000/api`
- **Uso:** Desarrollo local con backend en localhost

### 🚧 Staging
- **URL API:** `https://staging-api.consumos.online`
- **Uso:** Pruebas previas a producción

### 🚀 Production
- **URL API:** `https://api.consumos.online`
- **Uso:** Aplicación en producción

## Cómo Ejecutar en Diferentes Entornos

### Desde VSCode (Recomendado)
1. Abre el panel de "Run and Debug" (Ctrl/Cmd + Shift + D)
2. Selecciona una de las configuraciones disponibles:
   - `Development` - Entorno de desarrollo
   - `Development (Android Emulator)` - Desarrollo en emulador Android específico
   - `Staging` - Entorno de staging
   - `Production` - Entorno de producción
3. Presiona F5 o haz clic en "Start Debugging"

### Desde la Terminal

#### Development (por defecto)
```bash
flutter run
```

o explícitamente:
```bash
flutter run --dart-define=ENVIRONMENT=development
```

#### Staging
```bash
flutter run --dart-define=ENVIRONMENT=staging
```

#### Production
```bash
flutter run --dart-define=ENVIRONMENT=production
```

## Compilar para Producción

### Android (APK)
```bash
flutter build apk --dart-define=ENVIRONMENT=production --release
```

### Android (App Bundle para Play Store)
```bash
flutter build appbundle --dart-define=ENVIRONMENT=production --release
```

### iOS
```bash
flutter build ios --dart-define=ENVIRONMENT=production --release
```

## Verificar el Entorno Actual

Puedes verificar el entorno actual usando:

```dart
import 'package:water_readings_app/core/config/environment.dart';

print('Entorno actual: ${Environment.name}');
print('API URL: ${Environment.apiBaseUrl}');
print('¿Es producción?: ${Environment.isProduction}');
```

## Cambiar URLs de Entorno

Para modificar las URLs de cada entorno, edita el archivo:
`lib/core/config/environment.dart`

```dart
static String get apiBaseUrl {
  switch (current) {
    case EnvironmentType.production:
      return 'https://api.consumos.online';
    case EnvironmentType.staging:
      return 'https://staging-api.consumos.online';
    case EnvironmentType.development:
      // Tus URLs de desarrollo local
  }
}
```

## Notas Importantes

- **Android Emulator:** Usa `10.0.2.2` en lugar de `localhost` para conectar con tu máquina host
- **iOS Simulator:** Puede usar directamente `localhost`
- **Dispositivos Físicos:** Necesitarás usar la IP local de tu máquina (ej: `192.168.1.100:3000`)
- El entorno por defecto si no se especifica es **Development**
