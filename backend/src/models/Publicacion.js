const mongoose = require('mongoose');

const publicacionSchema = new mongoose.Schema(
  {
    autor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Usuario',
      required: true,
    },
    contenido: {
      type: String,
      required: [true, 'El contenido de la publicación no puede estar vacío'],
      maxlength: 1000,
    },
    tipoPost: {
      type: String,
      enum: ['BUSCANDO_PERSONAL', 'BUSCANDO_OPORTUNIDAD', 'GENERAL'],
      default: 'GENERAL',
    },
    vacantes: {
      type: Number,
      default: null,
    },
    precio: {
      type: Number,
      default: null,
    },
    evidencias: [
      {
        type: String, // URLs of the photos/videos from Cloudinary
      },
    ],
    likes: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Usuario',
      },
    ],
    favoritos: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Usuario',
      },
    ],
    bloqueadaPor: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Usuario',
      },
    ],
    // Los comentarios en lugar de incrustarlos de lleno se manejarán 
    // en una colección separada para escalabilidad, 
    // guardaremos solo los IDs si es necesario, o usaremos populate virtual.
    comentarios: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Comentario',
      },
    ],
  },
  {
    timestamps: true, // Agrega createdAt y updatedAt automáticamente
  }
);

module.exports = mongoose.model('Publicacion', publicacionSchema);
