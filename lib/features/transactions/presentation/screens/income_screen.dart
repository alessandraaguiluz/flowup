// lib/features/transactions/presentation/screens/income_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowup/core/widgets/app_drawer.dart';
import 'package:flowup/core/theme/app_colors.dart';
import 'package:flowup/features/home/presentation/widgets/summary_card.dart';
import 'package:flowup/features/home/presentation/widgets/transaction_list_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/income_providers.dart';

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  int _selectedChipIndex = 0;
  final List<String> _chipLabels = ['Todos', 'Salario', 'Ventas', 'Otros'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    // Observamos los providers de ingresos
    final incomeListAsync = ref.watch(incomeListProvider);
    final incomeTotalAsync = ref.watch(incomeTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'INGRESOS',
          style: textTheme.displaySmall?.copyWith(
            color: theme.primaryColor,
            fontSize: 32,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refrescar los datos
          ref.invalidate(incomeListProvider);
          ref.invalidate(incomeTotalProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            // --- 1. Sección Superior (Resumen y Botón) ---
            _buildTopSection(context, incomeTotalAsync),
            const SizedBox(height: 24),

            // --- 2. Barra de Búsqueda ---
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'Buscar Ingresos',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // TODO: Implementar búsqueda
              },
            ),
            const SizedBox(height: 16),

            // --- 3. Chips de Filtro ---
            _buildFilterChips(),
            const SizedBox(height: 24),

            // --- 4. Lista de Transacciones ---
            Text(
              'TRANSACCIONES RECIENTES',
              style: textTheme.labelMedium,
            ),
            const SizedBox(height: 8),

            // Mostramos la lista usando el provider
            incomeListAsync.when(
              data: (incomes) {
                if (incomes.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No hay ingresos registrados',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: incomes.map((income) {
                    final date = income.date ?? income.createdAt;
                    final dateStr = date != null
                        ? DateFormat('dd MMM').format(date)
                        : 'Sin fecha';

                    return TransactionListTile(
                      title: income.description ?? 'Ingreso',
                      category: income.category ?? 'Sin categoría',
                      date: dateStr,
                      amount: income.amount,
                      isExpense: false,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar ingresos',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(incomeListProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, AsyncValue<String> totalAsync) {
    return Row(
      children: [
        // Tarjeta de Resumen
        Expanded(
          child: totalAsync.when(
            data: (total) {
              final amount = double.tryParse(total) ?? 0.0;
              final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
              return SummaryCard(
                title: 'TOTAL INGRESOS',
                amount: formatter.format(amount),
                color: AppColors.greenSuccess,
                onTap: () {},
              );
            },
            loading: () => const SummaryCard(
              title: 'TOTAL INGRESOS',
              amount: 'Cargando...',
              color: AppColors.greenSuccess,
              onTap: null,
            ),
            error: (_, __) => const SummaryCard(
              title: 'TOTAL INGRESOS',
              amount: '\$0.00',
              color: AppColors.greenSuccess,
              onTap: null,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Botón "Nuevo Ingreso"
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 38),
            ),
            onPressed: () {
              context.push('/income/new');
            },
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(height: 8),
                Text('Nuevo Ingreso'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_chipLabels.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(_chipLabels[index]),
              selected: _selectedChipIndex == index,
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedChipIndex = index;
                    // TODO: Implementar filtrado por categoría
                  });
                }
              },
            ),
          );
        }),
      ),
    );
  }
}
