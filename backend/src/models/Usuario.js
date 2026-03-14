const mongoose = require('mongoose');

const usuarioSchema = new mongoose.Schema(
  {
    nombre: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
    },
    password: {
      type: String,
      required: true,
      select: false,
    },
    rol: {
      type: String,
      enum: ['compañia', 'independiente', 'artista'],
      default: 'artista',
    },
    fotoPerfil: {
      type: String,
      default: null,
    },
    telefono: {
      type: String,
      default: null,
    },
    tokens: {
      type: Number,
      default: 0,
    },
    publicacionesGratuitas: {
      type: Number,
      default: 0,
    },
    seguidores: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Usuario',
      },
    ],
    siguiendo: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Usuario',
      },
    ],
    refreshToken: {
      type: String,
      select: false,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Usuario', usuarioSchema);
