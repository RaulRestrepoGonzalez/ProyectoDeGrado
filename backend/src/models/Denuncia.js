const mongoose = require('mongoose');

const denunciaSchema = new mongoose.Schema(
  {
    publicacion: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Publicacion',
      required: true,
    },
    denunciante: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Usuario',
      required: true,
    },
    motivo: {
      type: String,
      required: [true, 'Debe especificar el motivo de la denuncia.'],
      enum: ['SPAM', 'OFENSIVO', 'ACOSO', 'FRAUDE', 'OTRO'],
    },
    comentariosOpcionales: {
      type: String,
      maxlength: 250,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Denuncia', denunciaSchema);
