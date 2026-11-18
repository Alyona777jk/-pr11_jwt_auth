import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl.text = user?.name ?? '';
    _emailCtrl.text = user?.email ?? '';
  }

  void _showChangePasswordDialog() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Зміна пароля'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Поточний пароль'),
                validator: (v) => (v == null || v.isEmpty) ? 'Обов’язкове поле' : null,
              ),
              TextFormField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Новий пароль (мін. 8)'),
                validator: (v) => (v == null || v.length < 8) ? 'Мінімум 8 символів' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await context.read<AuthProvider>().changePassword(
                      oldPassword: oldPassCtrl.text,
                      newPassword: newPassCtrl.text,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Listener(
      onPointerDown: (_) => auth.resetInactivityTimer(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Захищений профіль'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Вийти',
              onPressed: () => auth.logout(),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auth.statusLog != null)
                Card(
                  color: Colors.indigo.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Лог перехоплювача: ${auth.statusLog}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text('ID користувача: ${user?.id} | Роль: ${user?.role}'),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ім’я (PUT /user)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email (PUT /user)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Оновити профіль'),
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        try {
                          await auth.updateProfile(
                            name: _nameCtrl.text.trim(),
                            email: _emailCtrl.text.trim(),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                          );
                        }
                      },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.password),
                label: const Text('Змінити пароль (POST /user/change-password)'),
                onPressed: _showChangePasswordDialog,
              ),
              const Divider(height: 32),
              const Text(
                'Демонстрація роботи Interceptors:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade100,
                  foregroundColor: Colors.black87,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Симулювати 401 -> Refresh Token -> Retry'),
                onPressed: auth.isLoading ? null : () => auth.simulateExpiredTokenAndRetry(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
