import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import 'login_screen.dart';
import 'voucher_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _topupLoading = false;
  bool _editLoading = false;

  Future<void> _logout() async {
    final app = context.read<AppState>();
    await app.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  Future<void> _topup() async {
    final app = context.read<AppState>();
    final ctl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Top-up Saldo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text('Saldo saat ini: ${rupiah(app.user?.saldo ?? 0)}', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              TextField(
                controller: ctl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nominal (Rp)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _topupLoading
                    ? null
                    : () async {
                        final n = int.tryParse(ctl.text) ?? 0;
                        if (n <= 0) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nominal tidak valid')));
                          return;
                        }
                        setState(() => _topupLoading = true);
                        try {
                          await Api.topup(n);
                          await app.refreshUser();
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                        } finally {
                          if (mounted) setState(() => _topupLoading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF171717), foregroundColor: Colors.white),
                child: _topupLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Top-up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showInfo(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Future<void> _showEditProfile() async {
    final app = context.read<AppState>();
    final u = app.user;
    if (u == null) return;
    final nama = TextEditingController(text: u.nama);
    final telepon = TextEditingController(text: u.telepon);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Edit Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: telepon, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telepon', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _editLoading
                    ? null
                    : () async {
                        setState(() => _editLoading = true);
                        try {
                          await Api.updateProfil(nama: nama.text.trim(), telepon: telepon.text.trim());
                          await app.refreshUser();
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                          }
                        } finally {
                          if (mounted) setState(() => _editLoading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF171717), foregroundColor: Colors.white),
                child: _editLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final u = app.user;
    if (u == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: RefreshIndicator(
        onRefresh: () => app.refreshUser(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white12,
                    child: Icon(u.fotoProfil.isEmpty ? Icons.person : null, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.nama, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(u.email, style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
                          child: Text(u.role.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  ListTile(
                    tileColor: Colors.white,
                    leading: const Icon(Icons.wallet_outlined),
                    title: const Text('Saldo Dompet'),
                    trailing: Text(rupiah(u.saldo), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _topup,
                        icon: const Icon(Icons.add),
                        label: const Text('Top-up Saldo'),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    tileColor: Colors.white,
                    leading: const Icon(Icons.confirmation_number_outlined),
                    title: const Text('Voucher Saya'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherScreen())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    tileColor: Colors.white,
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Edit Profil'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showEditProfile(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    tileColor: Colors.white,
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Alamat Saya'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showInfo('Alamat', 'Fitur alamat tersimpan akan hadir di pembaruan berikutnya.'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    tileColor: Colors.white,
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Bantuan'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showInfo('Bantuan', 'Butuh bantuan? Hubungi admin MarketKita melalui menu Pesan.'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    tileColor: Colors.white,
                    leading: const Icon(Icons.logout),
                    title: const Text('Keluar', style: TextStyle(color: Colors.red)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
