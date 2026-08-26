const errorHandler = (err, req, res, _next) => {
  const status = err.status || 500;
  let message = err.message || 'Error interno del servidor';

  // Si es un error de conexión de BD o de red con la API, devolvemos mensaje amigable
  if (status === 503) {
    message = 'Servicio temporalmente no disponible. Verifica tu conexión de red y vuelve a intentar.';
  }

  // Si es un error 500 en producción, ofuscamos el mensaje real para no filtrar info de BD
  // Mostrar mensajes de límite de tamaño de archivo de forma clara
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({
      status: 'error',
      message: 'El archivo es demasiado grande. El límite es 1 GB por archivo.',
    });
  }

  if (err.code === 'VIDEO_DURATION_EXCEEDED') {
    return res.status(413).json({
      status: 'error',
      message: err.message || 'El video excede la duración máxima permitida.',
    });
  }

  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    return res.status(400).json({
      status: 'error',
      message: 'Número máximo de archivos excedido. Solo se permiten hasta 5 archivos.',
    });
  }

  if (process.env.NODE_ENV === 'production' && status === 500) {
    message = 'Algo salió mal en nuestros servidores.';
  } else if (process.env.NODE_ENV !== 'production') {
    console.error(err);
  }

  res.status(status).json({
    status: 'error',
    message,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack }),
  });
};

const notFoundHandler = (req, res) => {
  res.status(404).json({
    status: 'fail',
    message: `No se encontró ${req.originalUrl}`,
  });
};

module.exports = { errorHandler, notFoundHandler };
