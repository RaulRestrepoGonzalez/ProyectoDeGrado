# ⚠️ ARCHIVADO: Cloudinary (Ya no es necesario)

## 📦 Migración a MongoDB GridFS

**A partir de ahora, el proyecto usa MongoDB GridFS en lugar de Cloudinary.**

### ¿Por qué cambiar?

- ❌ Cloudinary requiere tarjeta de crédito (verificación de pago)
- ✅ GridFS es **gratis** y ya está integrado con MongoDB Atlas
- ✅ **No requiere servicios externos** adicionales
- ✅ **Más simple** - todo en la base de datos

## ¿Qué cambió?

**Antes (Cloudinary)**:
```
Video → Backend → Cloudinary Cloud → URL pública
```

**Ahora (GridFS)**:
```
Video → Backend → MongoDB Atlas (GridFS) → URL local
https://proyectodegrado-90yf.onrender.com/api/files/download/{fileId}
```

## Documentación nueva

👉 **Ve a [SETUP_GRIDFS.md](./SETUP_GRIDFS.md)** para entender cómo funciona ahora

## Si ya tenías Cloudinary configurado

Los archivos que subiste a Cloudinary seguirán siendo accesibles con sus URLs antiguas. Los nuevos archivos se guardarán automáticamente en GridFS mediante MongoDB Atlas.

## Para borrar la configuración de Cloudinary

Si tenías configuradas las variables en Render:
1. Ve a Settings → Environment
2. Elimina: `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`
3. Redeploy

**No es obligatorio eliminarlas**, simplemente no se usarán.
