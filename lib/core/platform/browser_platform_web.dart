import 'package:web/web.dart';

String? readLocalStorage(String key) => window.localStorage.getItem(key);

void writeLocalStorage(String key, String value) {
  window.localStorage.setItem(key, value);
}

void removeLocalStorage(String key) {
  window.localStorage.removeItem(key);
}

void clearBrowserStorage() {
  window.localStorage.clear();
  window.sessionStorage.clear();
}

void openInNewTab(String url) {
  window.open(url, '_blank');
}
