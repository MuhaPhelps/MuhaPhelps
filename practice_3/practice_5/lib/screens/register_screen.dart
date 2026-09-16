import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/auth_service.dart';

class RegisterScreen
    extends StatefulWidget {
  final String? from;

  const RegisterScreen({
    super.key,
    this.from,
  });

  @override
  State<RegisterScreen>
      createState() =>
          _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _usernameController =
      TextEditingController();

  final _fullNameController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? _generalError;

  Map<String, String>
      _serverErrors = {};

  bool get _hasMinimumLength =>
      _passwordController
          .text.length >=
      8;

  bool get _hasDigit =>
      RegExp(r'\d').hasMatch(
        _passwordController.text,
      );

  bool get _hasSpecialCharacter =>
      RegExp(
        r'[!@#$%^&*(),.?":{}|<>_\-]',
      ).hasMatch(
        _passwordController.text,
      );

  bool get _passwordIsStrong =>
      _hasMinimumLength &&
      _hasDigit &&
      _hasSpecialCharacter;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController
        .dispose();

    super.dispose();
  }

  String? _usernameValidator(
    String? value,
  ) {
    final serverError =
        _serverErrors[
            'username'];

    if (serverError != null) {
      return serverError;
    }

    final text =
        value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Введите логин.';
    }

    if (text.length < 3) {
      return 'Логин не короче 3 символов.';
    }

    return null;
  }

  String? _fullNameValidator(
    String? value,
  ) {
    if ((value?.trim() ?? '')
        .isEmpty) {
      return 'Введите имя.';
    }

    return null;
  }

  String? _emailValidator(
    String? value,
  ) {
    final serverError =
        _serverErrors['email'];

    if (serverError != null) {
      return serverError;
    }

    final text =
        value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Введите электронную почту.';
    }

    final valid =
        RegExp(
      r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
    ).hasMatch(
      text,
    );

    if (!valid) {
      return 'Введите корректный адрес почты.';
    }

    return null;
  }

  String? _passwordValidator(
    String? value,
  ) {
    final serverError =
        _serverErrors['password'];

    if (serverError != null) {
      return serverError;
    }

    final text =
        value ?? '';

    if (text.isEmpty) {
      return 'Введите пароль.';
    }

    if (text.length < 8) {
      return 'Минимум 8 символов.';
    }

    if (!RegExp(r'\d')
        .hasMatch(text)) {
      return 'Добавьте хотя бы одну цифру.';
    }

    if (!RegExp(
      r'[!@#$%^&*(),.?":{}|<>_\-]',
    ).hasMatch(text)) {
      return 'Добавьте специальный символ.';
    }

    return null;
  }

  String? _confirmPasswordValidator(
    String? value,
  ) {
    if ((value ?? '').isEmpty) {
      return 'Повторите пароль.';
    }

    if (value !=
        _passwordController.text) {
      return 'Пароли не совпадают.';
    }

    return null;
  }

  void _onFieldChanged() {
    if (_serverErrors.isNotEmpty ||
        _generalError != null) {
      setState(() {
        _serverErrors = {};
        _generalError = null;
      });

      return;
    }

    setState(() {});
  }

  Future<void> _submit() async {
    setState(() {
      _serverErrors = {};
      _generalError = null;
    });

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (!_passwordIsStrong) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await context
          .read<AuthService>()
          .register(
        username:
            _usernameController.text,
        password:
            _passwordController.text,
        fullName:
            _fullNameController.text,
        email:
            _emailController.text,
      );

      if (!mounted) {
        return;
      }

      final parameters =
          <String, String>{
        'registered': '1',
        'username':
            _usernameController
                .text
                .trim(),
      };

      final from =
          widget.from;

      if (from != null &&
          from.startsWith('/')) {
        parameters['from'] =
            from;
      }

      context.go(
        Uri(
          path: '/login',
          queryParameters:
              parameters,
        ).toString(),
      );
    } on ValidationException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _serverErrors =
            e.errors;
      });

      _formKey.currentState!
          .validate();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _generalError =
            e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _generalError =
            'Не удалось выполнить регистрацию.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Widget _passwordRequirement({
    required bool completed,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          completed
              ? Icons
                  .check_circle
              : Icons
                  .radio_button_unchecked,
          size: 18,
          color: completed
              ? Colors.green
              : Theme.of(
                  context,
                )
                  .colorScheme
                  .onSurfaceVariant,
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          text,
          style: TextStyle(
            color: completed
                ? Colors.green
                : null,
          ),
        ),
      ],
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
              maxWidth: 460,
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
                            .person_add_alt_1,
                        size: 56,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      Text(
                        'Регистрация',
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
                        'Новая учётная запись создаётся с ролью «Читатель».',
                        textAlign:
                            TextAlign.center,
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      TextFormField(
                        controller:
                            _usernameController,
                        enabled:
                            !_submitting,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Логин',
                          prefixIcon:
                              Icon(
                            Icons.person_outline,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        validator:
                            _usernameValidator,
                        onChanged: (_) {
                          _onFieldChanged();
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextFormField(
                        controller:
                            _fullNameController,
                        enabled:
                            !_submitting,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Имя',
                          prefixIcon:
                              Icon(
                            Icons.badge_outlined,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        validator:
                            _fullNameValidator,
                        onChanged: (_) {
                          _onFieldChanged();
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextFormField(
                        controller:
                            _emailController,
                        enabled:
                            !_submitting,
                        keyboardType:
                            TextInputType
                                .emailAddress,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Электронная почта',
                          prefixIcon:
                              Icon(
                            Icons.email_outlined,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        validator:
                            _emailValidator,
                        onChanged: (_) {
                          _onFieldChanged();
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
                        decoration:
                            InputDecoration(
                          labelText:
                              'Пароль',
                          prefixIcon:
                              const Icon(
                            Icons.lock_outline,
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
                            _passwordValidator,
                        onChanged: (_) {
                          _onFieldChanged();
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _passwordRequirement(
                        completed:
                            _hasMinimumLength,
                        text:
                            'Не менее 8 символов',
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      _passwordRequirement(
                        completed:
                            _hasDigit,
                        text:
                            'Хотя бы одна цифра',
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      _passwordRequirement(
                        completed:
                            _hasSpecialCharacter,
                        text:
                            'Хотя бы один специальный символ',
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextFormField(
                        controller:
                            _confirmPasswordController,
                        enabled:
                            !_submitting,
                        obscureText:
                            _obscureConfirm,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Повторите пароль',
                          prefixIcon:
                              const Icon(
                            Icons
                                .lock_reset_outlined,
                          ),
                          border:
                              const OutlineInputBorder(),
                          suffixIcon:
                              IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirm =
                                    !_obscureConfirm;
                              });
                            },
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons
                                      .visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator:
                            _confirmPasswordValidator,
                        onChanged: (_) {
                          _onFieldChanged();
                        },
                      ),

                      if (_generalError !=
                          null) ...[
                        const SizedBox(
                          height: 16,
                        ),

                        Text(
                          _generalError!,
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
                                Icons
                                    .person_add,
                              ),
                        label: Text(
                          _submitting
                              ? 'Регистрация...'
                              : 'Зарегистрироваться',
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      TextButton(
                        onPressed:
                            _submitting
                                ? null
                                : () {
                                    final from =
                                        widget
                                            .from;

                                    if (from !=
                                        null) {
                                      context.go(
                                        Uri(
                                          path:
                                              '/login',
                                          queryParameters: {
                                            'from':
                                                from,
                                          },
                                        ).toString(),
                                      );
                                    } else {
                                      context.go(
                                        '/login',
                                      );
                                    }
                                  },
                        child: const Text(
                          'Уже есть аккаунт? Войти',
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