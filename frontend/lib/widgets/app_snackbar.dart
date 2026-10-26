import 'package:flutter/material.dart';

import '../themes/app_theme.dart';

/// Mensajes SnackBar estandarizados para operaciones exitosas o fallidas.
class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message) {
    _show(context, message, Icons.check_circle_rounded, AppTheme.success);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Icons.error_rounded, Theme.of(context).colorScheme.error);
  }

  static void _show(BuildContext context, String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
  }
}
