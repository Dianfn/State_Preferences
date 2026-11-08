import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _favoriteController;
  String? _errorMessage;

  static final _dangerousRegex = RegExp(
    r'<[a-zA-Z!/]|</|script|javascript:|on\w+\s*=',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _favoriteController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<UserProvider>(context, listen: false);
    // Mengisi teks controller hanya saat masih kosong agar tidak menimpa ketikan pengguna
    if (_nameController.text.isEmpty && _emailController.text.isEmpty) {
      _nameController.text = provider.user.name;
      _emailController.text = provider.user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  // Latihan 5: Validasi keamanan pada _saveProfile
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<UserProvider>(context, listen: false);
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    // Latihan 5b: cek apakah nama mengandung karakter berbahaya (misalnya <script>)
    if (_dangerousRegex.hasMatch(newName)) {
      setState(() {
        _errorMessage = 'Nama mengandung karakter berbahaya (misal '
            '<script>). Gunakan karakter yang aman.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama mengandung karakter berbahaya!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Latihan 5a: cek apakah email sudah digunakan (simulasi dengan SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final savedEmail = prefs.getString('user_email') ?? '';
    final registeredEmails = prefs.getStringList('registered_emails') ?? [];

    // Daftar email yang terpakai oleh akun lain
    final emailTerpakai = <String>{
      if (savedEmail.isNotEmpty && savedEmail != provider.user.email)
        savedEmail,
      ...registeredEmails.where(
        (e) => e.trim().isNotEmpty && e != provider.user.email,
      ),
    }.where((e) => e.isNotEmpty).toList();

    if (newEmail != provider.user.email && emailTerpakai.contains(newEmail)) {
      setState(() {
        _errorMessage = 'Email $newEmail sudah digunakan';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email $newEmail sudah digunakan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    // Perbarui daftar email terdaftar: hapus email lama, simpan email baru
    registeredEmails.remove(provider.user.email);
    if (newEmail.isNotEmpty) {
      registeredEmails.add(newEmail);
    }
    await prefs.setStringList('registered_emails', registeredEmails);

    if (!mounted) return;

    await provider.updateUser(
      provider.user.copyWith(
        name: newName,
        email: newEmail,
        isLoggedIn: true,
      ),
    );

    if (!mounted) return;

    // Latihan 5c: pesan sukses via ScaffoldMessenger
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil disimpan'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Latihan 3c: menambah favorit baru dari form
  void _addFavorite() {
    final text = _favoriteController.text.trim();
    if (text.isEmpty) return;
    Provider.of<UserProvider>(context, listen: false).addFavorite(text);
    _favoriteController.clear();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.pop(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              if (provider.user.isLoggedIn)
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.deepPurple,
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              final emailRegex =
                                  RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          // Latihan 5c: menampilkan pesan error di dalam form
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _saveProfile,
                            icon: const Icon(Icons.save),
                            label: const Text('Simpan Profil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Latihan 3b: menampilkan daftar favorit di ProfileScreen
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Daftar Favorit',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _favoriteController,
                                    decoration: const InputDecoration(
                                      labelText: 'Tambah item favorit',
                                      hintText: 'misal: hobi, makanan, dll',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onFieldSubmitted: (_) => _addFavorite(),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: _addFavorite,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Tambah Favorit'),
                                    ),
                                  ),
                                  if (provider.favorites.isEmpty)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        'Belum ada item favorit.',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: provider.favorites.length,
                                      itemBuilder: (context, index) {
                                        final item = provider
                                            .favorites[index];
                                        return ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: const Icon(
                                            Icons.favorite,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                          title: Text(item),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                            ),
                                            tooltip: 'Hapus',
                                            onPressed: () => Provider.of<
                                              UserProvider
                                            >(context, listen: false)
                                                .removeFavorite(index),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            color: Colors.amber[50],
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info,
                                          color: Colors.amber[900]),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Catatan Keamanan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Data disimpan di SharedPreferences (plaintext).\n'
                                    'Jangan simpan password atau data sensitif di sini.\n'
                                    'Gunakan secure storage untuk data sensitif.',
                                    style: TextStyle(fontSize: 12, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
