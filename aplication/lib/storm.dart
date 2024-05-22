import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();

void callbackDispatcher() {
  Workmanager workmanager = Workmanager();
  workmanager.executeTask((task, inputData) async {
    switch (task) {
      case "periodicTask":
        _executarScript();
        _jogoMaisProximo();
        break;
      default:
        break;
    }
    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Desenvolvido por: Kiri'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

  String estadoMercado = 'Fechado!';
  String horaAlarme = '00:00';
  String estadoAlarme = 'Desativado';
  String estadoNotificacao = 'Desativado';
  String mudarEstadoAlarme = 'Ativar Alarme!';
  String mudarEstadoNotificacao = 'Ativar Notificação!';
  String dataFechamento = 'Terça-Feira - 22/07';
  String horaFechamento = '00:00';
class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    super.initState();
    _startPeriodicTask();
  }

  void _startPeriodicTask() {
    Workmanager().registerPeriodicTask(
      "periodicTask",
      "periodicTask",
      initialDelay: const Duration(minutes: 10),
    );
  }

  Future<void> _botaoHorario() async {
    final TimeOfDay? horarioSelecionado = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (horarioSelecionado != null) {
      setState(() {
        horaAlarme = horarioSelecionado.format(context);
      });
    }
  }

  void _abreManual() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Como Funciona:'),
          content: const Text(
              'O app te enviará notificações e alarmes para te lembrar de escalar o time no Cartola. Ao deixar a notificação/alarme ativada o app irá automaticamente te lembrar uma hora antes de fechar o mercado, você pode ajustar esse horário manualmente, mas a cada rodada o horário é resetado para uma hora antes do fechamento do mercado.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Ok, Entendi!'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Chamar Kiri no Zap'),
            ),
          ],
        );
      },
    );
  }

  void _botaoAlarme() {
    setState(() {
      if (estadoAlarme == 'Desativado') {
        estadoAlarme = 'Ativado';
        mudarEstadoAlarme = 'Desativar Alarme!';
      } else {
        estadoAlarme = 'Desativado';
        mudarEstadoAlarme = 'Ativar Alarme!';
      }
    });
  }

  void _botaoNotificacao() {
    setState(() {
      if (estadoNotificacao == 'Desativado') {
        estadoNotificacao = 'Ativado';
        mudarEstadoNotificacao = 'Desativar Notificação!';
      } else {
        estadoNotificacao = 'Desativado';
        mudarEstadoNotificacao = 'Ativar Notificação!';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 400,
              height: 140,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alarme: $estadoAlarme',
                    style: const TextStyle(fontSize: 20),
                    textWidthBasis: TextWidthBasis.parent,
                  ),
                  Text(
                    'Notificação: $estadoNotificacao',
                    style: const TextStyle(fontSize: 20),
                    textWidthBasis: TextWidthBasis.parent,
                  ),
                  Text(
                    'Horário de Alarme/Notificação: $horaAlarme',
                    style: const TextStyle(fontSize: 18),
                    textWidthBasis: TextWidthBasis.parent,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 400,
              height: 80,
              child: Column(
                children: [
                  Text(
                    'Dia de Fechamento: $dataFechamento',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Horário de Fechamento: $horaFechamento',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const Text(
              'Estado do Mercado: ',
            ),
            Text(
              estadoMercado,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _botaoAlarme,
              child: Text(mudarEstadoAlarme),
            ),
            ElevatedButton(
              onPressed: _botaoNotificacao,
              child: Text(mudarEstadoNotificacao),
            ),
            ElevatedButton(
              onPressed: _botaoHorario,
              child: const Text('Alterar Hora do Alarme/Notificação'),
            ),
            ElevatedButton(
              onPressed: _abreManual,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Manual'),
                  SizedBox(width: 10),
                  Icon(Icons.help),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _jogoMaisProximo() async {
  try {
    final file = File('jogos.json');
    String jsonString = await file.readAsString();
    final jogos = json.decode(jsonString);
    if (jogos.isNotEmpty) {
      final data = jogos[0]['data'];
      dataFechamento = data.substring(0, 10);
      horaFechamento = data.substring(11, 16);
    } else {
      mudarEstadoAlarme = 'HAHA';
    }
  } catch (e) {
    mudarEstadoAlarme = 'Erro ao obter informações!';
  }
}

Future<void> _executarScript() async {
  try {
    final processResult = await Process.run('node', ['teste.js']);
    if (processResult.exitCode != 0) {
      throw Exception('Erro ao executar o script');
    }

    NotificationDetails? platformChannelSpecifics;
    await flutterLocalNotificationsPlugin.show(
        0, 'Título da Notificação', 'Corpo da Notificação', platformChannelSpecifics,
        payload: 'item x');
  } catch (e) {
    throw Exception('Erro ao executar o script');
  }
}
