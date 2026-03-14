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
If you run Mongo on another machine in the local network you can either set
`MONGODB_URI` to a full connection string (recommended), or provide
`MONGO_HOST` or `MONGO_HOSTS` (comma-separated list) with the host(s).

Examples:

 - `MONGODB_URI=mongodb+srv://<user>:<pass>@cluster0.mongodb.net/musicapp_valledupar`
 - `MONGO_HOST=192.168.1.50`
 - `MONGO_HOSTS=192.168.1.50,192.168.1.51`

The server will try candidates and perform several retries with backoff before exiting.
