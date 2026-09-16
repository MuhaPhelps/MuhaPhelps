import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/auth_service.dart';

class LoginScreen
    extends StatefulWidget {
  final String? from;
  final bool registered;
  final String? initialUsername;

  const LoginScreen({
    super.key,
    this.from,
    this.registered = false,
    this.initialUsername,
  });

  @override
  State<LoginScreen>
      createState() =>
          _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _usernameController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  bool _submitting = false;
  bool _obscurePassword = true;

  String? _loginError;

  @override
  void initState() {
    super.initState();

    _usernameController.text =
        widget.initialUsername ??
            '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loginError = null;
    });

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await context
          .read<AuthService>()
          .login(
        _usernameController.text,
        _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      final from =
          widget.from;

      final target =
          from != null &&
                  from.startsWith('/') &&
                  !from.startsWith(
                    '/login',
                  ) &&
                  !from.startsWith(
                    '/register',
                  )
              ? from
              : '/books';

      context.go(
        target,
      );
    } on UnauthorizedException {
      if (!mounted) {
        return;
      }

      setState(() {
        _loginError =
            'Неверный логин или пароль.';
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loginError =
            e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loginError =
            'Не удалось выполнить вход.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _goToRegister() {
    final from =
        widget.from;

    if (from != null &&
        from.startsWith('/')) {
      context.go(
        Uri(
          path: '/register',
          queryParameters: {
            'from': from,
          },
        ).toString(),
      );

      return;
    }

    context.go(
      '/register',
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            24,
          ),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 440,
            ),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      const Icon(
                        Icons
                            .local_library,
                        size: 56,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      Text(
                        'Библиотечная система',
                        textAlign:
                            TextAlign.center,
                        style:
                            Theme.of(
                          context,
                        )
                                .textTheme
                                .headlineMedium,
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        'Войдите в свою учётную запись',
                        textAlign:
                            TextAlign.center,
                      ),

                      if (widget
                          .registered) ...[
                        const SizedBox(
                          height: 20,
                        ),

                        Container(
                          padding:
                              const EdgeInsets.all(
                            12,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .green
                                .withValues(
                              alpha: 0.10,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                            border:
                                Border.all(
                              color:
                                  Colors.green,
                            ),
                          ),
                          child:
                              const Row(
                            children: [
                              Icon(
                                Icons
                                    .check_circle_outline,
                                color:
                                    Colors.green,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child:
                                    Text(
                                  'Регистрация завершена. Теперь войдите в систему.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 28,
                      ),

                      TextFormField(
                        controller:
                            _usernameController,
                        enabled:
                            !_submitting,
                        textInputAction:
                            TextInputAction
                                .next,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Логин',
                          prefixIcon:
                              Icon(
                            Icons
                                .person_outline,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        validator:
                            (value) {
                          if ((value
                                      ?.trim() ??
                                  '')
                              .isEmpty) {
                            return 'Введите логин.';
                          }

                          return null;
                        },
                        onChanged: (_) {
                          if (_loginError !=
                              null) {
                            setState(() {
                              _loginError =
                                  null;
                            });
                          }
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextFormField(
                        controller:
                            _passwordController,
                        enabled:
                            !_submitting,
                        obscureText:
                            _obscurePassword,
                        onFieldSubmitted:
                            (_) {
                          if (!_submitting) {
                            _submit();
                          }
                        },
                        decoration:
                            InputDecoration(
                          labelText:
                              'Пароль',
                          prefixIcon:
                              const Icon(
                            Icons
                                .lock_outline,
                          ),
                          border:
                              const OutlineInputBorder(),
                          suffixIcon:
                              IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                      .visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator:
                            (value) {
                          if ((value ?? '')
                              .isEmpty) {
                            return 'Введите пароль.';
                          }

                          return null;
                        },
                        onChanged: (_) {
                          if (_loginError !=
                              null) {
                            setState(() {
                              _loginError =
                                  null;
                            });
                          }
                        },
                      ),

                      if (_loginError !=
                          null) ...[
                        const SizedBox(
                          height: 16,
                        ),

                        Text(
                          _loginError!,
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color:
                                Theme.of(
                              context,
                            )
                                    .colorScheme
                                    .error,
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 24,
                      ),

                      FilledButton.icon(
                        onPressed:
                            _submitting
                                ? null
                                : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons.login,
                              ),
                        label: Text(
                          _submitting
                              ? 'Вход...'
                              : 'Войти',
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      TextButton(
                        onPressed:
                            _submitting
                                ? null
                                : _goToRegister,
                        child: const Text(
                          'Нет аккаунта? Зарегистрироваться',
                        ),
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