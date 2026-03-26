const Publicacion = require('../models/Publicacion');
const Usuario = require('../models/Usuario');

exports.searchAll = async (req, res, next) => {
  try {
    const { q } = req.query;
    const regex = q ? new RegExp(q, 'i') : /.*/;

    // Buscar Usuarios (Perfiles)
    const users = await Usuario.find({
      $or: [
        { nombre: regex },
        { username: regex },
        { bio: regex }
      ]
    }).select('nombre username avatar rol fotoPerfil').limit(10);

    // Buscar Publicaciones (GENERAL)
    const posts = await Publicacion.find({
      tipoPost: 'GENERAL',
      estado: 'ACTIVA',
      $or: [
        { contenido: regex },
        { etiquetas: regex }
      ]
    })
    .populate('autor', 'nombre username avatar rol')
    .sort({ createdAt: -1 })
    .limit(10);

    // Buscar Convocatorias (BUSCANDO_PERSONAL o BUSCANDO_OPORTUNIDAD)
    const convocatorias = await Publicacion.find({
      tipoPost: { $in: ['BUSCANDO_PERSONAL', 'BUSCANDO_OPORTUNIDAD'] },
      estado: 'ACTIVA',
      $or: [
        { contenido: regex },
        { etiquetas: regex }
      ]
    })
    .populate('autor', 'nombre username avatar rol')
    .sort({ createdAt: -1 })
    .limit(10);

    // Formatear respuestas para consistencia (como hicimos en obtenerFeed)
    const formatPub = (pub) => {
      const evidenciasUrls = pub.evidencias ? pub.evidencias.map(e => e.url || e) : [];
      return {
        ...pub.toJSON(),
        evidencias: evidenciasUrls,
        tipoEvidencia: pub.tipoEvidenciaPrincipal,
        likesCount: pub.likes.length,
        comentariosCount: pub.comentarios.length,
      };
    };

    res.status(200).json({
      data: {
        posts: posts.map(formatPub),
        users,
        convocatorias: convocatorias.map(formatPub)
      }
    });
  } catch (error) {
    next(error);
  }
};
