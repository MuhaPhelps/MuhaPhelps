import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../state/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      await context.read<AuthController>().register(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          );
      if (mounted) context.go('/dashboard');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().busy;
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Новый инженер',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'При самостоятельной регистрации назначается роль «Инженер».',
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'ФИО',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (value?.trim().length ?? 0) < 3
                            ? 'Минимум 3 символа'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Укажите e-mail';
                          if (!text.contains('@')) return 'Некорректный e-mail';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Пароль',
                          helperText: 'Не менее 8 символов, цифра и специальный символ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final text = value ?? '';
                          if (text.length < 8) return 'Минимум 8 символов';
                          if (!RegExp(r'\d').hasMatch(text)) return 'Добавьте цифру';
                          if (!RegExp(r'[^A-Za-zА-Яа-я0-9]').hasMatch(text)) {
                            return 'Добавьте специальный символ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirm,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Повторите пароль',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value != _password.text
                            ? 'Пароли не совпадают'
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: busy ? null : _submit,
                        child: const Text('Зарегистрироваться'),
                      ),
                      TextButton(
                        onPressed: busy ? null : () => context.go('/login'),
                        child: const Text('Вернуться ко входу'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
