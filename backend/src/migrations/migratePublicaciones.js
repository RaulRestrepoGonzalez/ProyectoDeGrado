const mongoose = require('mongoose');
const Publicacion = require('../src/models/Publicacion');
const database = require('../src/config/database');

// Script de migración para actualizar el modelo de Publicacion
async function migrarBaseDeDatos() {
  try {
    console.log('🔄 Iniciando migración de la base de datos...');
    
    // Conectar a la base de datos
    await database.connect();
    console.log('✅ Conectado a la base de datos');

    // Obtener todas las publicaciones existentes
    const publicaciones = await Publicacion.find({});
    console.log(`📊 Encontradas ${publicaciones.length} publicaciones para migrar`);

    let migradas = 0;
    let errores = 0;

    for (const pub of publicaciones) {
      try {
        // Verificar si ya tiene el nuevo formato
        if (pub.evidencias.length > 0 && typeof pub.evidencias[0] === 'object' && pub.evidencias[0].url) {
          console.log(`⏭️  Publicación ${pub._id} ya está en el nuevo formato`);
          continue;
        }

        // Migrar evidencias del formato antiguo al nuevo
        const evidenciasMigradas = [];
        let tipoEvidenciaPrincipal = 'TEXTO';

        if (pub.evidencias && pub.evidencias.length > 0) {
          for (let i = 0; i < pub.evidencias.length; i++) {
            const urlAntigua = pub.evidencias[i];
            const fileExtension = urlAntigua.split('.').pop().toLowerCase();
            let tipo = 'IMAGEN';

            // Detectar tipo por extensión
            if (['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(fileExtension)) {
              tipo = 'IMAGEN';
              if (tipoEvidenciaPrincipal === 'TEXTO') tipoEvidenciaPrincipal = 'IMAGEN';
            } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].includes(fileExtension)) {
              tipo = 'VIDEO';
              if (tipoEvidenciaPrincipal === 'TEXTO') tipoEvidenciaPrincipal = 'VIDEO';
            } else if (['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'].includes(fileExtension)) {
              tipo = 'AUDIO';
              if (tipoEvidenciaPrincipal === 'TEXTO') tipoEvidenciaPrincipal = 'AUDIO';
            }

            // Extraer nombre del archivo de la URL
            const nombreArchivo = urlAntigua.split('/').pop() || `archivo_${i + 1}.${fileExtension}`;

            evidenciasMigradas.push({
              url: urlAntigua,
              tipo,
              nombreOriginal: nombreArchivo,
              tamaño: 0, // No tenemos este dato en el formato antiguo
              formato: fileExtension,
              duracion: pub.duracionAudio || null,
              dimensiones: {
                ancho: null,
                alto: null,
              },
              thumbnail: null,
              publicId: nombreArchivo,
              orden: i,
            });
          }
        }

        // Actualizar la publicación con el nuevo formato
        await Publicacion.findByIdAndUpdate(pub._id, {
          $set: {
            evidencias: evidenciasMigradas,
            tipoEvidenciaPrincipal,
            tieneEvidencias: evidenciasMigradas.length > 0,
            totalEvidencias: evidenciasMigradas.length,
            estadisticas: {
              visualizaciones: 0,
              compartidos: 0,
              clicksEnEvidencias: 0,
            },
            estado: 'ACTIVA',
            privacidad: {
              tipo: 'PUBLICO',
              permitirComentarios: true,
              permitirCompartir: true,
            },
          },
          $unset: {
            tipoEvidencia: 1, // Eliminar campo antiguo
            duracionAudio: 1, // Eliminar campo antiguo
          }
        });

        console.log(`✅ Publicación ${pub._id} migrada exitosamente`);
        migradas++;
      } catch (error) {
        console.error(`❌ Error migrando publicación ${pub._id}:`, error.message);
        errores++;
      }
    }

    console.log(`🎉 Migración completada:`);
    console.log(`   ✅ Migradas: ${migradas}`);
    console.log(`   ❌ Errores: ${errores}`);
    console.log(`   📊 Total: ${publicaciones.length}`);

    // Crear índices para mejor rendimiento
    console.log('🔧 Creando índices...');
    await Publicacion.createIndexes();
    console.log('✅ Índices creados exitosamente');

  } catch (error) {
    console.error('❌ Error en la migración:', error);
  } finally {
    // Cerrar conexión
    await mongoose.connection.close();
    console.log('🔌 Conexión cerrada');
  }
}

// Ejecutar la migración
if (require.main === module) {
  migrarBaseDeDatos();
}

module.exports = migrarBaseDeDatos;
