import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/auth_session.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final session =
        context.watch<AuthSession>();

    final user =
        session.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Доступ запрещён',
        ),
      ),
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            24,
          ),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 520,
            ),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  32,
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .lock_outline,
                      size: 72,
                      color:
                          Theme.of(
                        context,
                      )
                              .colorScheme
                              .error,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Text(
                      'Доступ запрещён',
                      textAlign:
                          TextAlign
                              .center,
                      style:
                          Theme.of(
                        context,
                      )
                              .textTheme
                              .headlineSmall,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    const Text(
                      'У вашей роли нет прав '
                      'для открытия этой страницы.',
                      textAlign:
                          TextAlign.center,
                    ),

                    if (user != null) ...[
                      const SizedBox(
                        height: 20,
                      ),

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Theme.of(
                            context,
                          )
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              user.name,
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              'Роль: ${user.role.title}',
                              textAlign:
                                  TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 24,
                    ),

                    FilledButton.icon(
                      onPressed: () {
                        context.go(
                          '/books',
                        );
                      },
                      icon: const Icon(
                        Icons
                            .menu_book_outlined,
                      ),
                      label: const Text(
                        'Перейти к каталогу',
                      ),
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