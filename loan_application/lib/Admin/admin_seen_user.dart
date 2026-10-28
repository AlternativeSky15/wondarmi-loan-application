import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loan_application/Admin/admin_category_screen.dart';
import 'package:loan_application/Admin/admin_summary_screen.dart';
import 'package:loan_application/Admin/documents-review-list.dart';
import 'package:loan_application/Admin/loan_detail_page.dart';
import 'package:loan_application/Admin/payment_schedule.dart';
import 'package:loan_application/constant.dart';
import 'admin_dashboard.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _customers = [];
  int _selectedIndex = 2;

  List<dynamic> _borrowers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCustomers();
    _fetchApprovedBorrowers();
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
  Future<void> _fetchApprovedBorrowers() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.approvedhistory),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _borrowers = jsonDecode(utf8.decode(response.bodyBytes));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCustomers() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.customers),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _customers = jsonDecode(utf8.decode(response.bodyBytes));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EFFC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.group_outlined,
                                  color: Color(0xFF1E5BB8), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "အသုံးပြုသူများနှင့်ငွေချေးသူများ စီမံခန့်ခွဲမှု",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 450,
                                    child: TabBar(
                                      controller: _tabController,
                                      labelColor: const Color(0xFF2563EB),
                                      unselectedLabelColor: Colors.grey.shade500,
                                      indicatorColor: const Color(0xFF2563EB),
                                      indicatorWeight: 3,
                                      indicatorSize: TabBarIndicatorSize.label,
                                      labelStyle: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      unselectedLabelStyle: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      tabs: const [
                                        Tab(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.group_outlined, size: 16),
                                              SizedBox(width: 8),
                                              Text("အကောင့်ဖွင့်ထားသူများ"),
                                            ],
                                          ),
                                        ),
                                        Tab(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text("ငွေချေးထားသူများ"),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: _isLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : TabBarView(
                                        controller: _tabController,
                                        physics: const NeverScrollableScrollPhysics(),
                                        children: [
                                          _buildUsersTable(),
                                          _buildBorrowersTable(),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildUsersTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.group_outlined,
                    color: Color(0xFF1E5BB8), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
  "အသုံးပြုသူများစာရင်း (${convertToMyanmarNumber(_customers.length.toString())}) ယောက်",
  style: GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF0F172A),
  ),

              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text("စဉ်",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xFF334155))),
                ),
                Expanded(
                  flex: 3,
                  child: Text("အမည်နှင့်အီးမေးလ်လိပ်စာ",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xFF334155))),
                ),
                Expanded(
                  flex: 2,
                  child: Text("ဆက်သွယ်ရန်ဖုန်းနံပါတ်",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xFF334155))),
                ),
                Expanded(
                  flex: 2,
                  child: Text("မှတ်ပုံတင်နံပါတ်",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xFF334155))),
                ),
              ],
            ),
          ),
          Expanded(
            child: _customers.isEmpty
                ? Center(
                    child: Text("အချက်အလက်မရှိပါ",
                        style: GoogleFonts.poppins(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _customers.length,
                    itemBuilder: (context, index) {
                      final user = _customers[index];

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade100),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8EFFC),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
  convertToMyanmarNumber((index + 1).toString()),
  style: GoogleFonts.poppins(
    fontWeight: FontWeight.bold,
    color: const Color(0xFF1E5BB8),
    fontSize: 11,
  ),
)
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['full_name'] ?? "-",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    user['email'] ?? "-",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
  user['phone_number'] != null && user['phone_number'].toString().isNotEmpty
      ? convertToMyanmarNumber(user['phone_number'].toString())
      : "-",
  style: GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF334155),
  ),
)
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8EFFC),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
  user['nrc_number'] != null && user['nrc_number'].toString().isNotEmpty
      ? convertToMyanmarNumber(user['nrc_number'].toString())
      : "-",
  style: GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF2563EB),
  ),
)
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowersTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: Color(0xFF1E5BB8), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
  "ငွေချေးသူများစာရင်း (${convertToMyanmarNumber(_borrowers.length.toString())} ယောက်)",
  style: GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF0F172A),
  ),
)
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text("စဉ်",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xFF334155))),
                ),
                Expanded(
                  flex: 3,
                  child: Text("အမည်နှင့်ဖုန်းနံပါတ်",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xFF334155))),
                ),
                Expanded(
                  flex: 2,
                  child: Text("ချေးငွေပမာဏ",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xFF334155))),
                ),
                Expanded(
                  flex: 2,
                  child: Text("အခြေအနေ",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xFF334155))),
                ),
                const SizedBox(
                  width: 60,
                  child: Center(
                      child: Text("လုပ်ဆောင်ချက်",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF334155)))),
                ),
              ],
            ),
          ),
          Expanded(
            child: _borrowers.isEmpty
                ? Center(
                    child: Text("အချက်အလက်မရှိပါ",
                        style: GoogleFonts.poppins(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _borrowers.length,
                    itemBuilder: (context, index) {
                      final b = _borrowers[index];

                      String name = b['full_name']?.toString() ?? "N/A";
                      String phone = b['phone_number']?.toString() ?? "N/A";
                      var amount = b['amount']?.toString().replaceAll(',', '') ?? '0';
                      String status =
                          b['status']?.toString().toUpperCase() ?? "PENDING";

                      Color statusColor = status == "APPROVED"
                          ? Colors.green
                          : (status == "REJECTED" ? Colors.red : Colors.orange);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade100),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8EFFC),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
  convertToMyanmarNumber((index + 1).toString()),
  style: GoogleFonts.poppins(
    fontWeight: FontWeight.bold,
    color: const Color(0xFF1E5BB8),
    fontSize: 11,
  ),
)
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: const Color(0xFF0F172A))),
                                  Text(
  phone != null && phone.toString().isNotEmpty
      ? convertToMyanmarNumber(phone.toString())
      : "-",
  style: GoogleFonts.poppins(
    fontSize: 11,
    color: Colors.grey.shade500,
  ),
)
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child:Text(
  convertToMyanmarNumber(
    NumberFormat('#,###').format(num.tryParse(amount.toString()) ?? 0),
  ),
  style: GoogleFonts.poppins(
    fontWeight: FontWeight.bold,
    fontSize: 12,
    color: const Color(0xFF0F172A),
  ),
)
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Center(
                                child: IconButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          LoanDetailView(loanId: b['id']),
                                    ),
                                  ),
                                  icon: const Icon(
                                      Icons.remove_red_eye_rounded,
                                      color: Color(0xFF1E5BB8),
                                      size: 18),
                                  splashRadius: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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