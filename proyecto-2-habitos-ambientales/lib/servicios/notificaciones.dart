import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificacionesHelper {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    // Configuración para Android usando el ícono por defecto de la app
    const AndroidInitializationSettings configuracionAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings configuracionGlobal = InitializationSettings(android: configuracionAndroid);

    await _plugin.initialize(configuracionGlobal);

    // Pedir permiso al usuario (necesario en Android 13+)
    _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // Función para mostrar la notificación
  static Future<void> mostrarRecordatorio() async {
    const AndroidNotificationDetails detallesAndroid = AndroidNotificationDetails(
      'canal_reto_verde', // ID del canal
      'Recordatorios Ecológicos', // Nombre del canal
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails detallesGenerales = NotificationDetails(android: detallesAndroid);

    await _plugin.show(
      0,
      '🌱 ¡No olvides tu Reto Verde!',
      'Entra para completar tus acciones ecológicas de hoy.',
      detallesGenerales,
    );
  }
}