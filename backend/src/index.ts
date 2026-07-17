import dotenv from 'dotenv';
dotenv.config();

import { createServer } from 'http';
import app from './app';
import { connectDB } from './config/db';
import { initSocket } from './services/socket';
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    // Connect to MongoDB first
    await connectDB();

    // Create HTTP server from Express app
    const server = createServer(app);

    // Initialize Socket.io
    initSocket(server);

    // Start Server
    server.listen(PORT as number, '0.0.0.0', () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();
