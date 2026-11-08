import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

// Latihan 4: UserProvider diubah dari InheritedWidget menjadi ChangeNotifier
class UserProvider extends ChangeNotifier {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  int _visitCount = 0;
  List<String> _favorites = [];

  User get user => _user;
  bool get isLoading => _isLoading;

  // Latihan 2: counter kunjungan
  int get visitCount => _visitCount;

  // Latihan 3: daftar favorit
  List<String> get favorites => List.unmodifiable(_favorites);

  UserProvider() {
    _loadUser();
  }

  // Memuat data user dari SharedPreferences
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    // Latihan 2b: increment counter setiap kali aplikasi dibuka
    final visitCount = (prefs.getInt('visit_count') ?? 0) + 1;
    await prefs.setInt('visit_count', visitCount);

    // Latihan 3a: muat daftar favorit
    final favorites = prefs.getStringList('favorites') ?? [];

    _user = User(name: name, email: email, isLoggedIn: isLoggedIn);
    _visitCount = visitCount;
    _favorites = favorites;
    _isLoading = false;
    notifyListeners();
  }

  // Menyimpan data user ke SharedPreferences
  Future<void> updateUser(User newUser) async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);
    _user = newUser;
    _isLoading = false;
    notifyListeners();
  }

  // Logout: hapus data user (kecuali email)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);
    _user = _user.copyWith(name: '', isLoggedIn: false);
    notifyListeners();
  }

  // Latihan 3a: simpan daftar favorit dengan setStringList
  Future<void> addFavorite(String item) async {
    final trimmed = item.trim();
    if (trimmed.isEmpty || _favorites.contains(trimmed)) return;
    final prefs = await SharedPreferences.getInstance();
    final list = [..._favorites, trimmed];
    await prefs.setStringList('favorites', list);
    _favorites = list;
    notifyListeners();
  }

  // Latihan 3c: hapus favorit
  Future<void> removeFavorite(int index) async {
    if (index < 0 || index >= _favorites.length) return;
    final prefs = await SharedPreferences.getInstance();
    final list = [..._favorites]..removeAt(index);
    await prefs.setStringList('favorites', list);
    _favorites = list;
    notifyListeners();
  }
}
