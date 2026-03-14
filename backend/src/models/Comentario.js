const mongoose = require('mongoose');

const comentarioSchema = new mongoose.Schema(
  {
    publicacion: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Publicacion',
      required: true,
    },
    autor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Usuario',
      required: true,
    },
    texto: {
      type: String,
      required: [true, 'El comentario no puede estar vacío'],
      maxlength: 500,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Comentario', comentarioSchema);
