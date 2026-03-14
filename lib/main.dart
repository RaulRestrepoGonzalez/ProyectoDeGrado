import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/constants/app_constants.dart';
import 'core/network/base_url_resolver.dart';
import 'presentation/router/app_router.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga variables de entorno desde .env (opcional)
  await dotenv.load(fileName: ".env");

  // Resolver dinámicamente la URL del backend si no está en .env
  try {
    final resolved = await resolveBaseUrl();
    if (resolved != null && resolved.isNotEmpty) {
      dotenv.env['BASE_URL'] = resolved;
    }
  } catch (_) {
    // ignorar; se usará el valor por defecto en tiempo de ejecución
  }

  // La inicialización del estado de autenticación ahora se hace en SplashScreen
  // para poder mostrar el progreso visualmente (UI/UX).

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
