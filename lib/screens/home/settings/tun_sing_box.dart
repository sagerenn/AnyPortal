import 'dart:io';

import 'package:anyportal/models/log_level.dart';
import 'package:anyportal/utils/tray_menu.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../utils/global.dart';
import '../../../utils/platform_file_mananger.dart';
import '../../../utils/prefs.dart';
import '../../../utils/vpn_manager.dart';
import '../../../widgets/popup/radio_list_selection.dart';
import '../../../widgets/popup/text_input.dart';

class TunSingBoxScreen extends StatefulWidget {
  const TunSingBoxScreen({
    super.key,
  });

  @override
  State<TunSingBoxScreen> createState() => _TunSingBoxScreenState();
}

class _TunSingBoxScreenState extends State<TunSingBoxScreen> {
  bool _tun = prefs.getBool('tun')!;
  bool _injectLog = prefs.getBool('tun.inject.log')!;
  LogLevel _logLevel = LogLevel.values[prefs.getInt('tun.inject.log.level')!];

  bool _injectSocks = prefs.getBool('tun.inject.socks')!;
  int _socksPort = prefs.getInt('inject.socks.port')!;
  bool _injectExcludeCorePath = prefs.getBool('tun.inject.excludeCorePath')!;

  @override
  void initState() {
    super.initState();
  }

  void writeTProxyConf() async {}

  @override
  Widget build(BuildContext context) {
    final fields = [
      ListTile(
        title: const Text("Enable tun"),
        subtitle: const Text("""Enable tun2socks so a socks proxy works like a VPN
Requires elevation
"""),
        trailing: Switch(
          value: _tun,
          onChanged: (value) {
            prefs.setBool('tun', value);
            setState(() {
              _tun = value;
            });
            trayMenu.updateContextMenu();
            if (vPNMan.isCoreActiveRecord.isCoreActive) {
              if (value) {
                vPNMan.startTun();
              } else {
                vPNMan.stopTun();
              }
            }
          },
        ),
      ),
      const Divider(),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Text(
          "Log config override",
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      ListTile(
        title: const Text("Inject Log"),
        subtitle: const Text("Override log config"),
        trailing: Switch(
          value: _injectLog,
          onChanged: (bool value) {
            prefs.setBool('tun.inject.log', value);
            setState(() {
              _injectLog = value;
            });
          },
        ),
      ),
      ListTile(
        enabled: _injectLog,
        title: const Text('Log Level'),
        subtitle: Text(_logLevel.name),
        onTap: () {
          showDialog(
              context: context,
              builder: (context) => RadioListSelectionPopup<LogLevel>(
                    title: 'Log Level',
                    items: LogLevel.values,
                    initialValue: _logLevel,
                    onSaved: (value) {
                      prefs.setInt('tun.inject.log.level', value.index);
                      setState(() {
                        _logLevel = value;
                      });
                    },
                    itemToString: (e) => e.name,
                  ));
        },
      ),
      const Divider(),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Text(
          "Outbound config: additional socks outbound",
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      ListTile(
        title: const Text("Inject socks outbound"),
        subtitle: const Text(
            "inject a socks outbound"),
        trailing: Switch(
          value: _injectSocks,
          onChanged: (value) {
            prefs.setBool('tun.inject.socks', value);
            setState(() {
              _injectSocks = value;
            });
          },
        ),
      ),
      ListTile(
        title: const Text('Port'),
        subtitle: Text(_socksPort.toString()),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => TextInputPopup(
                title: 'Socks port',
                initialValue: _socksPort.toString(),
                onSaved: (String value) {
                  final socksPort = int.parse(value);
                  prefs.setInt('inject.socks.port', socksPort);
                  setState(() {
                    _socksPort = socksPort;
                  });
                }),
          );
        },
        enabled: _injectSocks,
      ),
      const Divider(),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Text(
          "Routing rule: additionally exclude core path",
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      ListTile(
        title: const Text("Inject rule to exclude core path"),
        subtitle: const Text(
            "Disable to improve performance, make sure you have bound core to a correct interface"),
        trailing: Switch(
          value: _injectExcludeCorePath,
          onChanged: (value) {
            prefs.setBool('tun.inject.excludeCorePath', value);
            setState(() {
              _injectExcludeCorePath = value;
            });
          },
        ),
      ),
      const Divider(),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Text(
          "Advanced",
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      ListTile(
        title: const Text("Edit config"),
        subtitle: const Text("sing-box config"),
        trailing: const Icon(Icons.folder_open),
        onTap: () {
          PlatformFileMananger.highlightFileInFolder(p.join(
              global.applicationDocumentsDirectory.path,
              "AnyPortal",
              "conf",
              "tun.sing_box.json"));
        },
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        writeTProxyConf();
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          // Use the selected tab's label for the AppBar title
          title: const Text("Tun settings"),
        ),
        body: ListView.builder(
          itemCount: fields.length,
          itemBuilder: (context, index) => fields[index],
          // separatorBuilder: (context, index) => const SizedBox(height: 16),
        ),
      ),
    );
  }
}

tProxyConfInit() async {
  final file = File(p.join(
    global.applicationSupportDirectory.path,
    'conf',
    'tun.sing_box.gen.json',
  ));
  if (!file.existsSync()) {
    await file.create(recursive: true);
    _TunSingBoxScreenState().writeTProxyConf();
  }
}
