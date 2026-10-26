import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../config/formatters.dart';
import '../models/inventario_resumen.dart';
import '../routes/app_routes.dart';
import '../services/producto_service.dart';
import '../themes/app_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/state_views.dart';

/// Pantalla principal: identidad de la app, métricas y accesos directos.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key, required this.service});

  final ProductoService service;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late Future<InventarioResumen> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.obtenerResumen();
    widget.service.cambios.addListener(_reload);
  }

  @override
  void dispose() {
    widget.service.cambios.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    setState(() => _future = widget.service.obtenerResumen());
  }

  Future<void> _refresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {
      // El error se muestra en la vista mediante el FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.inventory_2_rounded), SizedBox(width: 12), Text(AppConfig.appName)]),
        actions: [IconButton(tooltip: 'Actualizar', icon: const Icon(Icons.refresh), onPressed: _reload)],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const _HeaderBanner(),
            const SizedBox(height: 24),
            Text('Resumen del inventario', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            FutureBuilder<InventarioResumen>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasData) return _Metricas(resumen: snapshot.data!);
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 280,
                    child: ErrorView(message: '${snapshot.error}', onRetry: _reload),
                  );
                }
                return const SizedBox(height: 280, child: LoadingView(message: 'Calculando métricas...'));
              },
            ),
            const SizedBox(height: 24),
            Text('Accesos rápidos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.goNamed(AppRoutes.productos),
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('Ver productos'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => context.pushNamed(AppRoutes.productoNuevo),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Registrar producto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
            child: Icon(Icons.warehouse_rounded, size: 32, color: scheme.onPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistema de Gestión de Inventario',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Controla tus productos, existencias y valor en tiempo real.',
                  style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metricas extends StatelessWidget {
  const _Metricas({required this.resumen});

  final InventarioResumen resumen;

  @override
  Widget build(BuildContext context) {
    final cards = [
      MetricCard(
        icon: Icons.category_rounded,
        label: 'Productos registrados',
        value: Formatters.entero(resumen.totalProductos),
        color: AppTheme.metricProductos,
        caption: resumen.productosAgotados > 0 ? '${resumen.productosAgotados} agotado(s)' : 'Todos con existencias',
      ),
      MetricCard(
        icon: Icons.inventory_rounded,
        label: 'Unidades disponibles',
        value: Formatters.entero(resumen.totalUnidades),
        color: AppTheme.metricUnidades,
        caption: 'Suma de cantidades en stock',
      ),
      MetricCard(
        icon: Icons.payments_rounded,
        label: 'Valor total del inventario',
        value: Formatters.moneda(resumen.valorTotal),
        color: AppTheme.metricValor,
        caption: 'Σ precio × cantidad',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // En pantallas anchas (tablet/web) las tarjetas se muestran en fila.
        if (constraints.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, card) in cards.indexed) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: card)],
            ],
          );
        }
        return Column(
          children: [
            for (final (i, card) in cards.indexed) ...[if (i > 0) const SizedBox(height: 12), card],
          ],
        );
      },
    );
  }
}
