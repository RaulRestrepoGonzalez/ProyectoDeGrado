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

    // ── Procesar archivos subidos ───────────────────────────────────────────────
    const evidencias = [];
    let tipoEvidencia = 'IMAGEN'; // Por defecto
    let duracionAudio = null;
    
    if (req.files && req.files.length > 0) {
      req.files.forEach(file => {
        evidencias.push(file.path); // Cloudinary URL
        
        // Detectar tipo de archivo por extensión
        const fileExtension = file.path.toLowerCase().split('.').pop();
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(fileExtension)) {
          // Es imagen - mantener tipo actual
        } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].includes(fileExtension)) {
          if (tipoEvidencia === 'IMAGEN') tipoEvidencia = 'VIDEO';
        } else if (['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'].includes(fileExtension)) {
          tipoEvidencia = 'AUDIO';
          
          // Si es audio, verificar duración (Cloudinary proporciona metadata)
          if (file.duration) {
            duracionAudio = Math.min(file.duration, 60); // Máximo 60 segundos
          }
        }
        
        // Si hay múltiples tipos, es MIXTO
        if (evidencias.length > 1) {
          const hasImage = req.files.some(f => {
            const ext = f.path.toLowerCase().split('.').pop();
            return ['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext);
          });
          const hasVideo = req.files.some(f => {
            const ext = f.path.toLowerCase().split('.').pop();
            return ['mp4', 'mov', 'avi', 'mkv', 'webm'].includes(ext);
          });
          const hasAudio = req.files.some(f => {
            const ext = f.path.toLowerCase().split('.').pop();
            return ['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'].includes(ext);
          });
          
          if ((hasImage && hasVideo) || (hasImage && hasAudio) || (hasVideo && hasAudio)) {
            tipoEvidencia = 'MIXTO';
          }
        }
      });
    }

    const nuevaPublicacion = await Publicacion.create({
      autor: userId,
      contenido,
      tipoPost: tipoPost || 'GENERAL',
      vacantes: vacantes ? Number(vacantes) : null,
      precio: precio ? Number(precio) : null,
      evidencias,
      tipoEvidencia,
      duracionAudio,
    });

    const publicacionPopulada = await Publicacion.findById(nuevaPublicacion._id).populate(
      'autor',
      'nombre email rol'
    );

    res.status(201).json({
      status: 'success',
      data: publicacionPopulada,
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

      return {
        ...pub,
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
