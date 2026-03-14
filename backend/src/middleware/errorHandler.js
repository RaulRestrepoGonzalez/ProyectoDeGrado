const errorHandler = (err, req, res, next) => {
  const status = err.status || 500;
  let message = err.message || 'Error interno del servidor';

  // Si es un error 500 en producción, ofuscamos el mensaje real para no filtrar info de BD
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
