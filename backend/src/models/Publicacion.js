const mongoose = require('mongoose');

const evidenciaSchema = new mongoose.Schema({
  url: {
    type: String,
    required: true,
  },
  tipo: {
    type: String,
    enum: ['IMAGEN', 'VIDEO', 'AUDIO'],
    required: true,
  },
  nombreOriginal: {
    type: String,
    required: true,
  },
  tamaño: {
    type: Number, // en bytes
    required: true,
  },
  formato: {
    type: String,
    required: true,
  },
  duracion: {
    type: Number, // en segundos (para videos y audios)
    default: null,
  },
  dimensiones: {
    ancho: {
      type: Number,
      default: null,
    },
    alto: {
      type: Number,
      default: null,
    },
  },
  thumbnail: {
    type: String, // URL del thumbnail para videos
    default: null,
  },
  publicId: {
    type: String, // ID de Cloudinary para gestión
    required: true,
  },
  orden: {
    type: Number,
    default: 0,
  },
});

const publicacionSchema = new mongoose.Schema(
  {
    autor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Usuario',
      required: true,
      index: true, // Para búsquedas por autor
    },
    contenido: {
      type: String,
      required: [true, 'El contenido de la publicación no puede estar vacío'],
      maxlength: 1000,
      trim: true,
    },
    tipoPost: {
      type: String,
      enum: ['BUSCANDO_PERSONAL', 'BUSCANDO_OPORTUNIDAD', 'GENERAL'],
      default: 'GENERAL',
      index: true, // Para filtrar por tipo
    },
    vacantes: {
      type: Number,
      default: null,
      min: [1, 'Debe haber al menos una vacante'],
    },
    precio: {
      type: Number,
      default: null,
      min: [0, 'El precio no puede ser negativo'],
    },
    evidencias: [evidenciaSchema],
    tipoEvidenciaPrincipal: {
      type: String,
      enum: ['IMAGEN', 'VIDEO', 'AUDIO', 'TEXTO'],
      default: 'TEXTO',
    },
    tieneEvidencias: {
      type: Boolean,
      default: false,
      index: true, // Para filtrar publicaciones con/sin contenido multimedia
    },
    totalEvidencias: {
      type: Number,
      default: 0,
      min: 0,
      max: [5, 'Máximo 5 archivos permitidos'],
    },
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
    comentarios: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Comentario',
      },
    ],
    // Estadísticas y métricas
    estadisticas: {
      visualizaciones: {
        type: Number,
        default: 0,
        min: 0,
      },
      compartidos: {
        type: Number,
        default: 0,
        min: 0,
      },
      clicksEnEvidencias: {
        type: Number,
        default: 0,
        min: 0,
      },
    },
    // Estado de la publicación
    estado: {
      type: String,
      enum: ['ACTIVA', 'PAUSADA', 'ELIMINADA', 'REPORTADA'],
      default: 'ACTIVA',
      index: true,
    },
    // Ubicación (opcional)
    ubicacion: {
      tipo: {
        type: String,
        enum: ['CIUDAD', 'REGION', 'VIRTUAL'],
      },
      nombre: String,
      coordenadas: {
        lat: Number,
        lng: Number,
      },
    },
    // Etiquetas para búsquedas
    etiquetas: [{
      type: String,
      trim: true,
      lowercase: true,
      maxlength: 20,
    }],
    // Configuración de privacidad
    privacidad: {
      tipo: {
        type: String,
        enum: ['PUBLICO', 'AMIGOS', 'SOLO_YO'],
        default: 'PUBLICO',
      },
      permitirComentarios: {
        type: Boolean,
        default: true,
      },
      permitirCompartir: {
        type: Boolean,
        default: true,
      },
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Índices compuestos para mejor rendimiento
publicacionSchema.index({ autor: 1, createdAt: -1 });
publicacionSchema.index({ tipoPost: 1, estado: 1, createdAt: -1 });
publicacionSchema.index({ tieneEvidencias: 1, tipoEvidenciaPrincipal: 1 });
publicacionSchema.index({ etiquetas: 1 });
publicacionSchema.index({ 'ubicacion.tipo': 1, 'ubicacion.nombre': 1 });

// Virtuals para datos calculados
publicacionSchema.virtual('totalLikes').get(function() {
  return this.likes ? this.likes.length : 0;
});

publicacionSchema.virtual('totalFavoritos').get(function() {
  return this.favoritos ? this.favoritos.length : 0;
});

publicacionSchema.virtual('totalComentarios').get(function() {
  return this.comentarios ? this.comentarios.length : 0;
});

publicacionSchema.virtual('tieneContenidoMultimedia').get(function() {
  return this.evidencias && this.evidencias.length > 0;
});

// Middleware para actualizar campos derivados
publicacionSchema.pre('save', function(next) {
  // Actualizar tipoEvidenciaPrincipal basado en las evidencias
  if (this.evidencias && this.evidencias.length > 0) {
    this.tieneEvidencias = true;
    this.totalEvidencias = this.evidencias.length;
    
    // Determinar el tipo principal basado en el contenido
    const tipos = this.evidencias.map(e => e.tipo);
    const tiposUnicos = [...new Set(tipos)];
    
    if (tiposUnicos.length === 1) {
      this.tipoEvidenciaPrincipal = tiposUnicos[0];
    } else {
      this.tipoEvidenciaPrincipal = 'MIXTO';
    }
  } else {
    this.tieneEvidencias = false;
    this.totalEvidencias = 0;
    this.tipoEvidenciaPrincipal = 'TEXTO';
  }
  
  next();
});

// Métodos de instancia
publicacionSchema.methods.agregarEvidencia = function(evidencia) {
  if (this.evidencias.length >= 5) {
    throw new Error('Máximo 5 archivos permitidos');
  }
  this.evidencias.push(evidencia);
  return this.save();
};

publicacionSchema.methods.eliminarEvidencia = function(evidenciaId) {
  this.evidencias = this.evidencias.filter(e => e._id.toString() !== evidenciaId.toString());
  return this.save();
};

publicacionSchema.methods.incrementarVisualizacion = function() {
  this.estadisticas.visualizaciones += 1;
  return this.save();
};

// Métodos estáticos
publicacionSchema.statics.encontrarPorTipo = function(tipo, limit = 10) {
  return this.find({ tipoEvidenciaPrincipal: tipo, estado: 'ACTIVA' })
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate('autor', 'nombre username avatar');
};

publicacionSchema.statics.buscarConEvidencias = function(limit = 20) {
  return this.find({ 
    tieneEvidencias: true, 
    estado: 'ACTIVA' 
  })
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate('autor', 'nombre username avatar');
};

// Validaciones personalizadas
publicacionSchema.pre('validate', function(next) {
  // Validar que las publicaciones de empleo tengan vacantes
  if (this.tipoPost === 'BUSCANDO_PERSONAL' && !this.vacantes) {
    this.invalidate('vacantes', 'Las publicaciones de empleo deben especificar el número de vacantes');
  }
  
  // Validar que las publicaciones de oportunidad tengan precio
  if (this.tipoPost === 'BUSCANDO_OPORTUNIDAD' && this.precio === null) {
    this.invalidate('precio', 'Las publicaciones de oportunidad deben especificar un precio');
  }
  
  next();
});

module.exports = mongoose.model('Publicacion', publicacionSchema);
