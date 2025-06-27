# Water Management System - Mobile App

Aplicación móvil Flutter para el registro de lecturas de medidores de agua con funcionalidades offline, OCR y sincronización automática.

## 🚀 Características

- **Registro Offline**: Funciona sin conexión a internet
- **OCR Inteligente**: Reconocimiento automático de lecturas con ML Kit
- **Cámara Integrada**: Captura de fotos de medidores y recibos
- **Sincronización Automática**: Sync cuando hay conexión disponible
- **Multi-Condominio**: Soporte para múltiples condominios
- **Notificaciones Push**: Alertas importantes con Firebase
- **Interfaz Intuitiva**: Diseño optimizado para conserjes y administradores

## 📋 Requisitos

- Flutter 3.7.2+
- Dart SDK 3.0+
- Android Studio / Xcode
- Backend API ejecutándose

## 🛠️ Instalación

1. **Clonar y navegar al directorio APP**
   ```bash
   cd water-management-system/APP
   ```

2. **Instalar dependencias de Flutter**
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase**
   - Agregar `google-services.json` (Android) en `android/app/`
   - Agregar `GoogleService-Info.plist` (iOS) en `ios/Runner/`

4. **Configurar API endpoints**
   Editar `lib/core/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android Emulator
   // static const String baseUrl = 'http://localhost:3000/api'; // iOS Simulator
   ```

5. **Ejecutar la aplicación**
   ```bash
   # Android
   flutter run

   # iOS (requiere Xcode)
   flutter run -d ios
   ```

## 🏗️ Estructura del Proyecto

```
lib/
├── core/                    # Funcionalidades base
│   ├── models/             # Modelos de datos
│   │   ├── auth_state.dart # Estado de autenticación
│   │   ├── condominium.dart # Modelo de condominio
│   │   ├── reading.dart    # Modelo de lecturas
│   │   └── user.dart       # Modelo de usuario
│   ├── providers/          # Estado global (Riverpod)
│   │   ├── auth_provider.dart
│   │   ├── condominium_provider.dart
│   │   └── periods_provider.dart
│   ├── services/           # Servicios de la aplicación
│   │   ├── api_service.dart        # Cliente HTTP
│   │   ├── local_database_service.dart # SQLite
│   │   ├── ocr_service.dart        # ML Kit OCR
│   │   └── secure_storage_service.dart # Almacenamiento seguro
│   └── utils/              # Utilidades
├── features/               # Pantallas por funcionalidad
│   ├── auth/              # Autenticación
│   │   └── login_screen.dart
│   ├── condominium/       # Gestión de condominios
│   │   ├── condominium_detail_screen.dart
│   │   ├── condominium_list_screen.dart
│   │   └── unit_detail_screen.dart
│   ├── dashboard/         # Dashboard principal
│   │   └── dashboard_screen.dart
│   ├── onboarding/        # Introducción
│   │   └── onboarding_screen.dart
│   ├── periods/           # Períodos de lectura
│   │   ├── create_period_screen.dart
│   │   └── periods_list_screen.dart
│   ├── readings/          # Registro de lecturas
│   │   ├── camera_reading_screen.dart
│   │   ├── period_readings_screen.dart
│   │   ├── readings_list_screen.dart
│   │   └── unit_readings_history_screen.dart
│   └── settings/          # Configuración
└── shared/                # Componentes compartidos
    ├── constants/         # Constantes y tema
    │   └── app_theme.dart
    └── widgets/           # Widgets reutilizables
        ├── loading_screen.dart
        └── main_layout.dart
```

## 🎯 Funcionalidades Principales

### 1. Autenticación
- Login con email/password
- Almacenamiento seguro de tokens
- Renovación automática de sesión
- Logout con limpieza de datos

### 2. Gestión de Condominios
- Lista de condominios asignados
- Detalles de unidades y residentes
- Navegación por bloques
- Filtros y búsqueda

### 3. Registro de Lecturas
- **Modo Cámara**: Captura directa del medidor
- **OCR Automático**: Reconocimiento de números
- **Validación**: Verificación de lecturas anómalas
- **Fotos**: Almacenamiento de evidencia
- **Offline**: Funcionamiento sin internet

### 4. Sincronización
- **Automática**: Cuando hay conexión
- **Manual**: Botón de sincronización
- **Conflictos**: Resolución inteligente
- **Indicadores**: Estado de sync visual

### 5. Notificaciones
- **Push**: Firebase Cloud Messaging
- **Locales**: Recordatorios de lecturas
- **Estados**: Sync, errores, completado

## 📱 Arquitectura y Patrones

### Estado Global - Riverpod
```dart
// Provider de autenticación
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Uso en widgets
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    // ...
  }
}
```

### Base de Datos Local - SQLite
```dart
// Tablas principales
- condominiums
- units
- residents
- readings
- sync_queue
```

### Servicios Principales

**OCR Service** - Reconocimiento de texto:
```dart
class OCRService {
  Future<OCRResult> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    final recognizedText = await textRecognizer.processImage(inputImage);
    
    return OCRResult(
      text: recognizedText.text,
      confidence: _calculateConfidence(recognizedText),
      numbers: _extractNumbers(recognizedText.text),
    );
  }
}
```

**Local Database Service** - SQLite:
```dart
class LocalDatabaseService {
  Future<void> saveReading(Reading reading) async {
    final db = await database;
    await db.insert('readings', reading.toMap());
  }
  
  Future<List<Reading>> getPendingReadings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'readings',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => Reading.fromMap(maps[i]));
  }
}
```

## 🔄 Funcionalidad Offline

### Estrategia de Sync
1. **Almacenamiento Local**: Todas las lecturas se guardan en SQLite
2. **Cola de Sincronización**: Queue para datos pendientes
3. **Resolución de Conflictos**: Last-write-wins con timestamps
4. **Reintentos**: Backoff exponencial para fallos de red

### Estados de Conectividad
```dart
enum ConnectivityStatus {
  online,
  offline,
  syncing,
  syncError
}
```

## 📷 Implementación OCR

### ML Kit Text Recognition
- **Modelo**: On-device para funcionar offline
- **Idiomas**: Español, números
- **Precisión**: Optimizado para dígitos de medidores
- **Validación**: Verificación de formato esperado

### Flujo de Captura
1. **Cámara**: Previsualización en tiempo real
2. **Captura**: Foto de alta resolución
3. **Procesamiento**: OCR automático en background
4. **Validación**: Verificación de lecturas
5. **Confirmación**: Usuario valida el resultado

## 🔐 Seguridad

- **Almacenamiento Seguro**: flutter_secure_storage para tokens
- **Encriptación**: Datos sensibles encriptados
- **Certificados**: SSL pinning para API calls
- **Sesiones**: Timeout automático
- **Biometría**: Autenticación opcional con huella/Face ID

## 📊 Performance

### Optimizaciones
- **Lazy Loading**: Carga bajo demanda
- **Image Compression**: Compresión de fotos
- **Database Indexing**: Índices en consultas frecuentes
- **Memory Management**: Liberación de recursos
- **Background Processing**: Tareas pesadas en background

### Métricas
- **Tiempo de Inicio**: < 3 segundos
- **OCR Processing**: < 2 segundos promedio
- **Sync Time**: Basado en cantidad de datos
- **Memory Usage**: < 100MB promedio

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

## 📦 Build y Release

### Android
```bash
# Debug APK
flutter build apk

# Release APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

### iOS
```bash
# iOS build
flutter build ios --release

# Archive (App Store)
flutter build ipa --release
```

## 🔧 Configuración de Desarrollo

### Firebase Setup
1. Crear proyecto en Firebase Console
2. Habilitar Authentication, Cloud Messaging
3. Descargar archivos de configuración
4. Configurar SHA-1 para Android

### Permisos Requeridos

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>Esta app necesita acceso a la cámara para capturar lecturas de medidores</string>
```

## 📚 Dependencias Principales

```yaml
dependencies:
  # Estado y navegación
  flutter_riverpod: ^2.4.9    # Estado global
  go_router: ^12.1.3          # Navegación

  # HTTP y storage
  dio: ^5.4.0                 # Cliente HTTP
  shared_preferences: ^2.2.2   # Preferencias simples
  flutter_secure_storage: ^9.0.0  # Almacenamiento seguro
  sqflite: ^2.3.0             # Base de datos local

  # Cámara y OCR
  camera: ^0.10.5+9           # Cámara
  google_mlkit_text_recognition: ^0.11.0  # OCR
  image_picker: ^1.0.7        # Selección de imágenes

  # Firebase
  firebase_core: ^2.24.2      # Firebase core
  firebase_messaging: ^14.7.10  # Push notifications

  # Utilidades
  connectivity_plus: ^5.0.2   # Estado de conexión
  permission_handler: ^11.0.1  # Permisos
  json_annotation: ^4.8.1     # JSON serialization
```

## 🤝 Contribución

1. Seguir las convenciones de Dart/Flutter
2. Usar Riverpod para gestión de estado
3. Implementar tests para funcionalidades críticas
4. Optimizar para funcionalidad offline
5. Documentar cambios importantes

## 📄 Licencia

Este proyecto es parte del sistema integral Water Management System.