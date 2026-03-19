# 🎵 SoundUpar

> **SoundUpar - Red social musical para conexión, colaboración e intercambio de oportunidades entre artistas, bandas y compañías musicales.**
>
> Proyecto de grado — Ingeniería de Sistemas, Universidad Popular del Cesar  
> Autores: Kevin Manuel Castillo Aroca · Rubén Darío Ariza Valencia (2025–2026)

---

## 📁 Estructura del Proyecto

```
soundupar/
├── lib/                          # Código Flutter (frontend - Clean Architecture)
│   ├── main.dart                 # Punto de entrada
│   ├── core/
│   │   ├── constants/            # AppConstants, configuración global
│   │   ├── network/              # Interceptores Dio, resolución dinámicas de URL
│   │   └── services/             # Servicios compartidos
│   ├── data/
│   │   └── repositories/         # Implementaciones de repositorios
│   │       ├── auth_repository.dart
│   │       ├── user_repository.dart
│   │       ├── post_repository.dart
│   │       └── wallet_repository.dart
│   ├── presentation/
│       ├── screens/
│       │   ├── auth/             # Login, Registro, SeleccionRol
│       │   ├── home/             # Feed de posts, explorar usuarios
│       │   ├── post/             # Crear, ver y comentar posts
│       │   ├── splash/           # Pantalla de carga inicial
│       │   └── wallet/           # Gestión de billetera
│       ├── widgets/              # Componentes reutilizables
│       ├── router/               # GoRouter con rutas y guards
│       └── theme/                # AppTheme (colores, tipografía)
│
├── backend/                      # API Node.js + MongoDB
│   └── src/
│       ├── server.js             # Entrada principal con HTTP + Socket.IO
│       ├── app.js                # Express + middlewares (seguridad, CORS, rate limit)
│       ├── config/
│       │   ├── database.js       # Conexión MongoDB
│       │   ├── socket.js         # Socket.IO configuración
│       │   └── env.js            # Validación variables de entorno
│       ├── models/               # Esquemas Mongoose
│       │   ├── Usuario.js        # Registro de artistas, bandas, compañías
│       │   ├── Publicacion.js    # Posts: BUSCANDO_PERSONAL, BUSCANDO_OPORTUNIDAD, GENERAL
│       │   ├── Comentario.js     # Comentarios en publicaciones
│       │   └── Denuncia.js       # Reportes de contenido inapropiado
│       ├── controllers/          # Lógica de negocio por recurso
│       ├── routes/               # Rutas Express
│       │   ├── auth.routes.js
│       │   ├── user.routes.js
│       │   ├── post.routes.js
│       │   └── wallet.routes.js
│       ├── middleware/           # auth.js, errorHandler, validación
│       └── utils/                # AppError, catchAsync, logger
│
├── assets/                       # Imágenes, íconos, fuentes
├── test/                         # Unit, widget e integration tests
├── pubspec.yaml                  # Dependencias Flutter
└── .env                          # Variables de entorno
```

---

## 🚀 Funcionalidades del MVP

### Autenticación y Perfil
- [x] Registro e inicio de sesión (JWT)
- [x] Selección de rol: **Artista**, **Banda/Independiente**, **Compañía**
- [x] Edición de perfil con foto
- [x] Validación de email y contraseña segura

### Sistema de Posts (Red Social)
- [x] **Crear publicaciones** con tres tipos:
  - 🎯 `BUSCANDO_PERSONAL`: Compañías buscando artistas/músicos
  - 💼 `BUSCANDO_OPORTUNIDAD`: Artistas buscando gigs/contratos
  - 💬 `GENERAL`: Posts informativos o de distribución
- [x] Adjuntar evidencias (fotos/videos) en publicaciones
- [x] Especificar precio y vacantes disponibles
- [x] Feed de publicaciones con paginación infinita
- [x] Explorar perfiles de otros usuarios

### Interacción Social
- [x] **Comentarios** en publicaciones
- [x] **Denuncias/Reportes** de contenido inapropiado
- [x] Validación y moderación de contenido

### Billetera
- [x] Sistema de wallet para transacciones
- [x] Historial de movimientos
- [x] Integración con servicios de pago (preparado)

### Chat y Comunicación
- [x] Chat en tiempo real con Socket.IO
- [x] Notificaciones push con Firebase Cloud Messaging
- [x] Historial de conversaciones

### Características Técnicas
- [x] Autenticación JWT con tokens seguros
- [x] Rate limiting (200 req/15 min)
- [x] Almacenamiento multimedia en Cloudinary
- [x] Validación de entrada (sanitización XSS)
- [x] Paginación en listados
- [x] Logs centralizados con Winston
- [x] Seguridad HTTP headers (Helmet)

---

---

## ⚠️ Notas de Compatibilidad — Flutter 3.41.4 / Dart 3.11

| Cambio                        | Detalle                                                                                    |
|------------------------------|--------------------------------------------------------------------------------------------|
| **SDK mínimo**               | `sdk: ">=3.11.0 <4.0.0"` — requerido por Flutter 3.41.x                                  |
| **flutter_bloc 9.x**         | Preferir `context.read<>()` y `context.watch<>()` en lugar de `BlocProvider.of()`         |
| **go_router 17.x**           | Propiedad `subloc` renombrada a `matchedLocation`                                         |
| **firebase_core 4.x**        | Requiere credenciales Firebase actualizadas (google-services.json, GoogleService-Info.plist) |
| **dotenv carga variables**   | `.env` se carga en `main()` para variables de configuración (BASE_URL, etc.)               |
| **Windows rutas largas**     | Instalar Flutter en `C:\Flutter` para evitar errores por límite de ruta en Windows         |
| **Socket.IO client v2**      | Compatible con Socket.IO v4.x del backend                                                 |
| **JWT local storage**        | Los tokens se almacenan en `flutter_secure_storage` para mayor seguridad                   |

---

## ⚙️ Instalación y Configuración

### Requisitos Previos
- **Flutter SDK** `>=3.0.0` (probado en 3.41.4)
- **Dart** `>=3.11.0`
- **Node.js** `>=18.x`
- **MongoDB** (local o MongoDB Atlas)
- **Cuenta Cloudinary** (para almacenamiento multimedia)
- **Proyecto Firebase** (para notificaciones push)
- **Visual Studio Code** o Android Studio

### Backend - Node.js + Express

```bash
cd backend
npm install

# Copiar variables de entorno
cp .env.example .env
# Editar .env con credenciales:
# - MONGODB_URI o MONGO_HOSTS + MONGO_DB
# - JWT_SECRET
# - CLIENT_ORIGIN (URL del frontend, ej: http://localhost:3000)
# - CLOUDINARY_* (credenciales)
# - FIREBASE_* (credenciales)
# - NODE_ENV (development | production)

# Iniciar servidor en desarrollo
npm run dev
# Escucha en http://localhost:3000
```

**Variables de entorno esperadas en `backend/.env`:**

```env
# Base de datos
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/soundupar
# O alternativa (para emuladores/redes):
MONGO_HOSTS=localhost:27017,10.0.2.2:27017
MONGO_DB=soundupar

# Seguridad
JWT_SECRET=tu_llave_secreta_jwt_fuerte
PORT=3000
CLIENT_ORIGIN=http://localhost:3000

# Multimedia
CLOUDINARY_NAME=tu_nombre
CLOUDINARY_API_KEY=tu_key
CLOUDINARY_API_SECRET=tu_secret

# Firebase
FIREBASE_PROJECT_ID=tu_project
FIREBASE_PRIVATE_KEY=tu_private_key
FIREBASE_CLIENT_EMAIL=tu_email

# Logs
NODE_ENV=development
```

**Verificar conexión:**

```bash
curl http://localhost:3000/health
# Respuesta esperada: { "status": "ok", "mongoReadyState": 1 }
```

### Frontend - Flutter

```bash
# En la raíz del proyecto
cp .env.example .env
# Ajustar si es necesario:
# - BASE_URL=http://localhost:3000 (o detectado automáticamente)
# - SOCKET_URL=http://localhost:3000 (o similar)

flutter pub get

# Para Android emulator:
flutter run -d emulator-5554

# Para dispositivo físico:
flutter run -d <device_id>

# Build APK liberación:
flutter build apk --release
```

**Notas importantes:**

- El cliente intenta resolver dinámicamente `BASE_URL` visitando `/health` en el backend
- Para Android emulator, usa `10.0.2.2` en lugar de `localhost`
- Para dispositivos físicos, asegúrate que estén en la misma red que el backend
- Se requiere `flutter_dotenv` para cargar variables desde `.env`

### Variables de entorno esperadas en `.env` (raíz):

```env
# Backend
BASE_URL=http://localhost:3000
SOCKET_URL=http://localhost:3000

# Firebase (opcional para dev local)
# Configurar vía google-services.json (Android) y GoogleService-Info.plist (iOS)
```

### Ejecutar Pruebas

**Backend:**
```bash
cd backend
npm test              # Ejecutar pruebas
npm run lint          # Verificar código
```

**Frontend:**
```bash
flutter test          # Unit + widget tests
```


---

## 🗃️ Modelos de Base de Datos MongoDB

| Colección        | Descripción                                    |
|-----------------|------------------------------------------------|
| `usuarios`       | Cuentas de artistas, bandas y compañías        |
| `publicaciones`  | Posts con tipos: BUSCANDO_PERSONAL, BUSCANDO_OPORTUNIDAD, GENERAL |
| `comentarios`    | Comentarios en publicaciones        |
| `denuncias`      | Reportes de contenido inapropiado              |
| `conversaciones` | Hilos de chat entre dos usuarios (opcional)    |
| `mensajes`       | Mensajes individuales con Socket.IO            |

---

## 🛠 Stack Tecnológico

| Capa              | Tecnología                          | Versión          |
|------------------|-------------------------------------|------------------|
| **Frontend**      |                                     |                  |
| Flutter SDK       | flutter_windows_3.41.4-stable       | 3.41.4           |
| Lenguaje          | Dart                                | 3.11.x           |
| State management  | flutter_bloc                        | ^9.1.1           |
| Navegación        | go_router                           | ^17.1.0          |
| HTTP / API        | dio + retrofit                      | ^5.7.0 / ^4.4.1  |
| Inyección dependencias | get_it + injectable            | ^8.0.3 / ^2.5.0  |
| Almacenamiento local | shared_preferences, hive        | ^2.3.5 / ^2.2.3  |
| Multimedia        | image_picker, video_player, flutter_image_compress | ^1.2.1 / ^2.9.2 / ^2.3.0 |
| Formularios       | reactive_forms, form_validator    | ^17.0.1 / ^2.1.1 |
| UI Components     | flutter_svg, google_fonts, shimmer, lottie | ^2.0.17 / ^6.2.1 / ^3.0.0 / ^3.3.1 |
| Chat tiempo real  | socket_io_client                    | ^2.0.3+1         |
| Autenticación     | jwt_decoder                         | ^2.0.1           |
| **Backend**       |                                     |                  |
| Runtime           | Node.js                             | >=18.x           |
| Framework         | Express.js                          | ^4.19.2          |
| Base de datos     | MongoDB + Mongoose                  | ^8.4.0           |
| Tiempo real       | Socket.IO                           | ^4.7.5           |
| Autenticación     | JWT (jsonwebtoken)                  | ^9.0.2           |
| Encriptación      | bcryptjs                            | ^2.4.3           |
| Validación        | express-validator                   | ^7.1.0           |
| Multimedia        | Cloudinary                          | ^1.34.0          |
| Notificaciones    | firebase-admin                      | ^12.2.0          |
| Seguridad         | helmet, cors, express-rate-limit   | ^7.1.0 / ^2.8.5 / ^7.3.1 |
| Logs              | winston, morgan                     | ^3.13.0 / ^1.10.0 |
| **Testing**       |                                     |                  |
| Testing framework | jest + supertest                    | ^29.7.0 / ^7.0.0 |

---

## 📅 Cronograma de Ejecución

| Fase                        | Período                          | Estado         |
|-----------------------------|----------------------------------|----------------|
| ✅ Análisis y diseño        | 01 Dic – 24 Dic 2025             | **Completado** |
| ✅ Desarrollo MVP           | 26 Dic 2025 – 16 Feb 2026        | **Completado** |
| ⏳ Pruebas funcionales       | 17 Feb – 05 Mar 2026             | **En curso** (12 Mar) |
| ⏳ Ajustes y mejoras        | 06 Mar – 25 Mar 2026             | **En curso**   |
| 📋 Implementación y entrega | 26 Mar – 30 Abr 2026             | **Pendiente**  |

**Nota:** La arquitectura ha evolucionado de una plataforma de convocatorias a una red social musical completa.

---

## � Guía Rápida de Inicio

### 1️⃣ En una terminal, iniciar el backend:

```bash
cd backend
npm install
npm run dev
# El backend escucha en http://localhost:3000
```

### 2️⃣ En otra terminal, iniciar el frontend:

```bash
flutter pub get
flutter run
```

### 3️⃣ Probar la conexión:

```bash
# En el navegador o terminal:
curl http://localhost:3000/health
```

---

## 📚 Referencia de Rutas

### API REST Endpoints

| Método | Ruta                    | Descripción                            |
|--------|------------------------|----------------------------------------|
| POST   | `/auth/register`        | Registro de nuevo usuario              |
| POST   | `/auth/login`           | Inicio de sesión                       |
| GET    | `/users/:id`            | Obtener perfil de usuario              |
| PUT    | `/users/:id`            | Actualizar perfil                      |
| GET    | `/posts`                | Listar posts (con paginación)          |
| POST   | `/posts`                | Crear nuevo post                       |
| GET    | `/posts/:id`            | Obtener detalles de un post            |
| POST   | `/posts/:id/comments`   | Comentar un post                       |
| POST   | `/posts/:id/report`     | Reportar un post                       |
| GET    | `/wallet`               | Obtener balance de wallet              |
| GET    | `/health`               | Verificar estado del backend           |

### Socket.IO Eventos

- `connect`: Conexión establecida
- `message`: Recibir/enviar mensajes en tiempo real
- `notification`: Notificaciones en vivo
- `disconnect`: Desconexión

---

## 🛡️ Seguridad y Mejores Prácticas

- ✅ **Autenticación:** JWT con tokens seguros en almacenamiento seguro (`flutter_secure_storage`)
- ✅ **HTTPS/CORS:** Configurado para producción
- ✅ **Rate Limiting:** 200 solicitudes por 15 minutos
- ✅ **Sanitización:** Protección contra XSS y NoSQL injection
- ✅ **Validación:** Entrada sanitizada en servidor
- ✅ **Encriptación:** Contraseñas con bcryptjs
- ✅ **Headers de Seguridad:** Helmet.js configurado (CSP, X-Frame-Options, etc.)

---

## 🐛 Soporte y Reportar Problemas

Si encuentras problemas:

1. Verifica que el backend esté corriendo: `curl http://localhost:3000/health`
2. Revisa los logs del backend: `backend/*.log`
3. Para Android: `adb logcat`
4. Abre un issue con detalles del problema

---
## 🎯 Próximas Mejoras (Roadmap)

- [ ] **Sistema de recomendaciones** basado en IA para sugerir colaboraciones
- [ ] **Integración de pagos** con pasarelas (Stripe, PayPal)
- [ ] **Notificaciones avanzadas** con preferencias de usuario
- [ ] **Sistema de calificaciones** entre colaboradores
- [ ] **Verificación de identidad** de usuarios
- [ ] **Portafolio multimedia** mejorado con galerías dinámicas
- [ ] **Búsqueda full-text** mejorada con filtros complejos
- [ ] **Soporte para eventos y conciertos**
- [ ] **Análisis y estadísticas** para compañías
- [ ] **App nativa iOS completa** (actualmente en Flutter, funciona en Android)

---

## 📄 Licencia

Este proyecto es un trabajo académico de grado.  
Uso educativo y no comercial únicamente.

---
## �👥 Equipo

| Nombre                     | Cédula      | Contacto                    |
|---------------------------|-------------|------------------------------|
| Kevin Manuel Castillo Aroca | 1004307206 | kmcastillo@unicesar.edu.co  |
| Rubén Darío Ariza Valencia  | 1065840837 | rdariza@unicesar.edu.co     |

**Universidad Popular del Cesar — Facultad de Ingeniería de Sistemas**
