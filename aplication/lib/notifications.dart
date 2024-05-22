import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';

// Define os objetos necessários
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final selectNotificationSubject = BehaviorSubject<String?>();

// Constante para identificar a notificação
const int id = 0;

// Função para inicializar o plugin de notificações locais
Future<void> initializeNotifications() async {
  // Configuração de inicialização do plugin
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
     
  // Callback para notificações em primeiro plano
  onDidReceiveNotificationResponse: (NotificationResponse response) async {
    final payload = response.payload;
    if (payload != null) {
      debugPrint('Notification payload: $payload');
    }
    // Emitir o payload da notificação para o fluxo de seleção de notificação
    selectNotificationSubject.add(payload);
  },
  // Callback para notificações em segundo plano
  onDidReceiveBackgroundNotificationResponse: (NotificationResponse response) async {
    final payload = response.payload;
    if (payload != null) {
      debugPrint('Background Notification payload: $payload');
    }
    // Emitir o payload da notificação para o fluxo de seleção de notificação
    selectNotificationSubject.add(payload);
  });
}

// Função para exibir uma notificação
Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your channel id',
    'your channel name',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    id,
    title,
    body,
    platformChannelSpecifics,
    payload: 'item x',
  );
}

// Função para agendar uma notificação
Future<void> scheduleNotification(
    String title, String body, DateTime scheduledDate) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your channel id',
    'your channel name',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(scheduledDate, tz.local),
    platformChannelSpecifics,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

// Função para cancelar uma notificação agendada
Future<void> cancelScheduledNotification() async {
  await flutterLocalNotificationsPlugin.cancel(id);
}

// Função para cancelar todas as notificações
Future<void> cancelAllNotifications() async {
  await flutterLocalNotificationsPlugin.cancelAll();
}
