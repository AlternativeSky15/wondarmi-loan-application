import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loan_application/Admin/admin_category_screen.dart';
import 'package:loan_application/Admin/admin_dashboard.dart';
import 'package:loan_application/Admin/admin_seen_user.dart';
import 'package:loan_application/Admin/admin_summary_screen.dart';
import 'package:loan_application/Admin/documents-review-list.dart';
import 'package:loan_application/Admin/repayment_schedule_detail.dart';
import 'package:loan_application/constant.dart'; 

class RepaymentSchedulePage extends StatefulWidget {
  const RepaymentSchedulePage({super.key});

  @override
  State<RepaymentSchedulePage> createState() => _RepaymentSchedulePageState();
}

class _RepaymentSchedulePageState extends State<RepaymentSchedulePage> {
  List repayments = [];
  bool isLoading = true;
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    fetchRepayments();
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
  Future<void> fetchRepayments() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.repaymentschedule),
      headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          repayments = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> payLoan(String loanId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loan_payment_and_schedule),
        headers: {"Content-Type": "application/json",
                  'ngrok-skip-browser-warning':'true'
        },
        body: jsonEncode({"loan_id": loanId}),
      );

      if (response.statusCode == 200) {
        fetchRepayments(); 
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ငွေသွင်းမှု အောင်မြင်ပါသည်"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
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
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.shade100.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.calendar_month_rounded,
                                  color: Colors.indigo.shade700),
                            ),
                            const SizedBox(width: 15),
                            const Text(
                              "ပြန်ဆပ်ရမည့် ငွေစာရင်းဇယား",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B254B)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 30,
                                    headingRowColor: MaterialStateProperty.all(
                                        const Color(0xFFF8FAFC)),
                                    columns: const [
                                      DataColumn(label: Text("စဉ်")),
                                      DataColumn(label: Text("ငွေချေးသူ အမည်")),
                                      DataColumn(label: Text("ချေးငွေအမျိုးအစား")),
                                      DataColumn(label: Text("ပြန်ဆပ်ရမည့်ရက်")),
                                      DataColumn(label: Text("မတည်စုငွေကျပ် (၅%)")),
                                      DataColumn(label: Text("လစဉ်ဆပ်ရမည့်ငွေ(ကျပ်)")),
                                      DataColumn(label: Text("အတိုးနှုန်း(ကျပ်)")),
                                      DataColumn(label: Text("ကျန်ရှိငွေ(ကျပ်)")),
                                      DataColumn(label: Text("လုပ်ဆောင်ချက်")),
                                    ],
                                    rows: repayments.asMap().entries.map((entry) {
                                      var item = entry.value;
                                      return DataRow(
                                        cells: [
                                          DataCell(
  Text(
    convertToMyanmarNumber((entry.key + 1).toString()),
  ),
),
                                          DataCell(Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
  Text(
    item['name'] ?? "-",
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      color: Color(0xFF1B254B),
    ),
  ),
  Text(
    item['phone'] != null && item['phone'].toString().isNotEmpty
        ? convertToMyanmarNumber(item['phone'].toString())
        : "-",
    style: TextStyle(
      color: Colors.grey.shade500,
      fontSize: 11,
    ),
  ),
],
                                          )),
                                          DataCell(Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 5),
                                            decoration: BoxDecoration(
                                                color: Colors.indigo.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            child: Text("${item['type']}",
                                                style: TextStyle(
                                                    color: Colors
                                                        .indigo.shade700,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12)),
                                          )),
                                         DataCell(
  Text(
    item['date'] != null && item['date'].toString().isNotEmpty
        ? convertToMyanmarNumber(item['date'].toString())
        : "-",
    style: const TextStyle(
      fontWeight: FontWeight.w500,
    ),
  ),
),
                                          DataCell(
  Text(
    item['compulsory_5'] != null && item['compulsory_5'].toString().isNotEmpty
        ? convertToMyanmarNumber(
            NumberFormat('#,###').format(
              num.tryParse(item['compulsory_5'].toString().replaceAll(',', '')) ?? 0,
            ),
          )
        : "-",
    style: const TextStyle(
      color: Color(0xFF0D9488),
      fontWeight: FontWeight.bold,
    ),
  ),
),
                                         DataCell(
  Text(
    item['installment'] != null && item['installment'].toString().isNotEmpty
        ? convertToMyanmarNumber(
            NumberFormat('#,###').format(
              num.tryParse(item['installment'].toString().replaceAll(',', '')) ?? 0,
            ),
          )
        : "-",
    style: const TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
),
DataCell(
  Text(
    item['interest_28'] != null && item['interest_28'].toString().isNotEmpty
        ? convertToMyanmarNumber(
            NumberFormat('#,###').format(
              num.tryParse(item['interest_28'].toString().replaceAll(',', '')) ?? 0,
            ),
          )
        : "-",
    style: const TextStyle(
      color: Colors.redAccent,
      fontWeight: FontWeight.bold,
    ),
  ),
),
DataCell(
  Text(
    item['remaining'] != null && item['remaining'].toString().isNotEmpty
        ? convertToMyanmarNumber(
            NumberFormat('#,###').format(
              num.tryParse(item['remaining'].toString().replaceAll(',', '')) ?? 0,
            ),
          )
        : "-",
    style: const TextStyle(
      color: Colors.blueAccent,
      fontWeight: FontWeight.bold,
    ),
  ),
),
                                          DataCell(Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.visibility_rounded,
                                                    color: Colors.blueAccent,
                                                    size: 20),
                                                onPressed: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            RepaymentDetailPage(
                                                                id: int.parse(item[
                                                                        'id']
                                                                    .toString())))),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons
                                                        .account_balance_wallet_rounded,
                                                    color: Color(0xFF0D9488),
                                                    size: 20),
                                                onPressed: () => payLoan(
                                                    item['id'].toString()),
                                              ),
                                            ],
                                          )),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
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
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.waves, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "WONDAMI",
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
          _sidebarMenuItem(Icons.grid_view_rounded, "မူလစာမျက်နှာ", 0, onTap: () {
            setState(() => _selectedIndex = 0);
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
          }),
          _sidebarMenuItem(Icons.layers_outlined, "ချေးငွေအမျိုးအစားများ", 1, onTap: () {
            setState(() => _selectedIndex = 1);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoanCategoriesScreen()));
          }),
          _sidebarMenuItem(Icons.people_outline, "အသုံးပြုသူများ", 2, onTap: () {
            setState(() => _selectedIndex = 2);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
          }),
          _sidebarMenuItem(Icons.calendar_today_outlined, "ပြန်ဆပ်ရမည့်ငွေဇယား", 3, onTap: () {
            setState(() => _selectedIndex = 3);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RepaymentSchedulePage()));
          }),
          _sidebarMenuItem(Icons.receipt_long_outlined, "ချေးငွေစာရွက်စာတမ်းစီစစ်ရန်", 4, onTap: () {
            setState(() => _selectedIndex = 4);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDocumentReviewScreen()));
          }),
          _sidebarMenuItem(Icons.insert_chart_outlined_rounded, "ငွေစာရင်းချုပ်", 5, onTap: () {
            setState(() => _selectedIndex = 5);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminSummaryScreen()));
          }),
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

  Widget _sidebarMenuItem(IconData icon, String title, int index, {required VoidCallback onTap}) {
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
}