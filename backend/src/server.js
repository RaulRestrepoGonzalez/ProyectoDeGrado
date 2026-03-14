require('dotenv').config();

const http = require('http');
const app = require('./app');
const { connectDB } = require('./config/database');
const { initSocket } = require('./config/socket');
const { validateEnv } = require('./config/env');

const PORT = process.env.PORT || 3000;

(async () => {
  try {
    validateEnv();

    await connectDB();

    const server = http.createServer(app);
    initSocket(server);

    server.listen(PORT, '0.0.0.0', () => {
      console.log(`Backend escuchando en http://0.0.0.0:${PORT}`);
    });
  } catch (error) {
    console.error('Error al iniciar el servidor:', error);
    process.exit(1);
  }
})();
