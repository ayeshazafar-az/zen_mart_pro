import 'package:flutter/material.dart';

enum AppLanguage { english, spanish }

class LanguageProvider extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;

  void toggleLanguage() {
    _currentLanguage = _currentLanguage == AppLanguage.english
        ? AppLanguage.spanish
        : AppLanguage.english;
    notifyListeners();
  }

  // Simple dictionary
  final Map<AppLanguage, Map<String, String>> _dictionary = {
    AppLanguage.english: {
      'welcome': 'Welcome User!',
      'products': 'Browse Products',
      'shops': 'Vendors & Shops',
      'cart': 'My Cart',
      'orders': 'My Orders',
      'wishlist': 'My Wishlist',
      'support': 'Help & Support',
      'settings': 'Settings',
      'logout': 'Logout',
      'dashboard': 'Customer Dashboard',
      'toggle_lang': 'Español',
      'edit_profile': 'Edit Profile',
      'profile_settings': 'Profile & Settings',
      'saved_addresses': 'Saved Addresses',
      'notifications': 'Notifications',
      'dark_mode': 'Dark Mode',
      'language_label': 'Language: English',
    },
    AppLanguage.spanish: {
      'welcome': '¡Bienvenido Usuario!',
      'products': 'Buscar Productos',
      'shops': 'Vendedores y Tiendas',
      'cart': 'Mi Carrito',
      'orders': 'Mis Pedidos',
      'wishlist': 'Mi Lista de Deseos',
      'support': 'Ayuda y Soporte',
      'settings': 'Ajustes',
      'logout': 'Cerrar Sesión',
      'dashboard': 'Panel de Clientes',
      'toggle_lang': 'English',
      'edit_profile': 'Editar Perfil',
      'profile_settings': 'Perfil y Ajustes',
      'saved_addresses': 'Direcciones Guardadas',
      'notifications': 'Notificaciones',
      'dark_mode': 'Modo Oscuro',
      'language_label': 'Idioma: Español',
    }
  };

  String getText(String key) {
    return _dictionary[_currentLanguage]?[key] ?? key;
  }
}
