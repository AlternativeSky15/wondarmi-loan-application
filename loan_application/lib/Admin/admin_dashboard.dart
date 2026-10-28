import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loan_application/Admin/admin_category_screen.dart';
import 'package:loan_application/Admin/admin_seen_user.dart';
import 'package:loan_application/Admin/admin_summary_screen.dart';
import 'package:loan_application/Admin/documents-review-list.dart';
import 'package:loan_application/Admin/payment_schedule.dart';
import 'package:loan_application/Admin/admin_payment_requests.dart';
import 'package:loan_application/constant.dart';

class DashboardData {
  final Map<String, dynamic> stats;
  final Map<String, dynamic> charts;
  final List<dynamic> repayments;

  DashboardData({
    required this.stats,
    required this.charts,
    required this.repayments,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stats: json['stats'] ?? {},
      charts: json['charts'] ?? {},
      repayments: json['repayments'] ?? [],
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<DashboardData> _dashboardFuture;
  final String apiUrl = ApiConfig.dashboard;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _dashboardFuture = _fetchDashboardData();
    });
  }

  String convertToMyanmarNumber(dynamic number) {
    String english = number.toString();
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const myanmarDigits = ['၀', '၁', '၂', '၃', '၄', '၅', '၆', '၇', '၈', '၉'];

    String result = english;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(englishDigits[i], myanmarDigits[i]);
    }
    return result;
  }

  Future<DashboardData> _fetchDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        var decoded = json.decode(response.body);
        List repayments = decoded['repayments'] ?? [];
        repayments.sort(
          (a, b) => (a['date']?.toString() ?? "").compareTo(
            b['date']?.toString() ?? "",
          ),
        );
        decoded['repayments'] = repayments;

        return DashboardData.fromJson(decoded);
      }
      throw Exception(
        'Failed to load dashboard data (Status Code: ${response.statusCode})',
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F43A2),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: FutureBuilder<DashboardData>(
                    future: _dashboardFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2563EB),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 60,
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Text(
                                  "${snapshot.error}",
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                ),
                                child: const Text(
                                  "Retry",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final data = snapshot.data!;
                      final stats = data.stats;
                      final charts = data.charts;
                      final repayments = data.repayments;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopHeader(stats),
                            const SizedBox(height: 24),
                            _buildTopStatCards(stats),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: _buildPieChartCard(stats),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 6,
                                  child: _buildChartContainer(
                                    title: "လစဉ်ချေးငွေလျှောက်ထားမှုအခြေ‌အနေ",
                                    action: const SizedBox(),
                                    child: UserActivityChart(
                                      userActivityData: charts['user_activity'],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _buildSummaryOverviewBars(
                                    charts,
                                    stats,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            _buildRecentTransactionsTable(repayments),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E5BB8),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  "assets/image/Logo2.PNG",
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.waves, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ဝန္ဒာမိ",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "ချေးငွေလုပ်ငန်း",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          _sidebarMenuItem(
            Icons.grid_view_rounded,
            "မူလစာမျက်နှာ",
            0,
            onTap: () {
              setState(() => _selectedIndex = 0);
            },
          ),
          _sidebarMenuItem(
            Icons.layers_outlined,
            "ချေးငွေအမျိုးအစားများ",
            1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoanCategoriesScreen()),
              );
            },
          ),
          _sidebarMenuItem(
            Icons.people_outline,
            "အသုံးပြုသူများ",
            2,
            onTap: () {
              setState(() => _selectedIndex = 2);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
              );
            },
          ),
          _sidebarMenuItem(
            Icons.calendar_today_outlined,
            "ပြန်ဆပ်ရမည့်ငွေဇယား",
            3,
            onTap: () {
              setState(() => _selectedIndex = 3);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const RepaymentSchedulePage(),
                ),
              );
            },
          ),
          _sidebarMenuItem(
            Icons.receipt_long_outlined,
            "ချေးငွေစာရွက်စာတမ်းစီစစ်ရန်",
            4,
            onTap: () {
              setState(() => _selectedIndex = 4);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminDocumentReviewScreen(),
                ),
              );
            },
          ),
          _sidebarMenuItem(
            Icons.insert_chart_outlined_rounded,
            "ငွေစာရင်းချုပ်",
            5,
            onTap: () {
              setState(() => _selectedIndex = 5);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminSummaryScreen()),
              );
            },
          ),
          const Spacer(),
          Opacity(
            opacity: 0.2,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarMenuItem(
    IconData icon,
    String title,
    int index, {
    required VoidCallback onTap,
  }) {
    bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTopHeader(Map<String, dynamic> stats) {
    int pendingCount =
        int.tryParse(stats['pending_payment_count']?.toString() ?? "0") ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "မင်္ဂလာပါ၊အက်ဒမင် ဒက်ရှ်ဘုတ် မှ သင့်လုပ်ငန်းများကိုထိရောက်လွယ်ကူစွာစီမံခန့်ခွဲနိုင်ရန် အသင့်ရှိနေပါသည်။",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            // Text(
            //   "Welcome to your personalized dashboard panel.",
            //   style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
            // ),
          ],
        ),
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminPaymentRequestsScreen(),
                      ),
                    );
                  },
                ),
                if (pendingCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        convertToMyanmarNumber(
                          pendingCount > 99 ? '99+' : pendingCount,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE2E8F0),
              child: Icon(Icons.person_outline, size: 18, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopStatCards(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: "စုစုပေါင်းလျှောက်လွှာများ",
            value: convertToMyanmarNumber(
              NumberFormat('#,###').format(
                int.tryParse(stats['total_loans']?.toString() ?? "0") ?? 0,
              ),
            ),
            icon: Icons.article_outlined,
            iconBgColor: const Color(0xFF2563EB),
            badgeColor: Colors.blue.shade50,
            badgeTextColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        // Expanded(
        //   child: _statCard(
        //     title: "ငွေလွှဲအတည်ပြုရန်",
        //     value: convertToMyanmarNumber(
        //       NumberFormat('#,###').format(
        //         int.tryParse(stats['pending_payment_count']?.toString() ?? "0") ?? 0,
        //       ),
        //     ),
        //     icon: Icons.account_balance_wallet_outlined,
        //     iconBgColor: const Color(0xFFF97316),
        //     badgeColor: Colors.orange.shade50,
        //     badgeTextColor: Colors.orange,
        //   ),
        // ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            title: "ခွင့်ပြုပြီး",
            value: convertToMyanmarNumber(
              NumberFormat(
                '#,###',
              ).format(int.tryParse(stats['approved']?.toString() ?? "0") ?? 0),
            ),
            icon: Icons.check_circle_outline,
            iconBgColor: const Color(0xFF10B981),
            badgeColor: Colors.green.shade50,
            badgeTextColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(Map<String, dynamic> stats) {
    final double totalPaid =
        double.tryParse(stats['total_paid']?.toString() ?? '0') ?? 0.0;
    final double totalRemain =
        double.tryParse(stats['total_remain']?.toString() ?? '0') ?? 0.0;
    final double totalAmount = totalPaid + totalRemain;

    final double paidPercent =
        totalAmount > 0 ? (totalPaid / totalAmount) * 100 : 0.0;
    final double remainPercent =
        totalAmount > 0 ? (totalRemain / totalAmount) * 100 : 0.0;

    return _buildChartContainer(
      title: "ငွေပြန်ဆပ်မှုအခြေအနေ",
      action: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
      child: SizedBox(
        height: 180,
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 35,
                  startDegreeOffset: 270,
                  sections: [
                    PieChartSectionData(
                      color: const Color(0xFFEF4444),
                      value: paidPercent > 0 ? paidPercent : 0.001,
                      radius: 20,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      color: const Color(0xFF10B981),
                      value: remainPercent > 0 ? remainPercent : 0.001,
                      radius: 20,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _indicatorRow(
                  color: const Color(0xFFEF4444),
                  text: "ဆပ်ပြီး",
                  percent:
                      "${convertToMyanmarNumber(paidPercent.toStringAsFixed(1))}%",
                ),
                const SizedBox(height: 12),
                _indicatorRow(
                  color: const Color(0xFF10B981),
                  text: "ဆပ်ရန်ကျန်ရှိ",
                  percent:
                      "${convertToMyanmarNumber(remainPercent.toStringAsFixed(1))}%",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicatorRow({
    required Color color,
    required String text,
    required String percent,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Text(
          percent,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryOverviewBars(
    Map<String, dynamic> charts,
    Map<String, dynamic> stats,
  ) {
    List<String> categories = [];
    List<dynamic> counts = [];

    if (charts['categories'] != null && charts['categories'] is List) {
      categories = List<String>.from(charts['categories']);
    }

    if (charts['counts'] != null && charts['counts'] is List) {
      counts = List.from(charts['counts']);
    }

    if (categories.isEmpty) {
      categories = [
        "စိုက်ပျိုးရေးချေးငွေ",
        "သုံးစွဲမှုချေးငွေ",
        "အသေးစားစီးပွားရေးလုပ်ငန်းချေးငွေ",
      ];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "လျှောက်ထားမှုအများဆုံးချေးငွေအမျိုးအစားများ",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "သုံးစွဲသူများ အများဆုံးစိတ်ဝင်စားသောချေးငွေအမျိုးအစားများ",
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              String catName = categories[i];
              int countVal =
                  i < counts.length
                      ? (int.tryParse(counts[i].toString()) ?? 0)
                      : 2;
              double progressValue =
                  countVal > 0 ? (countVal / 20).clamp(0.05, 1.0) : 0.02;

              List<Color> barColors = [
                const Color(0xFF2563EB),
                const Color(0xFF10B981),
                const Color(0xFF8B5CF6),
                const Color(0xFFEF4444),
                const Color(0xFFF59E0B),
              ];
              Color currentColor = barColors[i % barColors.length];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 170,
                      child: Text(
                        catName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          color: currentColor,
                          backgroundColor: Colors.grey.shade100,
                          minHeight: 7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      convertToMyanmarNumber(countVal),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsTable(List repayments) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ငွေချေးသူများစာရင်း",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "မကြာသေးမီက ငွေချေးထားသူများ၏ အချက်အလက်များ",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          repayments.isEmpty
              ? Padding(
                padding: const EdgeInsets.all(30.0),
                child: Center(
                  child: Text(
                    "ငွေချေးထားသူများမရှိပါ",
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
              : LayoutBuilder(
                builder: (context, constraints) {
                  double totalWidth = constraints.maxWidth;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: totalWidth),
                      child: DataTable(
                        columnSpacing: 10,
                        horizontalMargin: 0,
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFFF8FAFC),
                        ),
                        columns: [
                          DataColumn(
                            label: SizedBox(
                              width: totalWidth * 0.08,
                              child: const Text(
                                "စဉ်",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: totalWidth * 0.22,
                              child: const Text(
                                "အမည်",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: totalWidth * 0.20,
                              child: const Text(
                                "ဖုန်းနံပါတ်",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: totalWidth * 0.25,
                              child: const Text(
                                "ချေးငွေပမာဏ (ကျပ်)",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: totalWidth * 0.15,
                              child: const Text(
                                "အခြေအနေ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                        rows: List.generate(repayments.length, (index) {
                          final item = repayments[index];

                          String name =
                              item['name'] ??
                              item['user']?['full_name'] ??
                              "N/A";
                          String phone =
                              item['phone'] ??
                              item['user']?['phone_number'] ??
                              "N/A";
                          num amount =
                              num.tryParse(
                                item['principal']?.toString() ??
                                    item['amount']?.toString() ??
                                    "0",
                              ) ??
                              0;

                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: totalWidth * 0.08,
                                  child: Text(
                                    convertToMyanmarNumber(index + 1),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: totalWidth * 0.22,
                                  child: Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: totalWidth * 0.20,
                                  child: Text(convertToMyanmarNumber(phone)),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: totalWidth * 0.25,
                                  child: Text(
                                    "${convertToMyanmarNumber(NumberFormat('#,###').format(amount))} ကျပ်",
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: totalWidth * 0.15,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "Approved",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _buildChartContainer({
    required String title,
    required Widget action,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              action,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class UserActivityChart extends StatelessWidget {
  final Map<String, dynamic>? userActivityData;

  const UserActivityChart({super.key, this.userActivityData});

  @override
  Widget build(BuildContext context) {
    if (userActivityData == null || userActivityData!['spots'] == null) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text("No Chart Data Available")),
      );
    }

    List dynamicSpots = userActivityData!['spots'] ?? [];
    List<FlSpot> spots =
        dynamicSpots.map((item) {
          return FlSpot(
            (item['x'] as num).toDouble(),
            (item['y'] as num).toDouble(),
          );
        }).toList();

    List<String> monthLabels = List<String>.from(
      userActivityData!['labels'] ?? [],
    );

    // 💡 [CRASH FIX] Max Y ကို spots ထဲမှ အမြင့်ဆုံး Value + Margin ဖြင့် Dynamic ရှာဖွေခြင်း
    double calculatedMaxY = 10.0;
    for (var spot in spots) {
      if (spot.y > calculatedMaxY) {
        calculatedMaxY = spot.y;
      }
    }
    double maxY = calculatedMaxY + 5.0; // Margin ထည့်ထားပါသည်

    return SizedBox(
      height: 180,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 11,
          minY: 0,
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine:
                (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < monthLabels.length) {
                    String label = monthLabels[index];
                    return Text(
                      label.length >= 3 ? label.substring(0, 3) : label,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
              isCurved: true,
              color: const Color(0xFF8B5CF6),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter:
                    (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 3,
                      color: const Color(0xFF8B5CF6),
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.3),
                    const Color(0xFF8B5CF6).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
