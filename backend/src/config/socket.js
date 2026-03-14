const { Server } = require('socket.io');

let io;

function initSocket(server) {
  io = new Server(server, {
    cors: {
      origin: process.env.CLIENT_ORIGIN || '*',
      methods: ['GET', 'POST'],
    },
  });

  io.on('connection', (socket) => {
    console.log('Nuevo cliente Socket.IO conectado:', socket.id);

    socket.on('join-room', (room) => {
      socket.join(room);
    });

    socket.on('send-message', (payload) => {
      io.to(payload.room).emit('receive-message', payload);
    });

    socket.on('disconnect', () => {
      console.log('Cliente desconectado:', socket.id);
    });
  });

  return io;
}

function getIO() {
  if (!io) {
    throw new Error('Socket.IO no ha sido inicializado.');
  }
  return io;
}

module.exports = { initSocket, getIO };
