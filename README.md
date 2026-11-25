<div align="center">
  <img src="assets/images/app_logo.png" alt="Logo de descuidaU" width="220" />
  <h1>descuidaU</h1>
  <p><strong>Plataforma móvil para reportar, buscar y recuperar objetos perdidos y encontrados dentro del campus universitario.</strong></p>

  ![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
  ![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?logo=firebase&logoColor=black)
  ![Platform](https://img.shields.io/badge/Plataforma-iOS%20%7C%20Android-2E7D32)
</div>

---

## Descripción

**descuidaU** es una aplicación móvil multiplataforma desarrollada en **Flutter** y respaldada por **Firebase**, diseñada para centralizar en tiempo real los reportes de objetos extraviados (*Perdido*) y hallados (*Encontrado*) dentro de la sede universitaria.

Este proyecto fue desarrollado como evaluación de la asignatura **Desarrollo de Aplicaciones Móviles** en la **Universidad Técnica Federico Santa María**.

---

## Funcionalidades Principales

* **Autenticación con Google:** Inicio y cierre de sesión mediante cuenta Google con persistencia automática de estado a través de `StreamBuilder` (`AuthWrapper`).
* **Listado en Tiempo Real:** Sincronización instantánea con Cloud Firestore dividida en dos vistas mediante barra de navegación inferior (`NavigationBar`):
  * **Explorar:** Feed general con todas las publicaciones ordenadas cronológicamente.
  * **Mis Publicaciones:** Vista filtrada por el `uid` del usuario autenticado.
* **Publicación Validada con Fotografía:**
  * Formulario con validación completa (`GlobalKey<FormState>`) para tipo de publicación, título, categoría dinámica desde Firestore, ubicación en el campus, selector nativo de fecha y hora (`DD/MM/AAAA HH:mm`) y descripción.
  * Captura desde cámara o galería mediante `image_picker` con redimensionamiento y compresión automática (`maxWidth: 1024`, `maxHeight: 1024`) para cumplir estrictamente con el límite de **1 MB por documento** en Firestore, almacenando la imagen directamente como tipo binario `Blob`.
* **Detalle y Gestión de Ciclo de Vida:**
  * Visualización completa del objeto, metadatos y autor.
  * Acciones exclusivas para el creador de la publicación: marcar el objeto como **Devuelto** (actualizando su estado y estilo visual en las tarjetas) o **Eliminar** el registro previa confirmación mediante `AlertDialog`.

---

## Stack Tecnológico

* **Framework:** Flutter (Material Design 3)
* **Lenguaje:** Dart
* **Autenticación:** `firebase_auth` & `google_sign_in`
* **Base de Datos NoSQL:** `cloud_firestore`
* **Multimedia y Utilidades:** `image_picker` (cámara/galería), `intl` (formateo de fechas)

---

## Arquitectura del Proyecto

```text
descuidau/
├── assets/
│   └── images/
│       ├── app_logo.png              # Identidad visual de descuidaU
│       └── google_logo.png           # Ícono oficial para inicio de sesión
├── lib/
│   ├── main.dart                     # Inicialización de Firebase y punto de entrada
│   ├── pages/
│   │   ├── detalle_page.dart         # Vista completa del objeto y acciones del autor
│   │   ├── home_page.dart            # Navegación principal (Explorar / Mis Publicaciones)
│   │   ├── login_page.dart           # Pantalla de acceso con Google
│   │   └── publicar_page.dart        # Formulario validado y compresión de imagen
│   ├── services/
│   │   ├── auth_service.dart         # Lógica de Firebase Auth y Google Sign-In
│   │   └── fs_service.dart           # Consultas Stream y operaciones CRUD en Firestore
│   ├── theme/
│   │   └── app_theme.dart            # Paleta de colores corporativa y estilos globales
│   └── widgets/
│       ├── auth_wrapper.dart         # Controlador reactivo de sesión
│       └── publicacion_card.dart     # Tarjeta reutilizable con renderizado condicional
└── pubspec.yaml
```

---

## Modelo de Datos en Cloud Firestore

### Colección `publicaciones`
| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `titulo` | `string` | Nombre breve del objeto perdido o encontrado |
| `descripcion` | `string` | Características detalladas y medio de contacto |
| `tipo` | `string` | `"Perdido"` o `"Encontrado"` |
| `categoria` | `string` | Categoría seleccionada desde la colección `categorias` |
| `lugar` | `string` | Sector o sala del campus donde ocurrió el evento |
| `fechaHora` | `string` | Fecha y hora formateada (`DD/MM/AAAA HH:mm`) |
| `estado` | `string` | `"Vigente"` (por defecto) o `"Devuelto"` |
| `foto` | `bytes (Blob)` | Fotografía comprimida bajo 1 MB |
| `autorNombre` | `string` | Nombre visible obtenido desde la cuenta Google |
| `autorUid` | `string` | Identificador único (`uid`) del creador en Firebase Auth |
| `fechaCreacion` | `timestamp` | Marca de tiempo del servidor (`FieldValue.serverTimestamp()`) |

### Colección `categorias`
Documentos con el campo `nombre` (`string`): `Electrónica`, `Documentos`, `Ropa y accesorios`, `Llaves`, `Útiles` y `Otros`.

---

## Instalación y Ejecución Local

1. **Clonar el repositorio e instalar dependencias:**
   ```bash
   cd descuidau
   flutter pub get
   ```

2. **Configuración de Firebase:**
   * Crear un proyecto en [Firebase Console](https://console.firebase.google.com/) con **Authentication (Proveedor Google)** y **Cloud Firestore** habilitados.
   * **iOS:** Añadir `GoogleService-Info.plist` en `ios/Runner/` y registrar el `REVERSED_CLIENT_ID` dentro de `CFBundleURLTypes` en `ios/Runner/Info.plist`.
   * **Android:** Añadir `google-services.json` en `android/app/`.

3. **Ejecutar la aplicación en dispositivo o emulador:**
   ```bash
   flutter run
   ```

---

## Autor

**Joaquín Contreras Valenzuela**  
Estudiante de Técnico en Informática — Universidad Técnica Federico Santa María (2026)
