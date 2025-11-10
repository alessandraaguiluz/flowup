// lib/features/transactions/presentation/screens/expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowup/core/widgets/app_drawer.dart';
import 'package:flowup/core/theme/app_colors.dart';
import 'package:flowup/features/home/presentation/widgets/summary_card.dart';
import 'package:flowup/features/home/presentation/widgets/transaction_list_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/expense_providers.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  int _selectedChipIndex = 0;
  final List<String> _chipLabels = ['Todos', 'Comida', 'Transporte', 'Ocio'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    // Observamos los providers de gastos
    final expenseListAsync = ref.watch(expenseListProvider);
    final expenseTotalAsync = ref.watch(expenseTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GASTOS',
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
          ref.invalidate(expenseListProvider);
          ref.invalidate(expenseTotalProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            // --- 1. Sección Superior (Resumen y Botón) ---
            _buildTopSection(context, expenseTotalAsync),
            const SizedBox(height: 24),

            // --- 2. Barra de Búsqueda ---
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'Buscar Gastos',
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
            expenseListAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No hay gastos registrados',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: expenses.map((expense) {
                    final date = expense.date ?? expense.createdAt;
                    final dateStr = date != null
                        ? DateFormat('dd MMM').format(date)
                        : 'Sin fecha';

                    return TransactionListTile(
                      title: expense.description ?? 'Gasto',
                      category: expense.category ?? 'Sin categoría',
                      date: dateStr,
                      amount: expense.amount,
                      isExpense: true,
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
                        'Error al cargar gastos',
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
                          ref.invalidate(expenseListProvider);
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
                title: 'TOTAL GASTOS',
                amount: formatter.format(amount),
                color: AppColors.redError,
                onTap: () {},
              );
            },
            loading: () => const SummaryCard(
              title: 'TOTAL GASTOS',
              amount: 'Cargando...',
              color: AppColors.redError,
              onTap: null,
            ),
            error: (_, __) => const SummaryCard(
              title: 'TOTAL GASTOS',
              amount: '\$0.00',
              color: AppColors.redError,
              onTap: null,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Botón "Nuevo Gasto"
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 38),
            ),
            onPressed: () {
              context.push('/expenses/new');
            },
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(height: 8),
                Text('Nuevo Gasto'),
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
