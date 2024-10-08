import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import 'global.dart';
import 'platform_system_proxy_user.dart';
import 'prefs.dart';
import 'vpn_manager.dart';

class TrayMenuManager {
  bool isSystemProxy = false;

  Menu menu = Menu();

  Future<void> init() async {
    if (Platform.isWindows) {
      await trayManager.setIcon('windows/runner/resources/app_icon.ico');
    } else if (Platform.isMacOS) {
      await trayManager.setIcon('assets/icon/icon_w.png');
    } else {
      await trayManager.setIcon('assets/icon/icon.png');
    }

    await updateContextMenu();
    _completer.complete(); // Signal that initialization is complete
  }

  static final TrayMenuManager _instance = TrayMenuManager._internal();
  final Completer<void> _completer = Completer<void>();

  // Private constructor
  TrayMenuManager._internal();

  // Singleton accessor
  factory TrayMenuManager() {
    return _instance;
  }

  updateContextMenu() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return;
    }
    final systemProxyEnabled = await platformSystemProxyUser.isEnabled();
    menu = Menu(
      items: [
        MenuItem.checkbox(
          key: 'toggle_all',
          label: 'Connect',
          checked: await vPNMan.getIsCoreActive(),
        ),
        MenuItem.separator(),
        MenuItem.checkbox(
          disabled: systemProxyEnabled == null,
          key: 'toggle_system_proxy',
          label: 'System proxy',
          checked: systemProxyEnabled,
        ),
        MenuItem.checkbox(
          disabled: global.isElevated == false,
          key: 'toggle_tun',
          label: 'Tun',
          checked: prefs.getBool("tun"),
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit',
          label: 'Exit',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }
}

final trayMenu = TrayMenuManager();
