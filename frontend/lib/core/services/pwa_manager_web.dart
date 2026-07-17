import 'dart:html' as html;
import 'dart:js_util' as js_util;

class PwaManager {
  PwaManager() {
    _init();
  }

  bool available = false;
  void Function()? onChange;

  dynamic _deferredPrompt;

  void _init() {
    html.window.addEventListener('beforeinstallprompt', (event) {
      event.preventDefault();
      _deferredPrompt = event;
      available = true;
      onChange?.call();
    });

    html.window.addEventListener('appinstalled', (_) {
      _deferredPrompt = null;
      available = false;
      onChange?.call();
    });
  }

  Future<bool> promptInstall() async {
    if (_deferredPrompt == null) return false;
    try {
      await js_util.promiseToFuture(js_util.callMethod(_deferredPrompt, 'prompt', []));
      final userChoice = await js_util.promiseToFuture(
        js_util.getProperty(_deferredPrompt, 'userChoice'),
      );
      final outcome = js_util.getProperty(userChoice, 'outcome') == 'accepted';
      _deferredPrompt = null;
      available = false;
      onChange?.call();
      return outcome;
    } catch (_) {
      _deferredPrompt = null;
      available = false;
      onChange?.call();
      return false;
    }
  }
}
