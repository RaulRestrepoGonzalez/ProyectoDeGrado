const mongoose = require('mongoose');
const Usuario = require('../models/Usuario');
const Publicacion = require('../models/Publicacion');

exports.obtenerPerfilUsuario = async (req, res, next) => {
  try {
    const { id } = req.params;
    const currentUserId = req.user.id;

    const usuario = await Usuario.findById(id)
      .select('nombre rol email fotoPerfil telefono seguidores siguiendo')
      .populate('siguiendo', 'nombre fotoPerfil rol');
      
    if (!usuario) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    // 1. Pestaña "Publicaciones" (Posts del autor)
    const publicaciones = await Publicacion.find({
      autor: id,
      bloqueadaPor: { $ne: currentUserId },
    })
      .sort({ createdAt: -1 })
      .populate('autor', 'nombre rol fotoPerfil')
      .lean();

    // 2. Pestaña "Me Gusta" (Posts que le gustan al autor del perfil)
    const publicacionesGustadas = await Publicacion.find({
      likes: id,
      bloqueadaPor: { $ne: currentUserId },
    })
      .sort({ createdAt: -1 })
      .populate('autor', 'nombre rol fotoPerfil')
      .lean();

    const formatearPublicacion = (pub) => {
      const hasLiked = pub.likes.some((uid) => uid.toString() === currentUserId.toString());
      const hasFavorited = pub.favoritos.some((uid) => uid.toString() === currentUserId.toString());
      return {
        ...pub,
        likesCount: pub.likes.length,
        comentariosCount: pub.comentarios.length,
        hasLiked,
        hasFavorited,
      };
    };

    const isFollowing = usuario.seguidores.some(sId => sId.toString() === currentUserId.toString());

    res.status(200).json({
      status: 'success',
      data: {
        usuario: {
          _id: usuario._id,
          nombre: usuario.nombre,
          rol: usuario.rol,
          email: usuario.email,
          fotoPerfil: usuario.fotoPerfil,
          telefono: usuario.telefono,
          seguidoresCount: usuario.seguidores.length,
          siguiendoCount: usuario.siguiendo.length,
          isFollowing
        },
        siguiendo: usuario.siguiendo, // Para la pestaña "Siguiendo"
        publicacionesRecientes: publicaciones.map(formatearPublicacion),
        publicacionesGustadas: publicacionesGustadas.map(formatearPublicacion),
      },
    });
  } catch (error) {
    next(error);
  }
};

exports.toggleSeguirUsuario = async (req, res, next) => {
  try {
    const { id } = req.params; // ID del usuario a seguir/dejar de seguir
    const currentUserId = req.user.id; // Mi ID

    if (id === currentUserId) {
      return res.status(400).json({ message: 'No puedes seguirte a ti mismo' });
    }

    const targetUser = await Usuario.findById(id);
    const currentUserObj = await Usuario.findById(currentUserId);

    if (!targetUser || !currentUserObj) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    const indexFollower = targetUser.seguidores.indexOf(currentUserId);
    const indexFollowing = currentUserObj.siguiendo.indexOf(id);

    let isFollowing = false;

    // Si ya lo sigue, dejar de seguir
    if (indexFollower !== -1) {
      targetUser.seguidores.splice(indexFollower, 1);
      currentUserObj.siguiendo.splice(indexFollowing, 1);
      isFollowing = false;
    } else {
      // Si no lo sigue, seguir
      targetUser.seguidores.push(currentUserId);
      currentUserObj.siguiendo.push(id);
      isFollowing = true;
    }

    await Promise.all([targetUser.save(), currentUserObj.save()]);

    res.status(200).json({
      status: 'success',
      isFollowing,
      seguidoresCount: targetUser.seguidores.length,
    });
  } catch (error) {
    next(error);
  }
};

exports.actualizarPerfilUsuario = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { nombre, rol, telefono } = req.body;

    const updates = {};
    if (nombre) updates.nombre = nombre;
    if (rol) updates.rol = rol;
    if (telefono !== undefined) updates.telefono = telefono;

    // Si Multer capturó una imagen (fotoPerfil), laURL está en req.file.path (Cloudinary)
    if (req.file) {
      updates.fotoPerfil = req.file.path;
    }

    const usuario = await Usuario.findByIdAndUpdate(
      userId,
      { $set: updates },
      { new: true, runValidators: true }
    ).select('-password -refreshToken');

    if (!usuario) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    res.status(200).json({
      status: 'success',
      data: {
        usuario,
      },
      message: 'Perfil actualizado exitosamente',
    });
  } catch (error) {
    next(error);
  }
};
