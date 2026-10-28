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
import 'package:loan_application/Admin/payment_schedule.dart';
import 'package:loan_application/constant.dart';

class RepaymentDetailPage extends StatefulWidget {
  final int id;
  const RepaymentDetailPage({super.key, required this.id});

  @override
  State<RepaymentDetailPage> createState() => _RepaymentDetailPageState();
}

class _RepaymentDetailPageState extends State<RepaymentDetailPage> {
  Map data = {};
  List schedule = [];
  bool isLoading = true;
 int _selectedIndex=3;

  @override
  void initState() {
    super.initState();
    fetchData();
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
  Future<void> fetchData() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.loan_payment_and_schedule + "?loan_id=${widget.id}"),
      headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
      );
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        setState(() {
          data = jsonData;
          schedule = jsonData['schedule'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color statusColor(String status) {
    if (status.contains("ဆပ်ပြီး")) {
      return const Color(0xFF10B981);
    } else if (status.contains("ရက်ကျော်")) {
      return const Color(0xFFEF4444);
    } else if (status.contains("ဒီနေ့ဆပ်ရမည်")) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFF64748B);
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
            // ================= SIDEBAR =================
            _buildSidebar(),

            // ================= MAIN CONTENT AREA =================
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24.0),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderBar(context),
                          const SizedBox(height: 20),
                          _buildInfoCard(),
                          const SizedBox(height: 24),
                          Text(
                            "ငွေပေးဆပ်မူ အသေးစိတ် ဇယားခွဲခြားချက်",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _buildDataTableContainer(),
                          ),
                        ],
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
                  errorBuilder: (_, __, ___) => const Icon(Icons.waves, color: Colors.white),
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

  Widget _buildHeaderBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF0F172A)),
                const SizedBox(width: 8),
                Text(
                  "နောက်သို့",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          "ချေးငွေ ပြန်ဆပ်မှု အသေးစိတ် ဇယား",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    // 💡 ID မပြတော့ဘဲ Customer Name သို့မဟုတ် 'အမည်မရှိပါ' ဟုသာ သီးသန့် ထုတ်ပေးခြင်း
    final String customerName = (data['name'] != null && data['name'].toString().trim().isNotEmpty && data['name'] != 'Unknown')
        ? data['name'].toString()
        : 'အမည်မရှိပါ';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF002984), Color(0xFF1E5BB8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002984).withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "စုစုပေါင်းကျသင့်ငွေ(ကျပ်): ",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                      ),
                      Text(
  data['total'] != null
      ? convertToMyanmarNumber(
          NumberFormat('#,###').format(
            num.tryParse(data['total'].toString().replaceAll(',', '')) ?? 0,
          ),
        )
      : convertToMyanmarNumber('0'),
  style: GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ),
)
                    ],
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "လက်ကျန်ငွေပမာဏ(ကျပ်)",
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
  data['remain_amount'] != null
      ? convertToMyanmarNumber(
          NumberFormat('#,###').format(
            num.tryParse(data['remain_amount'].toString().replaceAll(',', '')) ?? 0,
          ),
        )
      : convertToMyanmarNumber('0'),
  style: GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF4ADE80),
  ),
)
              ],
            ),
          ),
        ],
      ),
    );
  }

  

  Widget _buildDataTableContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
              horizontalMargin: 20,
              columnSpacing: 24,
              headingRowHeight: 48,
              dataRowHeight: 56,
              columns: [
                DataColumn(
                  label: Text(
                    "လ",
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Due Date (ဆပ်ရမည့်ရက်)",
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "လစဉ်ပေးသွင်းငွေ (EMI)",
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "ကျော်လွန်မှု/ကျန်ရှိမှု",
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "အခြေအနေ",
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: schedule.map<DataRow>((item) {
                final String month = (item['month_num'] ?? '').toString();
                final String date = (item['date_str'] ?? '').toString();
                final String emi = (item['emi'] ?? '0').toString();
                final String monthsLeft = (item['months_left'] ?? '-').toString();
                final String status = (item['status'] ?? '').toString();

                final Color mainStatusColor = statusColor(status);

                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
  "လ - ${month != null && month.toString().isNotEmpty ? convertToMyanmarNumber(month.toString()) : '-'}",
  style: GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF334155),
  ),
)
                      ),
                    ),
                    DataCell(
  Text(
    date != null && date.toString().isNotEmpty
        ? convertToMyanmarNumber(date.toString())
        : "-",
    style: GoogleFonts.poppins(
      fontSize: 13,
      color: const Color(0xFF334155),
    ),
  ),
),
                    DataCell(
  Text(
    emi != null && emi.toString().isNotEmpty
        ? "${convertToMyanmarNumber(
            NumberFormat('#,###').format(
              num.tryParse(emi.toString().replaceAll(',', '')) ?? 0,
            ),
          )} (ကျပ်)"
        : "- (ကျပ်)",
    style: GoogleFonts.poppins(
      fontSize: 13,
      color: const Color(0xFF2563EB),
      fontWeight: FontWeight.bold,
    ),
  ),
),
                    DataCell(
  Text(
    monthsLeft != null && monthsLeft != "-" && monthsLeft.toString().isNotEmpty
        ? convertToMyanmarNumber(monthsLeft.toString())
        : "-",
    style: GoogleFonts.poppins(
      fontSize: 13,
      color: monthsLeft == "-" || monthsLeft == null ? const Color(0xFF64748B) : const Color(0xFFEF4444),
      fontWeight: monthsLeft == "-" || monthsLeft == null ? FontWeight.normal : FontWeight.bold,
    ),
  ),
),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: mainStatusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: mainStatusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.poppins(
                            color: mainStatusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}