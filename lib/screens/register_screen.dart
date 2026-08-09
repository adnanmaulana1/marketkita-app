import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api.dart';
import '../state/app_state.dart';
import '../widgets/app_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _telepon = TextEditingController();
  final _password = TextEditingController();
  final _namaToko = TextEditingController();
  final _kendaraan = TextEditingController();
  String _role = 'pembeli';
  bool _obscure = true;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final app = context.read<AppState>();
    try {
      await app.register(
        nama: _nama.text.trim(),
        email: _email.text.trim(),
        telepon: _telepon.text.trim(),
        password: _password.text,
        role: _role,
        namaToko: _namaToko.text.trim(),
        kendaraan: _kendaraan.text.trim(),
      );
      if (!mounted) return;
      final role = app.user!.role;
      if (role == 'kurir') {
        Navigator.pushReplacementNamed(context, '/kurir');
      } else if (role == 'toko') {
        Navigator.pushReplacementNamed(context, '/toko');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Terjadi kesalahan. Periksa koneksi ke server.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToko = _role == 'toko';
    final isKurir = _role == 'kurir';
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(size: 56)),
                    const SizedBox(height: 16),
                    const Text(
                      'Daftar di MarketKita',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'pembeli', label: Text('Pembeli'), icon: Icon(Icons.shopping_bag_outlined)),
                        ButtonSegment(value: 'toko', label: Text('Toko'), icon: Icon(Icons.storefront_outlined)),
                        ButtonSegment(value: 'kurir', label: Text('Kurir'), icon: Icon(Icons.two_wheeler_outlined)),
                      ],
                      selected: {_role},
                      onSelectionChanged: (s) => setState(() => _role = s.first),
                    ),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _nama,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Email wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telepon,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Telepon', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    if (isToko) ...[
                      TextFormField(
                        controller: _namaToko,
                        decoration: const InputDecoration(labelText: 'Nama Toko', prefixIcon: Icon(Icons.storefront_outlined), border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama toko wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (isKurir) ...[
                      DropdownButtonFormField<String>(
                        value: _kendaraan.text.isEmpty ? 'motor' : _kendaraan.text,
                        decoration: const InputDecoration(labelText: 'Kendaraan', prefixIcon: Icon(Icons.two_wheeler_outlined), border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'motor', child: Text('Motor')),
                          DropdownMenuItem(value: 'mobil', child: Text('Mobil')),
                          DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
                        ],
                        onChanged: (v) => _kendaraan.text = v ?? 'motor',
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF171717),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Daftar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text('Sudah punya akun? Masuk'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
