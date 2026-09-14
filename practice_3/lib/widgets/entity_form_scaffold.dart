import 'package:flutter/material.dart';

class EntityFormScaffold extends StatelessWidget {
  final String title;
  final String heading;
  final String saveLabel;

  final bool isDirty;
  final bool isSaving;

  final Widget child;

  final VoidCallback onSave;
  final Future<void> Function() onExitConfirmed;

  const EntityFormScaffold({
    super.key,
    required this.title,
    required this.heading,
    required this.saveLabel,
    required this.isDirty,
    required this.isSaving,
    required this.child,
    required this.onSave,
    required this.onExitConfirmed,
  });

  Future<bool> _confirmDiscard(
    BuildContext context,
  ) async {
    if (!isDirty) {
      return true;
    }

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text(
                'Несохранённые изменения',
              ),
              content: const Text(
                'Изменения не сохранены. '
                'Покинуть страницу?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text(
                    'Остаться',
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  child: const Text(
                    'Выйти',
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _requestExit(
    BuildContext context,
  ) async {
    final canLeave =
        await _confirmDiscard(
      context,
    );

    if (!canLeave) {
      return;
    }

    await onExitConfirmed();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) async {
        if (didPop) {
          return;
        }

        await _requestExit(
          context,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Назад',
            onPressed: isSaving
                ? null
                : () {
                    _requestExit(
                      context,
                    );
                  },
            icon: const Icon(
              Icons.arrow_back,
            ),
          ),
          title: Text(title),
        ),
        body: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 750,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                children: [
                  Text(
                    heading,
                    style:
                        Theme.of(context)
                            .textTheme
                            .headlineSmall,
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  child,
                  const SizedBox(
                    height: 32,
                  ),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .end,
                    children: [
                      TextButton(
                        onPressed:
                            isSaving
                                ? null
                                : () {
                                    _requestExit(
                                      context,
                                    );
                                  },
                        child:
                            const Text(
                          'Отмена',
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      FilledButton.icon(
                        onPressed:
                            isSaving
                                ? null
                                : onSave,
                        icon: isSaving
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
                                Icons.save,
                              ),
                        label: Text(
                          saveLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}