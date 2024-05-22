import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_js/flutter_js.dart';
import 'dart:typed_data';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();
JavascriptRuntime flutterJs = getJavascriptRuntime();

void _jogoMaisProximo() async {
  try {
    final jsonString = await rootBundle.loadString('assets/jogos.json');
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

void callbackDispatcher() {
  Workmanager workmanager = Workmanager();
  workmanager.executeTask((task, inputData) async {
    switch (task) {
      case "Lembrete":
        _executarScript();
        _jogoMaisProximo();
        break;
      default:
        break;
    }
    return Future.value(true);
  });
}

Future<void> _executarScript() async {
  try {
    final processResult = await Process.run('node', ['teste.mjs']);
    
    // Logar a saída e o erro do processo
    print('stdout: ${processResult.stdout}');
    print('stderr: ${processResult.stderr}');
    
    if (processResult.exitCode != 0) {
      throw Exception('Erro no teste.mjs: ${processResult.stderr}');
    }

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        'channel id',
        'channel name',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      0, 
      'Título da Notificação', 
      'Corpo da Notificação', 
      platformChannelSpecifics,
      payload: 'item x'
    );
  } catch (e) {
    print('Exception: $e');
    throw Exception('Erro ao tentar executar o teste.mjs: $e');
  }
}


  Future<void> _executarScriptJS() async {

    // Carrega o conteúdo do arquivo JavaScript
    // String scriptContentPart1 = await _carregarScript('assets/teste.mjs');
    // String scriptContentPart2 = await _carregarScript('assets/teste.mjs');
    // String scriptContent = scriptContentPart1 + scriptContentPart2;
    String scriptContent = await _carregarScript();

    print(scriptContent);
    try {
      // Avalia o código JavaScript
      JsEvalResult jsResult = await flutterJs.evaluate(scriptContent);

      // Verifica se a saída do script contém a mensagem de sucesso
      if (jsResult.stringResult.contains('Arquivo salvo com sucesso como jogos.json')) {
        print('Arquivo salvo com sucesso como jogos.json');
      } else {
        print('Erro: A operação falhou');
        print(jsResult.stringResult);
      }
    } catch (e) {
      print('Erro ao executar JS: $e');
    }
  }

/*
  Future<String> _carregarScript(String nomeArquivo) async {
    // Carrega o arquivo JavaScript da pasta de ativos
    ByteData data = await rootBundle.load(nomeArquivo);
    Uint8List bytes = data.buffer.asUint8List();
    return utf8.decode(bytes);
  }
*/






Future<String> _carregarScript() async {
  try {
    // Carregar o arquivo teste.mjs da pasta de ativos
    ByteData data = await rootBundle.load('assets/teste.txt');
    List<int> bytes = data.buffer.asUint8List();
    
    // Converta os bytes em uma string usando UTF-8
    print(String.fromCharCodes(bytes));
    return String.fromCharCodes(bytes);
  } catch (e) {
    // Se ocorrer algum erro, trate-o adequadamente
    print('Erro ao carregar o arquivo teste.mjs: $e');
    return 'aha'; // Retorna null em caso de erro
  }
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@drawable/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(const MyApp());
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
    flutterJs = getJavascriptRuntime();
    _startPeriodicTask();
  }

  void _startPeriodicTask() {
    Workmanager().registerPeriodicTask(
      "Lembrete",
      "Lembrete",
      tag: "Lembrete do gremio",
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 10),
    );
  }

  Future<DateTime?> _obterDataFechamento() async {
    try {
      final jsonString = await rootBundle.loadString('assets/jogos.json');
      final jogos = json.decode(jsonString);
      if (jogos.isNotEmpty) {
        final data = jogos[0]['data'];
        return DateTime.parse(data);
      }
    } catch (e) {
      Exception('Erro ao obter informações!!!!!!!');
    }
    return null;
  }

  Future<void> registerUniqueTask(TimeOfDay horarioSelecionado) async {
    final DateTime agora = DateTime.now();
    final TimeOfDay agoraHorario = TimeOfDay.fromDateTime(agora);
    final DateTime? dataFechamento = await _obterDataFechamento();

    if (dataFechamento != null) {
      final DateTime horarioNotificacao = DateTime(
        dataFechamento.year,
        dataFechamento.month,
        dataFechamento.day,
        horarioSelecionado.hour,
        horarioSelecionado.minute,
      );

      final DateTime agoraComHorarioSelecionado = DateTime(
        agora.year,
        agora.month,
        agora.day,
        horarioSelecionado.hour,
        horarioSelecionado.minute,
      );

      if (horarioNotificacao.isAfter(agora) || agoraComHorarioSelecionado.isBefore(agora)) {
        // Calcular o intervalo de tempo até o horário de notificação
        final Duration tempoAteNotificacao = horarioNotificacao.difference(agora);

        // Converter o horário selecionado em minutos
        final int minutosAteNotificacao = tempoAteNotificacao.inMinutes;

        // Agendar a notificação
        await flutterLocalNotificationsPlugin.zonedSchedule(
          0,
          'Título da Notificação',
          'Corpo da Notificação',
          tz.TZDateTime.from(horarioNotificacao, tz.local),
          const NotificationDetails(android: AndroidNotificationDetails('channel id', 'channel name')),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'item x',
        );
      }
    }
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

  void _abrirWhatsApp() async {
    // 'https://wa.me/5555996836060?text=Tenho%20interesse%20em%20comprar%20seu%20carro';
    var url = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '5555996836060',
      queryParameters: {
        'text': 'Olá, Kiri! Gostaria de saber mais sobre o app de lembrete de escalação do Cartola FC!',
      },
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Não foi possível abrir o WhatsApp!';
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
                _abrirWhatsApp();
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
            ElevatedButton(
              onPressed: _executarScriptJS,
              child: const Text('Executar JS'),
            ),
          ],
        ),
      ),
    );
  }
}
