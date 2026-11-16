import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/auth/session_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/state_views.dart';
import '../../orders/model/order_model.dart';
import '../../tasks/model/task_model.dart';
import '../controller/dashboard_controller.dart';
import '../repository/dashboard_repository.dart';

/// Admin "Dashboard" tab.
class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final name = SessionService.to.user.value?.name ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          name.isEmpty ? 'Dashboard' : 'Hi, ${name.split(' ').first}',
        ),
        actions: [
          IconButton(
            onPressed: () => controller.changeYear(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Obx(
            () => Center(
              child: Text(
                '${controller.year.value}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Obx(
            () => IconButton(
              onPressed: controller.year.value >= DateTime.now().year
                  ? null
                  : () => controller.changeYear(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final d = controller.data.value;
        if (d == null) {
          return controller.error.isNotEmpty
              ? ErrorView(
                  message: controller.error.value,
                  onRetry: controller.load,
                )
              : const ShimmerList(count: 5, itemHeight: 100);
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.isLoading.value)
                const LinearProgressIndicator(minHeight: 2),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.7,
                children: [
                  _Stat(
                    'Income',
                    Formatters.taka(d.earning.round()),
                    Icons.trending_up,
                    AppColors.success,
                  ),
                  _Stat(
                    'Expenses',
                    Formatters.taka(d.expense.round()),
                    Icons.trending_down,
                    AppColors.error,
                  ),
                  _Stat(
                    'Net profit',
                    Formatters.taka(d.netProfit.round()),
                    Icons.account_balance_wallet_outlined,
                    d.netProfit >= 0 ? AppColors.primary : AppColors.error,
                  ),
                  _Stat(
                    'Clients',
                    '${d.clients}',
                    Icons.people_outline,
                    AppColors.inkSoft,
                  ),
                  _Stat(
                    'Team',
                    '${d.employees}',
                    Icons.groups_outlined,
                    AppColors.inkSoft,
                  ),
                  _Stat(
                    'Packages',
                    '${d.packages}',
                    Icons.inventory_2_outlined,
                    AppColors.inkSoft,
                  ),
                ],
              ),
              if (d.months.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Income vs expenses',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    _Legend('Income', AppColors.primary),
                    SizedBox(width: 14),
                    _Legend('Expenses', Color(0xFFFCA5A5)),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _MonthBars(months: d.months),
                  ),
                ),
              ],
              if (d.orderStatus.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Orders',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final e in d.orderStatus.entries)
                        ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.circle,
                            size: 12,
                            color: StatusStyle.order(e.key).color,
                          ),
                          title: Text(StatusStyle.order(e.key).label),
                          trailing: Text(
                            '${e.value}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (d.taskStatus.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Tasks',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final e in d.taskStatus.entries)
                        ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.circle,
                            size: 12,
                            color: TaskStatusStyle.of(e.key).color,
                          ),
                          title: Text(TaskStatusStyle.of(e.key).label),
                          trailing: Text(
                            '${e.value}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    ],
  );
}

/// Grouped bars per month, scaled to the year's highest value.
class _MonthBars extends StatelessWidget {
  const _MonthBars({required this.months});
  final List<MonthValue> months;

  @override
  Widget build(BuildContext context) {
    final maxValue = months.fold<num>(
      1,
      (m, v) => [m, v.income, v.expense].reduce((a, b) => a > b ? a : b),
    );
    const height = 140.0;
    return SizedBox(
      height: height + 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final m in months)
            Expanded(
              child: Tooltip(
                message:
                    '${m.month}\nIncome ${Formatters.taka(m.income.round())}\nExpenses ${Formatters.taka(m.expense.round())}',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _bar(m.income / maxValue * height, AppColors.primary),
                        const SizedBox(width: 2),
                        _bar(
                          m.expense / maxValue * height,
                          const Color(0xFFFCA5A5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.month.length > 3 ? m.month.substring(0, 3) : m.month,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(double h, Color c) => Container(
    width: 7,
    height: h.clamp(2, 140).toDouble(),
    decoration: BoxDecoration(
      color: c,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
    ),
  );
}
