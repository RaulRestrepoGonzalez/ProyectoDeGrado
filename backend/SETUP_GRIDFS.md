# 📦 Almacenamiento con MongoDB GridFS

## ¿Qué es GridFS?

**GridFS** es un mecanismo de MongoDB para almacenar archivos grandes (> 16 MB) directamente en la base de datos. En lugar de guardar archivos en el servidor o en servicios externos como Cloudinary, **los archivos se guardan en MongoDB Atlas**.

### Ventajas

✅ **Gratis** - No requiere servicios adicionales  
✅ **Integrated** - Ya tienes MongoDB Atlas configurado  
✅ **Persistent** - Los archivos se guardan permanentemente en Atlas  
✅ **Escalable** - MongoDB maneja automáticamente el almacenamiento  
✅ **No requiere tarjeta de crédito** - A diferencia de Cloudinary o AWS

## Cómo funciona

1. **Subida**: El archivo se envía como multipart/form-data
2. **Almacenamiento**: Se guarda en la colección `fs.files` de MongoDB
3. **Descarga**: Se recupera mediante `/api/files/download/:fileId`

## Flujo de una publicación con video

```
┌─────────────────────────────────────────────────────────┐
│ Flutter App                                              │
├─────────────────────────────────────────────────────────┤
│ 1. Usuario selecciona video en galería                  │
│ 2. Envía POST /posts con archivo                        │
└────────────┬──────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│ Render Backend (Node.js + Express)                       │
├─────────────────────────────────────────────────────────┤
│ 1. Recibe archivo en memoria (req.file.buffer)          │
│ 2. Inicializa uploadStream en GridFS                    │
│ 3. Escribe buffer en GridFS                             │
│ 4. Devuelve URL: /api/files/download/{fileId}           │
└────────────┬──────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│ MongoDB Atlas (GridFS)                                   │
├─────────────────────────────────────────────────────────┤
│ ✓ Archivo guardado en fs.files                          │
│ ✓ Chunks en fs.chunks si es > 255KB                     │
└────────────┬──────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│ Flutter App (Reproducción)                               │
├─────────────────────────────────────────────────────────┤
│ 1. VideoPlayerWidget recibe URL de GridFS               │
│ 2. ExoPlayer descarga desde /api/files/download/{id}    │
│ 3. Reproduce el video streamuendo desde MongoDB         │
└─────────────────────────────────────────────────────────┘
```

## Límites de GridFS

| Parámetro | Límite | Nota |
|-----------|--------|------|
| Tamaño máximo archivo | 100 MB | Configurable en multer |
| Documentos fs.files | Ilimitados | Depende cuota MongoDB |
| Tamaño total almacenamiento | Depende de plan MongoDB Atlas | Plan gratuito: 512 MB |

## Configuración en Render

**No necesitas hacer nada especial**. GridFS funciona automáticamente cuando:

1. `MONGODB_URI` está configurada en Render
2. El backend está corriendo
3. El middleware de upload está activo

## Debugging: Ver archivos en GridFS

```bash
# En MongoDB Atlas, ve a:
# 1. Haz clic en "Browse Collections"
# 2. Selecciona tu base de datos (soundupar_db)
# 3. Busca la colección "fs.files"
# 
# Deberías ver documentos como:
# {
#   "_id": ObjectId("..."),
#   "length": 52428800,           # Tamaño en bytes (50 MB)
#   "uploadDate": ISODate("..."),
#   "filename": "Screen_Recording_20260611_181127.mp4",
#   "metadata": {
#     "originalname": "Screen_Recording_20260611_181127.mp4",
#     "mimetype": "video/mp4",
#     "size": 52428800,
#     "uploadedAt": ISODate("...")
#   }
# }
```

## Optimización de velocidad

Para acelerar las descargas, el endpoint `/api/files/download/:fileId` implementa streaming:

```javascript
// El archivo se streamea directamente sin cargar todo en memoria
const stream = gridFSBucket.openDownloadStream(fileId);
stream.pipe(res);  // ← Eficiente para archivos grandes
```

## Eliminación de archivos

Cuando se elimina una publicación, se debe eliminar también el archivo de GridFS:

```javascript
// En el controlador de posts:
await gridFSBucket.delete(new ObjectId(fileId));
```

## Migración desde Cloudinary (si lo usabas)

Si antes usabas Cloudinary:

1. **Cloudinary URL**: `https://res.cloudinary.com/xyz/video/upload/v123/file.mp4`
2. **GridFS URL**: `https://proyectodegrado-90yf.onrender.com/api/files/download/60d5ec49c1234567890abcde`

Los archivos nuevos se guardarán automáticamente en GridFS. Los archivos antiguos de Cloudinary seguirán siendo accesibles si todavía están alojados ahí.

## Troubleshooting

### "Cannot find module 'mongodb'"
```bash
npm install mongodb
```

### "GridFS no disponible" (error)
- Verifica que `MONGODB_URI` esté configurada en Render
- Revisa los logs en Render para ver si MongoDB conectó correctamente
- Reinicia el servicio en Render

### El video no se carga después de subirse
- Verifica que el `fileId` se devolvió correctamente en la respuesta de POST /posts
- Verifica que el URL está en formato correcto: `/api/files/download/{id}`
- Intenta abrir la URL directamente en un navegador para descargar

### GridFS lleno (límite de 512 MB)
Opciones:
1. Subir archivos más pequeños (comprimir videos)
2. Eliminar publicaciones antiguas
3. Upgrade a plan de pago en MongoDB Atlas
4. Migrar a AWS S3 u otra solución si necesitas más espacio

## Próximos pasos

1. ✅ GridFS está configurado
2. ✅ Rutas de descarga están listas
3. 📍 **Ahora**: Prueba subiendo un video desde la app
4. 📍 **Si funciona**: Celebra 🎉
5. 📍 **Si no funciona**: Revisa los logs en Render
