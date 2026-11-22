# AireClaro (prototipo)

App Android hecha con Flutter para que motociclistas, ciclistas y peatones reporten vehículos que botan humo contaminante en el corredor Soacha–Bogotá. La app arma automáticamente una solicitud formal tipo PQRSD en PDF con foto o video, ubicación, fecha, hora y placa.

> Prototipo funcional. No tiene backend: todo se guarda en el teléfono.

## Funcionalidades

- Registro e inicio de sesión (con aceptación de tratamiento de datos, Ley 1581 de 2012).
- Nuevo reporte en 4 pasos:
  1. Evidencia: tomar foto, grabar video o subir desde galería.
  2. Datos del vehículo: placa, color del humo y descripción (con dictado por voz).
  3. Ubicación y hora: GPS automático y mapa (OpenStreetMap), con ajuste manual del punto.
  4. Datos del peticionario: se precargan desde la cuenta.
- Generación del PDF de la PQRSD con número de radicado interno (ej. `AC-2026-00001`).
- Abrir y compartir el PDF (correo, WhatsApp, Drive, etc.).
- Historial "Mis reportes" con estado (Generado / Enviado), reenvío y eliminación.

## Tecnologías (todas gratuitas)

| Necesidad | Paquete |
|---|---|
| App | Flutter + Dart |
| Base de datos local | `sqflite` |
| Contraseñas | `crypto` (SHA-256 con sal) |
| Foto, video y galería | `image_picker` |
| GPS | `geolocator` |
| Mapa | `flutter_map` + OpenStreetMap |
| Dictado por voz | `speech_to_text` |
| PDF | `pdf` |
| Abrir y compartir | `open_filex`, `share_plus` |

## Requisitos

- Flutter SDK
- Android Studio (solo para el SDK de Android, con *Command-line Tools*, una plataforma reciente y el NDK)
- Un celular Android con **Depuración USB** activada
- Internet en el teléfono (para cargar el mapa)

Verifica tu entorno con:

```
flutter doctor
```

## Cómo ejecutar

```
git clone <url-del-repositorio>
cd aireclaro
flutter pub get
flutter devices
flutter run
```

La primera compilación puede tardar varios minutos.

> Recomendación en Windows: ubica el proyecto en una ruta corta y sin espacios (por ejemplo `C:\src\aireclaro`), fuera de OneDrive.

## Generar el APK

```
flutter build apk --release
```

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`.

## Estructura

```
lib/
├── main.dart
├── db/app_database.dart          # SQLite (usuarios y reportes)
├── models/report_draft.dart      # Borrador del reporte entre pantallas
├── services/
│   ├── auth_service.dart         # Registro, login y sesión
│   ├── report_service.dart       # Crear, listar, actualizar y borrar reportes
│   └── pdf_service.dart          # Generación del PDF
└── screens/
    ├── login_screen.dart
    ├── register_screen.dart
    ├── home_screen.dart
    ├── evidence_screen.dart      # Paso 1
    ├── vehicle_screen.dart       # Paso 2
    ├── location_screen.dart      # Paso 3
    ├── petitioner_screen.dart    # Paso 4
    ├── success_screen.dart
    └── history_screen.dart
```

## Limitaciones del prototipo

- No hay servidor: los datos y archivos viven solo en el teléfono. Si se desinstala la app, se pierden.
- El envío no es automático: el PDF se comparte desde el celular y el usuario lo envía a la entidad.
- El estado "Enviado" se marca manualmente.
- La plantilla del texto legal del PDF es genérica; debe ser validada antes de uso real.
- Solo Android.

## Posibles mejoras

- Lectura automática de la placa con OCR (`google_mlkit_text_recognition`).
- Backend para sincronizar reportes y enviarlos directamente a la entidad.
- Docker para compilar el APK sin instalar Flutter.
