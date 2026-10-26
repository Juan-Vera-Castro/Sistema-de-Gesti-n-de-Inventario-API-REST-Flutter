import 'package:flutter/material.dart';

/// Indicador de carga centrado.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Cargando...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(message)],
      ),
    );
  }
}

/// Mensaje centrado con ícono y acción opcional (base de error y vacío).
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color ?? theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de error con botón para reintentar.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return MessageView(
      icon: Icons.cloud_off_rounded,
      title: 'Algo salió mal',
      message: message,
      color: Theme.of(context).colorScheme.error,
      actionLabel: onRetry == null ? null : 'Reintentar',
      actionIcon: Icons.refresh,
      onAction: onRetry,
    );
  }
}

/// Estado de lista vacía.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, this.message, this.actionLabel, this.onAction});

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return MessageView(
      icon: Icons.inventory_2_outlined,
      title: title,
      message: message,
      actionLabel: actionLabel,
      actionIcon: Icons.add,
      onAction: onAction,
    );
  }
}
