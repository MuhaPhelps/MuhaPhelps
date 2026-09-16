import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/system_user.dart';
import '../repositories/user_repository.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({
    super.key,
  });

  @override
  State<UsersScreen> createState() =>
      _UsersScreenState();
}

class _UsersScreenState
    extends State<UsersScreen> {
  bool _isLoading = true;
  String? _error;

  List<SystemUser> _users = [];

  @override
  void initState() {
    super.initState();

    Future.microtask(
      _load,
    );
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository =
          context.read<UserRepository>();

      final users =
          await repository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'Не удалось загрузить пользователей.\n$error';

        _isLoading = false;
      });
    }
  }

  IconData _roleIcon(
    SystemUser user,
  ) {
    switch (user.role) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;

      case 'librarian':
        return Icons.local_library_outlined;

      case 'reader':
        return Icons.person_outline;

      default:
        return Icons.account_circle_outlined;
    }
  }

  Widget _buildUserCard(
    BuildContext context,
    SystemUser user,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              child: Icon(
                _roleIcon(
                  user,
                ),
              ),
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName.isNotEmpty
                        ? user.fullName
                        : user.username,
                    style:
                        Theme.of(
                      context,
                    ).textTheme.titleMedium
                            ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    '@${user.username}',
                    style:
                        Theme.of(
                      context,
                    ).textTheme.bodyMedium,
                  ),

                  if (user.email.isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      user.email,
                      style:
                          Theme.of(
                        context,
                      ).textTheme.bodySmall,
                    ),
                  ],

                  const SizedBox(
                    height: 10,
                  ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: Icon(
                          _roleIcon(
                            user,
                          ),
                          size: 18,
                        ),
                        label: Text(
                          user.roleTitle,
                        ),
                      ),

                      if (user.readerId !=
                          null)
                        Chip(
                          avatar:
                              const Icon(
                            Icons.badge_outlined,
                            size: 18,
                          ),
                          label: Text(
                            'Reader ID: '
                            '${user.readerId}',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Text(
              '#${user.id}',
              style:
                  Theme.of(
                context,
              ).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Пользователи',
        ),
        actions: [
          IconButton(
            tooltip:
                'Обновить',
            onPressed:
                _isLoading
                    ? null
                    : _load,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body:
          _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          24,
                        ),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            Text(
                              _error!,
                              textAlign:
                                  TextAlign.center,
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            FilledButton.icon(
                              onPressed:
                                  _load,
                              icon:
                                  const Icon(
                                Icons.refresh,
                              ),
                              label:
                                  const Text(
                                'Повторить',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _users.isEmpty
                      ? const Center(
                          child: Text(
                            'Пользователей нет',
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh:
                              _load,
                          child:
                              ListView.builder(
                            padding:
                                const EdgeInsets.all(
                              16,
                            ),
                            itemCount:
                                _users.length,
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              return _buildUserCard(
                                context,
                                _users[index],
                              );
                            },
                          ),
                        ),
    );
  }
}