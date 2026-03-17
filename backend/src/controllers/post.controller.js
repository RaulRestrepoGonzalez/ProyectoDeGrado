const Publicacion = require('../models/Publicacion');
const Comentario = require('../models/Comentario');
const Denuncia = require('../models/Denuncia');
const Usuario = require('../models/Usuario');

// =======================
//   PUBLICACIONES / FEED
// =======================

exports.crearPublicacion = async (req, res, next) => {
  try {
    const { contenido, tipoPost, vacantes, precio } = req.body;
    const userId = req.user.id;

    // ── Token Gate para compañia e independiente ──────────────────────────────
    const autor = await Usuario.findById(userId).select('rol tokens publicacionesGratuitas');
    if (autor && ['compañia', 'independiente'].includes(autor.rol)) {
      if (autor.publicacionesGratuitas < 3) {
        // Consume una publicación gratuita
        await Usuario.findByIdAndUpdate(userId, { $inc: { publicacionesGratuitas: 1 } });
      } else if (autor.tokens <= 0) {
        // Sin tokens → rechazar con código especial para que Flutter muestre la alerta
        return res.status(402).json({
          needsTokens: true,
          message: 'Has superado las 3 publicaciones gratuitas. Recarga tokens en tu Cartera para seguir publicando.',
        });
      } else {
        // Descontar token
        await Usuario.findByIdAndUpdate(userId, { $inc: { tokens: -1 } });
      }
    }
    // ─────────────────────────────────────────────────────────────────────────

    // ── Procesar archivos subidos con metadatos detallados ───────────────────────
    const evidencias = [];
    
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        // Detectar tipo de archivo por extensión
        const fileExtension = file.originalname.toLowerCase().split('.').pop();
        let tipoArchivo = 'IMAGEN';
        
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(fileExtension)) {
          tipoArchivo = 'IMAGEN';
        } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].includes(fileExtension)) {
          tipoArchivo = 'VIDEO';
        } else if (['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'].includes(fileExtension)) {
          tipoArchivo = 'AUDIO';
          
          // Validar duración del audio (máximo 60 segundos)
          if (file.duration && file.duration > 60) {
            return res.status(400).json({
              message: 'Los audios no pueden superar los 60 segundos',
              maxDuration: 60,
              actualDuration: file.duration,
            });
          }
        }

        // Crear objeto de evidencia con metadatos completos
        const evidencia = {
          url: file.path, // URL de Cloudinary
          tipo: tipoArchivo,
          nombreOriginal: file.originalname,
          tamaño: file.size || 0,
          formato: fileExtension,
          duracion: file.duration || null,
          dimensiones: {
            ancho: file.width || null,
            alto: file.height || null,
          },
          thumbnail: file.thumbnail || null,
          publicId: file.public_id || file.filename,
          orden: evidencias.length,
        };

        evidencias.push(evidencia);
      }
    }

    // ── Crear publicación con todos los datos ───────────────────────────────────
    const nuevaPublicacion = new Publicacion({
      autor: userId,
      contenido,
      tipoPost: tipoPost || 'GENERAL',
      vacantes: vacantes ? Number(vacantes) : null,
      precio: precio ? Number(precio) : null,
      evidencias,
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
    });

    await nuevaPublicacion.save();

    // ── Poblar datos del autor para respuesta ───────────────────────────────────
    await nuevaPublicacion.populate('autor', 'nombre username avatar email rol');

    res.status(201).json({
      message: 'Publicación creada exitosamente',
      publicacion: nuevaPublicacion,
    });
  } catch (error) {
    next(error);
  }
};

exports.obtenerFeed = async (req, res, next) => {
  try {
    const userId = req.user.id;

    // Obtener publicaciones excluyendo las que el usuario solicitante haya bloqueado
    const publicaciones = await Publicacion.find({
      bloqueadaPor: { $ne: userId },
    })
      .sort({ createdAt: -1 })
      .populate('autor', 'nombre rol email')
      .lean();

    // Mapear interacciones para saber si el usuario actual ya dio like o favorito
    const feedFormateado = publicaciones.map((pub) => {
      const hasLiked = pub.likes.some((id) => id.toString() === userId.toString());
      const hasFavorited = pub.favoritos.some((id) => id.toString() === userId.toString());

      // Simplificar evidencias para el frontend (solo URLs) Pero mantenemos el tipo principal
      const evidenciasUrls = pub.evidencias.map(e => e.url);

      return {
        ...pub,
        evidencias: evidenciasUrls,
        tipoEvidencia: pub.tipoEvidenciaPrincipal,
        likesCount: pub.likes.length,
        comentariosCount: pub.comentarios.length,
        hasLiked,
        hasFavorited,
      };
    });

    res.status(200).json({
      status: 'success',
      data: feedFormateado,
    });
  } catch (error) {
    next(error);
  }
};

exports.obtenerDetallePublicacion = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const publicacion = await Publicacion.findById(id)
      .populate('autor', 'nombre rol')
      .populate({
        path: 'comentarios',
        populate: { path: 'autor', select: 'nombre rol' },
        options: { sort: { createdAt: 1 } },
      })
      .lean();

    if (!publicacion) {
      return res.status(404).json({ message: 'Publicación no encontrada' });
    }

    const hasLiked = publicacion.likes.some((uid) => uid.toString() === userId.toString());
    const hasFavorited = publicacion.favoritos.some((uid) => uid.toString() === userId.toString());

    res.status(200).json({
      status: 'success',
      data: {
        ...publicacion,
        likesCount: publicacion.likes.length,
        comentariosCount: publicacion.comentarios.length,
        hasLiked,
        hasFavorited,
      },
    });
  } catch (error) {
    next(error);
  }
};

// =======================
//     INTERACCIONES
// =======================

exports.toggleLike = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const publicacion = await Publicacion.findById(id);
    if (!publicacion) {
      return res.status(404).json({ message: 'Publicación no encontrada' });
    }

    const index = publicacion.likes.indexOf(userId);
    let hasLiked = false;

    if (index === -1) {
      publicacion.likes.push(userId);
      hasLiked = true;
    } else {
      publicacion.likes.splice(index, 1);
      hasLiked = false;
    }

    await publicacion.save();

    res.status(200).json({
      status: 'success',
      hasLiked,
      likesCount: publicacion.likes.length,
    });
  } catch (error) {
    next(error);
  }
};

exports.toggleFavorito = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const publicacion = await Publicacion.findById(id);
    if (!publicacion) {
      return res.status(404).json({ message: 'Publicación no encontrada' });
    }

    const index = publicacion.favoritos.indexOf(userId);
    let hasFavorited = false;

    if (index === -1) {
      publicacion.favoritos.push(userId);
      hasFavorited = true;
    } else {
      publicacion.favoritos.splice(index, 1);
      hasFavorited = false;
    }

    await publicacion.save();

    res.status(200).json({
      status: 'success',
      hasFavorited,
    });
  } catch (error) {
    next(error);
  }
};

exports.comentar = async (req, res, next) => {
  try {
    const { id } = req.params; // ID de publicación
    const { texto } = req.body;
    const userId = req.user.id;

    const publicacion = await Publicacion.findById(id);
    if (!publicacion) {
      return res.status(404).json({ message: 'Publicación no encontrada' });
    }

    const nuevoComentario = await Comentario.create({
      publicacion: id,
      autor: userId,
      texto,
    });

    // Guardar referencia en el array de la publicacion
    publicacion.comentarios.push(nuevoComentario._id);
    await publicacion.save();

    const comentarioPopulada = await Comentario.findById(nuevoComentario._id).populate(
      'autor',
      'nombre rol'
    );

    res.status(201).json({
      status: 'success',
      data: comentarioPopulada,
    });
  } catch (error) {
    next(error);
  }
};

// =======================
//      MODERACIÓN
// =======================

exports.bloquearPublicacion = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const publicacion = await Publicacion.findById(id);
    if (!publicacion) {
      return res.status(404).json({ message: 'Publicación no encontrada' });
    }

    if (!publicacion.bloqueadaPor.includes(userId)) {
      publicacion.bloqueadaPor.push(userId);
      await publicacion.save();
    }

    res.status(200).json({
      status: 'success',
      message: 'Publicación ocultada de tu feed.',
    });
  } catch (error) {
    next(error);
  }
};

exports.denunciarPublicacion = async (req, res, next) => {
  try {
    const { id } = req.params; // id post
    const { motivo, comentariosOpcionales } = req.body;
    const userId = req.user.id;

    // Verificar si ya existe reporte de este usuario para esta pub
    const existeDenuncia = await Denuncia.findOne({
      publicacion: id,
      denunciante: userId,
    });

    if (existeDenuncia) {
      return res.status(400).json({ message: 'Ya has denunciado esta publicación.' });
    }

    await Denuncia.create({
      publicacion: id,
      denunciante: userId,
      motivo,
      comentariosOpcionales,
    });

    res.status(201).json({
      status: 'success',
      message: 'Denuncia enviada y registrada correctamente.',
    });
  } catch (error) {
    next(error);
  }
};

// =======================
//   BÚSQUEDA AVANZADA
// =======================

exports.buscarPorTipo = async (req, res, next) => {
  try {
    const { tipo } = req.params;
    const userId = req.user.id;

    const publicaciones = await Publicacion.find({
      tipoPost: tipo.toUpperCase(),
      estado: 'ACTIVA',
      bloqueadaPor: { $ne: userId }
    })
    .sort({ createdAt: -1 })
    .populate('autor', 'nombre rol email');

    res.status(200).json({
      status: 'success',
      results: publicaciones.length,
      data: publicaciones
    });
  } catch (error) {
    next(error);
  }
};

exports.buscarConMultimedia = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const publicaciones = await Publicacion.find({
      tieneEvidencias: true,
      estado: 'ACTIVA',
      bloqueadaPor: { $ne: userId }
    })
    .sort({ createdAt: -1 })
    .populate('autor', 'nombre rol email');

    res.status(200).json({
      status: 'success',
      results: publicaciones.length,
      data: publicaciones
    });
  } catch (error) {
    next(error);
  }
};
