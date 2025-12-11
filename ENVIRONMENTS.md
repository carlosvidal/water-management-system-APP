# 🌍 Configuración de Environments

La app Flutter tiene 3 ambientes configurados:

## Ambientes Disponibles

### 1. Development (Desarrollo Local)
- **API URL**: `http://localhost:3000/api` (iOS) o `http://10.0.2.2:3000/api` (Android)
- **Uso**: Desarrollo local con el API corriendo en tu máquina

### 2. Staging (Pre-producción)
- **API URL**: `https://staging-api.consumos.online/api`
- **Uso**: Testing antes de producción

### 3. Production (Producción)
- **API URL**: `https://api.consumos.online/api`
- **Uso**: Ambiente de producción en vivo

## 🚀 Cómo Ejecutar en Cada Ambiente

### Opción 1: Usar Scripts (Recomendado)

```bash
# Desarrollo (local)
./run-dev.sh

# Producción
./run-prod.sh
```

### Opción 2: Comando Flutter directo

```bash
# Development
flutter run --dart-define=ENVIRONMENT=development

# Production
flutter run --dart-define=ENVIRONMENT=production

# Staging
flutter run --dart-define=ENVIRONMENT=staging
```

### Opción 3: Usar VSCode/Android Studio

Si usas VSCode o Android Studio, en el selector de configuración de ejecución aparecerán:
- **Development** - Para desarrollo local
- **Production** - Para probar contra API de producción
- **Staging** - Para staging

## 🔧 Configuración en el Código

El archivo `lib/core/config/environment.dart` maneja la selección automática:

```dart
// Obtener URL del API según el ambiente
Environment.apiBaseUrl

// Verificar ambiente actual
Environment.isProduction  // true si está en producción
Environment.isDevelopment // true si está en desarrollo
Environment.name          // "Production", "Development", "Staging"
```

## 📱 Notas Importantes

### Para Android Emulator
- **Development**: Usa `10.0.2.2` en lugar de `localhost`
- Esto está configurado automáticamente en `environment.dart`

### Para iOS Simulator
- **Development**: Usa `localhost` directamente

### Para Testing en Producción
Si quieres probar la app en el emulador contra el API de producción:

```bash
flutter run --dart-define=ENVIRONMENT=production
```

Esto te conectará a `https://api.consumos.online/api` en lugar del localhost.

## 🏗️ Builds para Distribución

### APK de Producción
```bash
flutter build apk --dart-define=ENVIRONMENT=production
```

### App Bundle (para Google Play)
```bash
flutter build appbundle --dart-define=ENVIRONMENT=production
```

### iOS (para App Store)
```bash
flutter build ios --dart-define=ENVIRONMENT=production
```

## 🐛 Troubleshooting

### Error: "Connection refused"
- **En Development**: Verifica que el API local esté corriendo en el puerto 3000
- **En Production**: Verifica que `https://api.consumos.online` esté accesible

### Error: "DioException [connection error]"
- Verifica tu conexión a internet
- En emulador Android, verifica que puedas acceder a internet

### Cambiar de ambiente sin recompilar
No es posible. Debes detener la app y volver a ejecutar con el `--dart-define` correcto.
