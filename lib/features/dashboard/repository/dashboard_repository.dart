import '../../../core/network/api_endpoints.dart';
import '../../../core/network/base_repository.dart';

class MonthValue {
  MonthValue(this.month, this.income, this.expense);
  final String month;
  final num income;
  final num expense;
}

class DashboardData {
  DashboardData({
    required this.earning,
    required this.expense,
    required this.netProfit,
    required this.clients,
    required this.employees,
    required this.packages,
    required this.tasks,
    required this.orderStatus,
    required this.months,
    required this.taskStatus,
  });

  final num earning;
  final num expense;
  final num netProfit;
  final num clients;
  final num employees;
  final num packages;
  final num tasks;
  final Map<String, num> orderStatus;
  final List<MonthValue> months;
  final Map<String, num> taskStatus;
}

class DashboardRepository extends BaseRepository {
  DashboardRepository({super.dio});

  static num _n(dynamic v) => num.tryParse(v?.toString() ?? '') ?? 0;

  Future<DashboardData> load(int year) async {
    final res = await dio.get(
      ApiEndpoints.adminDashboard,
      queryParameters: {'year': year},
    );
    final b = asMap(res.data);
    final statusRaw = b['statusCounts'] is Map
        ? b['statusCounts'] as Map
        : const {};
    return DashboardData(
      earning: _n(b['earning']),
      expense: _n(b['expense']),
      netProfit: _n(b['netProfit']),
      clients: _n(b['clients']),
      employees: _n(b['employees']),
      packages: _n(b['packages']),
      tasks: _n(b['tasks']),
      orderStatus: {
        for (final e in statusRaw.entries) e.key.toString(): _n(e.value),
      },
      months: asList(b, key: 'profitByMonth')
          .map(
            (m) => MonthValue(
              (m['month'] ?? '').toString(),
              _n(m['income']),
              _n(m['expense']),
            ),
          )
          .toList(),
      taskStatus: {
        for (final t in asList(b, key: 'taskStatusCounts'))
          (t['status'] ?? '').toString(): _n(t['count']),
      },
    );
  }
}
