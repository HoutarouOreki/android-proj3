import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:proj3/full_width_button.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projekt 3',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const MyHomePage(title: 'Projekt 3'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  MaterialPageRoute<void>? route;

  void selectNotification(String? payload) async {
    // if (route != null) {
    //   await Navigator.push(
    //     context,
    //     route!,
    //   );
    // }
  }

  final TextEditingController adresController = TextEditingController();

  String statusText = "";

  double _progress = 0;

  double get downloadProgress => _progress;

  int downloadedBytes = 0;

  Future<bool> requestPermission(Permission setting) async {
    // setting.request() will return the status ALWAYS
    // if setting is already requested, it will return the status
    final result = await setting.request();
    switch (result) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return true;
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
      case PermissionStatus.permanentlyDenied:
        return false;
    }
  }

  void ustawStatus(String? t) {
    setState(() {
      statusText = t ?? "";
    });
  }

  void startDownloading() async {
    _progress = 0;
    var url = Uri.tryParse(adresController.text);
    await pobierzInformacje();
    if (url == null || size == null || type == null) {
      ustawStatus("Nie można pobrać z takiego URL.");
      return;
    }

    final request = Request('GET', url);
    final StreamedResponse response = await Client().send(request);

    _progress = 0;

    List<int> bytes = [];

    final file = await _getFile('zdjecie.bmp');

    if (file == null) {
      wyswietlBladToastOrazPrzekaz("Nie zezwolono na dostep do plikow");
      ustawStatus("Nie zezwolono na dostep do plikow.");
      return;
    }

    await showDownloadNotification();
    ustawStatus("Rozpoczęto pobieranie.");

    response.stream.listen(
      (List<int> newBytes) {
        // update progress
        bytes.addAll(newBytes);
        final downloadedLength = bytes.length;
        _progress = downloadedLength / num.parse(size!);

        showDownloadNotification();
        setState(() {
          downloadedBytes = downloadedLength;
        });
      },
      onDone: () async {
        ustawStatus("Zapisano plik w ${file.path}.");
        _progress = 1;
        await file.writeAsBytes(bytes);
      },
      onError: (e) {
        ustawStatus("Wystąpił błąd.");
        if (kDebugMode) {
          print(e);
        }
      },
      cancelOnError: true,
    );
  }

  Future<void> showDownloadNotification({bool firstTime = false}) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      progress: (_progress * 100).toInt(),
      showProgress: true,
      maxProgress: 100,
      fullScreenIntent: firstTime,
    );
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin?.show(0, 'Pobieranie pliku',
        '$downloadedBytes / $size', platformChannelSpecifics);
  }

  Future<File?> _getFile(String filename) async {
    final canUseStorage = await requestPermission(Permission.storage);

    if (canUseStorage) {
      return File("/storage/emulated/0/$filename");
    }
    return null;
  }

  String wyswietlBladToastOrazPrzekaz(String t) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t)),
    );
    return t;
  }

  String? size;
  String? type;
  String? fileName;

  Future getFileInfo({required String url}) async {
    http.Response r = await http.head(Uri.parse(url));
    log(r.headers.toString());
    setState(() {
      size = r.headers["content-length"];
      type = r.headers["content-type"];
    });
  }

  void initializeNotifs() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings("@mipmap/ic_launcher");
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin?.initialize(initializationSettings,
        onSelectNotification: selectNotification);
  }

  @override
  Widget build(BuildContext context) {
    route ??= MaterialPageRoute<void>(builder: (context) => widget);
    adresController.text =
        "https://cdn.discordapp.com/attachments/234407380618575872/986537478129348608/4312822.bmp";
    initializeNotifs();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextFormField(
              controller: adresController,
              decoration: const InputDecoration(labelText: "Adres URL"),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return wyswietlBladToastOrazPrzekaz("Podaj adres URL");
                }
                return null;
              },
            ),
            FullWidthButton(
              onPressed: () {
                pobierzInformacje();
              },
              child: const Text("Pobierz informacje"),
            ),
            Text(
                size == null ? "Brak content-length" : "Content-length: $size"),
            Text(type == null ? "Brak content-type" : "Content-type: $type"),
            SizedBox.fromSize(size: const Size(0, 30)),
            FullWidthButton(
              onPressed: () {
                startDownloading();
              },
              child: const Text("Pobierz plik"),
            ),
            SizedBox.fromSize(size: const Size(0, 30)),
            const Text("Postęp:"),
            LinearProgressIndicator(
              minHeight: 10,
              semanticsLabel: "Pobieranie",
              value: downloadProgress,
            ),
            SizedBox.fromSize(size: const Size(0, 30)),
            Text(statusText),
          ],
        ),
      ),
    );
  }

  Future pobierzInformacje() async {
    try {
      var url = Uri.tryParse(adresController.text);
      ustawStatus("Rozpoczęto pobieranie informacji.");
      if (url != null) {
        http.Response r = await http.head(url);
        log(r.headers.toString());
        setState(() {
          size = r.headers["content-length"];
          type = r.headers["content-type"];
        });
        ustawStatus("Pobrano informacje.");
      } else {
        ustawStatus("Nie można pobrać informacji z takiego URL.");
      }
    } catch (e) {
      ustawStatus("Nie można pobrać informacji z takiego URL.");
    }
  }
}
