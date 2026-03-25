# backend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Database configuration

The backend reads MongoDB connection from `MONGODB_URI` environment variable.

For free local development (recommended when no budget):
 - Install MongoDB Community Edition (Windows/macOS/Linux) or run Docker.
 - Use `MONGODB_URI=mongodb://localhost:27017/musicapp_valledupar`.
 - If you run the app in Docker compose, use `mongodb://mongodb:27017/musicapp_valledupar`.

If you run Mongo on another machine in the local network you can also set
`MONGODB_URI` to a full connection string, or provide `MONGO_HOST`/`MONGO_HOSTS`.

Examples:

 - `MONGODB_URI=mongodb://localhost:27017/musicapp_valledupar`
 - `MONGODB_URI=mongodb+srv://<user>:<pass>@cluster0.mongodb.net/musicapp_valledupar`
 - `MONGO_HOST=192.168.1.50`
 - `MONGO_HOSTS=192.168.1.50,192.168.1.51`

The server will try candidates and perform several retries with backoff before exiting.
