const mongoose = require('mongoose');
const database = require('../src/config/database');

async function testDatabase() {
  try {
    console.log('🔧 Probando conexión a la base de datos...');
    
    // Conectar a la base de datos
    await database.connect();
    console.log('✅ Conexión exitosa');

    // Probar creación de índices
    const Publicacion = require('../src/models/Publicacion');
    console.log('🔧 Creando índices...');
    await Publicacion.createIndexes();
    console.log('✅ Índices creados exitosamente');

    // Probar inserción de una publicación de prueba
    console.log('🧪 Creando publicación de prueba...');
    const testPublicacion = new Publicacion({
      autor: new mongoose.Types.ObjectId(), // ID de prueba
      contenido: 'Esta es una publicación de prueba para verificar el nuevo modelo',
      tipoPost: 'GENERAL',
      evidencias: [{
        url: 'https://res.cloudinary.com/demo/image/upload/test.jpg',
        tipo: 'IMAGEN',
        nombreOriginal: 'test.jpg',
        tamaño: 1024000,
        formato: 'jpg',
        dimensiones: {
          ancho: 800,
          alto: 600
        },
        publicId: 'test_1234567890',
        orden: 0
      }],
      estadisticas: {
        visualizaciones: 0,
        compartidos: 0,
        clicksEnEvidencias: 0
      },
      estado: 'ACTIVA',
      privacidad: {
        tipo: 'PUBLICO',
        permitirComentarios: true,
        permitirCompartir: true
      }
    });

    // Validar el modelo
    await testPublicacion.validate();
    console.log('✅ Validación del modelo exitosa');

    // Probar métodos estáticos
    console.log('🧪 Probando métodos estáticos...');
    const postsConMultimedia = await Publicacion.buscarConEvidencias(1);
    console.log(`✅ Método buscarConEvidencias funcionando: ${postsConMultimedia.length} resultados`);

    // Probar virtuals
    console.log('🧪 Probando virtuals...');
    console.log(`   totalLikes: ${testPublicacion.totalLikes}`);
    console.log(`   totalFavoritos: ${testPublicacion.totalFavoritos}`);
    console.log(`   totalComentarios: ${testPublicacion.totalComentarios}`);
    console.log(`   tieneContenidoMultimedia: ${testPublicacion.tieneContenidoMultimedia}`);
    console.log(`   tipoEvidenciaPrincipal: ${testPublicacion.tipoEvidenciaPrincipal}`);

    console.log('🎉 Todas las pruebas pasaron exitosamente');

  } catch (error) {
    console.error('❌ Error en las pruebas:', error);
  } finally {
    // Cerrar conexión
    await mongoose.connection.close();
    console.log('🔌 Conexión cerrada');
  }
}

// Ejecutar pruebas
if (require.main === module) {
  testDatabase();
}

module.exports = testDatabase;
