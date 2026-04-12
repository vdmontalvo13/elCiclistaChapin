# El Ciclista Chapín

> Plataforma de gestión e inscripción a eventos de ciclismo en Guatemala.  
> Conecta a ciclistas con organizadores de carreras, travesías y colonadas en todo el país.

---

## Tabla de Contenidos

- [Descripción General](#descripción-general)
- [Tecnologías y Versiones](#tecnologías-y-versiones)
- [Características Principales](#características-principales)
- [Arquitectura y Estructura del Proyecto](#arquitectura-y-estructura-del-proyecto)
- [Modelos de Datos](#modelos-de-datos)
- [Servicios](#servicios)
- [Pantallas](#pantallas)
- [Navegación](#navegación)
- [Tema y Diseño Visual](#tema-y-diseño-visual)
- [Backend: Firebase](#backend-firebase)
- [Configuración del Entorno](#configuración-del-entorno)
- [Instalación y Ejecución](#instalación-y-ejecución)
- [Compilación para Producción](#compilación-para-producción)
- [Configuración Android](#configuración-android)
- [Configuración iOS](#configuración-ios)
- [Configuración Web](#configuración-web)
- [Assets](#assets)
- [Ramas Git](#ramas-git)

---

## Descripción General

**El Ciclista Chapín** es una aplicación multiplataforma desarrollada con **Flutter** que funciona como ecosistema centralizado para la comunidad ciclista de Guatemala. Permite a los ciclistas descubrir eventos, inscribirse a carreras y gestionar sus participaciones, mientras que los organizadores pueden crear y administrar sus propias competencias de forma completa.

La aplicación soporta dos roles de usuario diferenciados (`ciclista` y `organizador`), con una interfaz completamente responsiva que se adapta tanto a dispositivos móviles como a la web.

---

## Tecnologías y Versiones

| Tecnología | Versión |
|---|---|
| **Flutter SDK** | `^3.38.x` (stable) |
| **Dart SDK** | `^3.9.2` |
| **Firebase Core** | `^3.6.0` |
| **Firebase Auth** | `^5.3.1` |
| **Cloud Firestore** | `^5.4.4` |
| **Firebase Storage** | `^12.3.4` |
| **intl** | `^0.19.0` |
| **pdf** | `^3.11.1` |
| **printing** | `^5.13.3` |
| **cupertino_icons** | `^1.0.8` |
| **flutter_launcher_icons** | `^0.14.3` |
| **flutter_lints** | `^5.0.0` |

**Versión de la app:** `1.0.0+1`

---

## Características Principales

### Para Ciclistas
- Explorar y descubrir eventos de ciclismo activos
- Filtrar eventos por **fecha**, **tipo** (Travesía, Colazo, Carrera), **disciplina** (MTB, Ruta, Gravel, Urbano) y **departamento**
- Ver detalle completo de cada evento: ubicación, categorías, fecha, distancia, desnivel
- Inscribirse a carreras por categoría, con selección de datos de pago (boleta bancaria)
- Adjuntar imagen del comprobante de pago
- Seguimiento del estado de inscripción: **Pendiente / Aprobado / Rechazado**
- Ver resumen de inscripción con número de corredor asignado
- Descargar/imprimir ficha de inscripción en **PDF**
- Gestionar perfil personal (foto, información, preferencia de ciclismo)

### Para Organizadores
- Crear eventos con: categorías, ubicación, descripción, tipo, disciplina, imagen de portada, cupos y cuenta bancaria
- Editar eventos existentes y previsualizar antes de publicar
- Gestionar inscripciones: ver pendientes, **aprobar o rechazar** con motivo
- Asignar número de corredor a los participantes aprobados
- Ver lista completa de participantes inscritos

### Administración
- Panel de aprobación de cuentas de organizadores pendientes

---

## Arquitectura y Estructura del Proyecto

```
el_ciclista_chapin/
│
├── android/                        # Configuración nativa Android
│   ├── app/
│   │   ├── build.gradle.kts        # Build config (appId, SDK versions, Kotlin)
│   │   └── google-services.json    # Firebase config para Android
│   ├── gradle.properties           # JVM args y AndroidX flags
│   └── local.properties            # Rutas locales (SDK, Flutter) — no commitear
│
├── ios/                            # Configuración nativa iOS
│   └── Runner/
│       └── Info.plist              # Bundle ID, orientaciones soportadas
│
├── web/                            # Plataforma web
│   ├── index.html                  # Entry point web + PWA config
│   └── manifest.json               # Web app manifest
│
├── assets/
│   └── images/
│       ├── logo.png                # Logo principal de la app (4.3 MB, LFS)
│       └── portada.jpg             # Imagen banner del home (335 KB, LFS)
│
├── lib/                            # Código fuente Dart
│   ├── main.dart                   # Entry point: Firebase init + runApp
│   ├── firebase_options.dart       # Configuración Firebase por plataforma
│   │
│   ├── constants/
│   │   └── colors.dart             # Paleta de colores centralizada
│   │
│   ├── models/                     # Modelos de datos Firestore
│   │   ├── user_model.dart
│   │   ├── event_model.dart
│   │   ├── inscription_model.dart
│   │   └── categoria_model.dart
│   │
│   ├── services/                   # Lógica de negocio + Firebase calls
│   │   ├── auth_service.dart
│   │   ├── event_service.dart
│   │   ├── home_service.dart
│   │   ├── inscription_service.dart
│   │   ├── profile_service.dart
│   │   └── approval_service.dart
│   │
│   ├── screens/                    # Pantallas de la aplicación (21 screens)
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── events/
│   │   │   ├── events_screen.dart
│   │   │   ├── event_detail_screen.dart
│   │   │   └── event_inscription_screen.dart
│   │   ├── my_races/
│   │   │   ├── my_races_screen.dart
│   │   │   ├── inscription_detail_screen.dart
│   │   │   └── inscription_summary_screen.dart
│   │   ├── inscriptions/
│   │   │   └── inscriptions_screen.dart
│   │   ├── organizer_events/
│   │   │   ├── organizer_events_screen.dart
│   │   │   ├── my_events_tab.dart
│   │   │   ├── inscriptions_tab.dart
│   │   │   └── participants_tab.dart
│   │   └── profile/
│   │       ├── profile_screen.dart
│   │       ├── edit_profile_screen.dart
│   │       ├── create_event_screen.dart
│   │       ├── edit_event_screen.dart
│   │       ├── event_preview_screen.dart
│   │       └── approve_organizers_screen.dart
│   │
│   └── widgets/                    # Componentes reutilizables
│       ├── top_navbar.dart         # Navbar superior (web)
│       ├── sidebar.dart            # Sidebar lateral
│       └── web_frame.dart          # Wrapper layout responsivo web
│
├── test/                           # Tests (directorio base Flutter)
├── pubspec.yaml                    # Dependencias y configuración del proyecto
├── pubspec.lock                    # Lock file de dependencias
├── analysis_options.yaml           # Reglas del linter (flutter_lints)
├── firebase.json                   # Metadatos del proyecto Firebase
└── .gitattributes                  # Git LFS para assets grandes
```

**Totales:** 4 modelos · 6 servicios · 21 pantallas · 3 widgets · 1 archivo de constantes

---

## Modelos de Datos

### `UserModel`
Representa a un usuario registrado en la plataforma.

| Campo | Tipo | Descripción |
|---|---|---|
| `uid` | `String` | ID de Firebase Auth |
| `nombre` / `apellido` | `String` | Nombre completo |
| `email` | `String` | Correo electrónico |
| `telefono` | `String` | Número de contacto |
| `rol` | `String` | `'ciclista'` o `'organizador'` |
| `ciclismoPreferido` | `String?` | Disciplina favorita |
| `genero` | `String?` | Género del ciclista |
| `fechaNacimiento` | `String?` | Fecha de nacimiento |
| `descripcion` | `String?` | Bio personal |
| `fotoPerfil` | `String?` | URL de imagen en Storage |

### `EventModel`
Representa un evento o carrera de ciclismo.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | `String` | ID del documento Firestore |
| `nombre` | `String` | Nombre del evento |
| `descripcion` | `String` | Descripción detallada |
| `fecha` / `hora` | `String` | Fecha y hora del evento |
| `ubicacion` | `Map` | `{municipio, departamento}` |
| `tipoEvento` | `String` | Travesía, Carrera, Colazo, etc. |
| `disciplina` | `String` | MTB, Ruta, Gravel, Urbano |
| `imagenUrl` | `String` | URL banner en Storage |
| `categorias` | `List<Map>` | Lista de categorías del evento |
| `organizadorId` | `String` | UID del organizador |
| `cuentaBancaria` | `String` | Cuenta para pagos |
| `cuposDisponibles` | `int` | Cupos restantes |
| `estado` | `String` | Estado del evento |

### `InscriptionModel`
Registra la inscripción de un ciclista a un evento.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | `String` | ID del documento |
| `eventoId` / `eventoNombre` | `String` | Referencia al evento |
| `ciclistaId` | `String` | UID del ciclista |
| `ciclistaNombre` / `Apellido` / `Email` / `Telefono` | `String` | Datos del ciclista |
| `categoriaNombre` | `String` | Categoría inscrita |
| `numeroBoletaPago` / `banco` / `fechaPago` | `String` | Datos del pago |
| `imagenBoleta` | `String?` | URL comprobante en Storage |
| `estado` | `String` | `en_progreso`, `aprobado`, `rechazado` |
| `motivoRechazo` | `String?` | Razón si fue rechazado |
| `numeroAsignado` | `String?` | Número de corredor asignado |

### `CategoriaModel`
Define una categoría dentro de un evento.

| Campo | Tipo | Descripción |
|---|---|---|
| `nombre` | `String` | Nombre de categoría (ej: "Elite Varones") |
| `edadMin` / `edadMax` | `int` | Rango de edad |
| `genero` | `String` | Género al que aplica |
| `distancia` | `double` | Distancia en km |
| `elevacion` | `double` | Desnivel en metros |
| `precioInscripcion` | `double` | Costo de inscripción |

---

## Servicios

La capa de servicios maneja toda la comunicación con Firebase y la lógica de negocio. **No hay un gestor de estado externo** — se usan `StatefulWidget`, `FutureBuilder` y `StreamBuilder` directamente.

| Servicio | Responsabilidad |
|---|---|
| `AuthService` | Registro, login, logout, obtener usuario actual, stream de estado de auth |
| `EventService` | Crear y actualizar eventos en Firestore |
| `HomeService` | Estadísticas globales, eventos activos y próximos (con Streams) |
| `InscriptionService` | Crear inscripciones, aprobar/rechazar, subir comprobantes a Storage |
| `ProfileService` | Actualizar perfil, subir foto, listar organizadores pendientes de aprobación |
| `ApprovalService` | Aprobar o rechazar cuentas de organizadores nuevos |

---

## Pantallas

| Pantalla | Ruta lógica | Rol | Descripción |
|---|---|---|---|
| `SplashScreen` | Inicio | Todos | Animación de logo (fade + scale, 3s). Redirige según estado de auth |
| `LoginScreen` | `/login` | Todos | Login con email/contraseña. Responsivo mobile/web |
| `RegisterScreen` | `/register` | Todos | Registro con rol, preferencia, género, fecha de nacimiento |
| `HomeScreen` | `/home` | Todos | Dashboard con estadísticas, banner y próximos eventos |
| `EventsScreen` | `/events` | Todos | Listado de eventos con filtros avanzados |
| `EventDetailScreen` | `/events/:id` | Todos | Detalle completo de un evento |
| `EventInscriptionScreen` | `/events/:id/inscribir` | Ciclista | Selección de categoría e inscripción |
| `MyRacesScreen` | `/mis-carreras` | Ciclista | Mis inscripciones activas |
| `InscriptionDetailScreen` | — | Ciclista | Detalle de una inscripción específica |
| `InscriptionSummaryScreen` | — | Ciclista | Resumen final con opción PDF |
| `InscriptionsScreen` | — | Todos | Vista general de inscripciones |
| `OrganizerEventsScreen` | `/mis-eventos` | Organizador | Panel con 3 tabs |
| `MyEventsTab` | — | Organizador | Listado de mis eventos creados |
| `InscriptionsTab` | — | Organizador | Gestión de inscripciones recibidas |
| `ParticipantsTab` | — | Organizador | Lista de participantes aprobados |
| `ProfileScreen` | `/perfil` | Todos | Perfil del usuario con opciones por rol |
| `EditProfileScreen` | — | Todos | Editar datos personales y foto |
| `CreateEventScreen` | — | Organizador | Formulario de creación de evento |
| `EditEventScreen` | — | Organizador | Edición de evento existente |
| `EventPreviewScreen` | — | Organizador | Preview antes de publicar |
| `ApproveOrganizersScreen` | — | Admin | Panel de aprobación de organizadores |

---

## Navegación

La app usa el **Navigator estándar de Flutter** (`Navigator.push` / `Navigator.pushReplacement`). No utiliza `go_router` ni ningún paquete de routing externo.

```
SplashScreen
    └── (FirebaseAuth.currentUser != null?)
        ├── SÍ → HomeScreen
        └── NO → LoginScreen ↔ RegisterScreen
                       └── HomeScreen (hub principal)
                               ├── [0] Home
                               ├── [1] Eventos
                               ├── [2] Mis Carreras (ciclista) / Mis Eventos (organizador)
                               └── [3] Perfil
```

- **Mobile:** Bottom Navigation Bar con 4 ítems
- **Web:** Top Navbar con links de navegación horizontal

---

## Tema y Diseño Visual

### Paleta de Colores (`lib/constants/colors.dart`)

| Nombre | HEX / Color | Uso |
|---|---|---|
| `primary` | `#2D8B6E` (verde teal) | Color principal |
| `secondary` | `#8FBF3B` (verde claro) | Acentos secundarios |
| `accent` | `#FF6B6B` (rojo/naranja) | Llamadas a la acción |
| `darkBlue` | `#1E3A5F` (azul oscuro) | Fondos oscuros |
| `buttonPrimary` | `#097D8D` (cyan teal) | Botones principales |
| `background` | `#F5F5F5` | Fondo de pantallas |
| `approved` | `#4CAF50` (verde) | Estado aprobado |
| `pending` | `#FF9800` (naranja) | Estado pendiente |
| `rejected` | `#F44336` (rojo) | Estado rechazado |

**Gradiente principal:** `#4DD0E1` → `#2D8B6E` (diagonal top-left a bottom-right)

### Colores por Disciplina

| Disciplina | Color |
|---|---|
| MTB | `#8B4513` (café) |
| Ruta | `#FF8C42` (naranja) |
| Gravel | `#6B8E23` (oliva) |
| Urbano | `#4682B4` (azul acero) |

### Tipografía
- **Familia:** Roboto (Material Design default)
- **Tema:** Material Light con `primarySwatch: Colors.teal`

---

## Backend: Firebase

El backend completo está construido sobre **Firebase**. No hay servidor propio ni API REST.

### Proyecto Firebase
- **Project ID:** `el-ciclista-chapin`
- **Auth Domain:** `el-ciclista-chapin.firebaseapp.com`
- **Storage Bucket:** `el-ciclista-chapin.firebasestorage.app`
- **Project Number:** `329717792262`

### Servicios en uso

| Servicio | Descripción |
|---|---|
| **Firebase Authentication** | Login y registro con email/contraseña |
| **Cloud Firestore** | Base de datos principal (colecciones: `users`, `events`, `inscriptions`) |
| **Firebase Storage** | Almacenamiento de imágenes (eventos, fotos de perfil, boletas de pago) |

### Colecciones Firestore

```
users/
  {uid}/               ← UserModel (rol, nombre, email, foto, etc.)

events/
  {eventId}/           ← EventModel (nombre, disciplina, categorias[], etc.)

inscriptions/
  {inscriptionId}/     ← InscriptionModel (ciclistaId, eventoId, estado, etc.)
```

### Credenciales por Plataforma

Las credenciales están configuradas en `lib/firebase_options.dart` y `android/app/google-services.json`. **Estos archivos NO deben subirse a repositorios públicos.**

| Plataforma | Application ID / Bundle ID |
|---|---|
| Android | `com.elciclistachapin.app` |
| iOS | `com.example.elCiclistaChapin` |
| Web | `el-ciclista-chapin` (proyecto Firebase) |

---

## Configuración del Entorno

### Requisitos previos

- **Flutter SDK** >= 3.9 instalado y en el `PATH`
- **Dart SDK** >= 3.9.2 (incluido con Flutter)
- **Android Studio** con Android SDK configurado (para Android)
- **Xcode** >= 15 (solo para compilar iOS — requiere macOS)
- **Google Chrome** (para desarrollo web)
- **Git LFS** instalado (`git lfs install`) — los assets usan LFS

### Variables de entorno / Archivos sensibles

Este proyecto **no usa archivos `.env`**. Las credenciales de Firebase están embebidas en:

- `lib/firebase_options.dart` — credenciales para todas las plataformas
- `android/app/google-services.json` — credenciales específicas de Android
- `ios/Runner/GoogleService-Info.plist` — credenciales específicas de iOS

> **Importante:** Para levantar el proyecto necesitas estos archivos. Si no los tienes, solicítalos al equipo o crea tu propio proyecto en Firebase Console y reemplaza los valores usando `flutterfire configure`.

---

## Instalación y Ejecución

### 1. Clonar el repositorio

```bash
git clone <URL_DEL_REPOSITORIO>
cd el_ciclista_chapin
```

### 2. Instalar Git LFS y descargar assets

```bash
git lfs install
git lfs pull
```

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Verificar configuración del entorno

```bash
flutter doctor
```

Asegúrate de que no haya errores críticos en Android toolchain y Flutter.

### 5. Ejecutar la aplicación

```bash
# En dispositivo/emulador Android o iOS
flutter run

# Específicamente en Chrome (web)
flutter run -d chrome

# En Windows (escritorio)
flutter run -d windows

# Listar dispositivos disponibles
flutter devices
```

### 6. Generar iconos del launcher (si modificas el logo)

```bash
dart run flutter_launcher_icons
```

---

## Compilación para Producción

### Android APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (recomendado para Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

> **Nota:** La configuración de release signing en `build.gradle.kts` usa el keystore de debug por defecto. Para publicar en producción, configura un keystore de release apropiado.

### Web

```bash
flutter build web --release
# Output: build/web/
```

### iOS (requiere macOS + Xcode)

```bash
flutter build ios --release
```

### Windows

```bash
flutter build windows --release
```

---

## Configuración Android

**Archivo:** `android/app/build.gradle.kts`

```kotlin
android {
    namespace         = "com.elciclistachapin.app"
    compileSdk        = flutter.compileSdkVersion   // Default Flutter (34+)
    
    defaultConfig {
        applicationId = "com.elciclistachapin.app"
        minSdk        = flutter.minSdkVersion       // Default Flutter (21)
        targetSdk     = flutter.targetSdkVersion    // Default Flutter (34+)
        versionCode   = 1
        versionName   = "1.0.0"
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}
```

**Plugins requeridos:**
- `com.android.application`
- `com.google.gms.google-services` (Firebase)
- `kotlin-android`
- `dev.flutter.flutter-gradle-plugin`

**`gradle.properties`:**
```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G
android.useAndroidX=true
android.enableJetifier=true
```

---

## Configuración iOS

**Archivo:** `ios/Runner/Info.plist`

| Propiedad | Valor |
|---|---|
| `CFBundleDisplayName` | El Ciclista Chapin |
| `CFBundleName` | el_ciclista_chapin |
| `CFBundleShortVersionString` | `$(FLUTTER_BUILD_NAME)` → `1.0.0` |
| `CFBundleVersion` | `$(FLUTTER_BUILD_NUMBER)` → `1` |

**Orientaciones soportadas:**
- iPhone: Portrait, Landscape Left, Landscape Right
- iPad: Todas las orientaciones (incluido Portrait Upside Down)

---

## Configuración Web

**Archivo:** `web/index.html`

La app web soporta instalación como **PWA (Progressive Web App)**:

- Manifest configurado en `web/manifest.json`
- Icono Apple Touch configurado
- Meta tags para `apple-mobile-web-app-capable`
- Favicon generado desde el logo

Para desplegar en producción:

```bash
flutter build web --release
# Sube el contenido de build/web/ a tu servidor o Firebase Hosting
```

**Firebase Hosting (opcional):**

```bash
firebase deploy --only hosting
```

---

## Assets

Los archivos de assets están gestionados con **Git LFS** (Large File Storage).

| Archivo | Tamaño | Uso |
|---|---|---|
| `assets/images/logo.png` | 4.3 MB | Logo de la app: splash, login, navbar, launcher icons |
| `assets/images/portada.jpg` | 335 KB | Banner de portada del Home |

Los assets se declaran en `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
```

Los **launcher icons** para todas las plataformas se generan automáticamente desde `logo.png` usando `flutter_launcher_icons`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.png"
  web:
    generate: true
    background_color: "#000000"
    theme_color: "#000000"
  windows:
    generate: true
  macos:
    generate: true
```

---

## Ramas Git

| Rama | Estado | Descripción |
|---|---|---|
| `main` | Estable | Rama principal de producción |
| `rebranding` | Activa | Rama de trabajo actual — rediseño visual y nuevas pantallas |

### Historial reciente

```
1c7ff67  Nuevas pantallas de flujo evento - detalle - inscripcion
db8dcba  Home page renderizada para web y refactorizacion de la pagina
9c1fbbf  Nuevas paginas de login y registro
6e32ca0  Logos y nombre de la app actualizados
04481e2  Configuracion Git LFS para Assets
```

---

## Análisis de Código

```bash
# Ejecutar el linter
flutter analyze

# Correr tests
flutter test
```

La configuración del linter está en `analysis_options.yaml` usando las reglas base de `flutter_lints`.

---

## Plataformas Soportadas

| Plataforma | Estado |
|---|---|
| Android | Soportado |
| iOS | Soportado |
| Web (Chrome) | Soportado + Responsivo |
| Windows | Configurado |
| macOS | Configurado |
| Linux | Configurado |

---

*Desarrollado con Flutter — Comunidad Ciclista de Guatemala*
