import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loan_application/Admin/admin_category_screen.dart';
import 'package:loan_application/Admin/admin_dashboard.dart';
import 'package:loan_application/Admin/admin_seen_user.dart';
import 'package:loan_application/Admin/documents-review-list.dart';
import 'package:loan_application/Admin/payment_schedule.dart';
import 'package:loan_application/constant.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class AdminSummaryScreen extends StatefulWidget {
  const AdminSummaryScreen({super.key});

  @override
  State<AdminSummaryScreen> createState() => _AdminSummaryScreenState();
}

class _AdminSummaryScreenState extends State<AdminSummaryScreen> {
  int _selectedIndex = 5;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  bool isLoading = true;
  Map<String, dynamic> summaryData = {};
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchSummaryData();
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

  Future<void> _fetchSummaryData() async {
    setState(() => isLoading = true);

    String formattedStart = DateFormat('yyyy-MM-dd').format(startDate);
    String formattedEnd = DateFormat('yyyy-MM-dd').format(endDate);

    final String apiUrl =
        ApiConfig.loansummary + "?start_date=$formattedStart&end_date=$formattedEnd";

    try {
      final response = await http.get(Uri.parse(apiUrl),
      headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          summaryData = json.decode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Data ရယူ၍ မရပါ (Status: ${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Server မချိတ်ဆက်နိုင်ပါ: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1D4ED8),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _fetchSummaryData();
    }
  }

  void _setQuickFilter(String type) {
    DateTime now = DateTime.now();
    if (type == 'today') {
      startDate = now;
      endDate = now;
    } else if (type == 'this_month') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
    } else if (type == 'this_year') {
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31);
    }
    _fetchSummaryData();
  }

  Future<void> _exportAndSavePdf() async {
    try {
      final pdf = pw.Document();

      String formattedStart = DateFormat('yyyy-MM-dd').format(startDate);
      String formattedEnd = DateFormat('yyyy-MM-dd').format(endDate);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Financial Summary Report",
                      style: pw.TextStyle(
                          fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text("Report Date Range: $formattedStart to $formattedEnd",
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.Divider(thickness: 1.5),
                  pw.SizedBox(height: 16),

                  pw.Text("1. Cash Flow Summary",
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Table.fromTextArray(
                    headers: ['Category', 'Amount (ကျပ်)'],
                    data: [
                      [
                        'Loan Issued (Cash Out)',
                        '${summaryData['loan_summary']?['period_loan_issued'] ?? 0}'
                      ],
                      [
                        'Loan Repaid (Cash In)',
                        '${summaryData['loan_summary']?['period_repaid_amount'] ?? 0}'
                      ],
                      [
                        'Mandatory Savings Collected',
                        '${summaryData['savings_summary']?['period_mandatory_savings'] ?? 0}'
                      ],
                      [
                        'Remaining Loan (Debt)',
                        '${summaryData['loan_summary']?['remaining_loan'] ?? 0}'
                      ],
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  pw.Text("2. Member & Loan Overview",
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Table.fromTextArray(
                    headers: ['Type', 'Count'],
                    data: [
                      [
                        'Total Customers',
                        '${summaryData['member_summary']?['total_members'] ?? 0}'
                      ],
                      [
                        'Active Borrowers',
                        '${summaryData['member_summary']?['active_borrowers'] ?? 0}'
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'Financial_Report_${formattedStart}_to_$formattedEnd.pdf';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = fileName;

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: fileName,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("PDF ထုတ်ရာတွင် Error တက်နေပါသည်: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalLoan =
        (summaryData['loan_summary']?['total_loan'] ?? 0).toDouble();
    double periodIssued =
        (summaryData['loan_summary']?['period_loan_issued'] ?? 0).toDouble();
    double periodRepaid =
        (summaryData['loan_summary']?['period_repaid_amount'] ?? 0).toDouble();
    double remainingLoan =
        (summaryData['loan_summary']?['remaining_loan'] ?? 0).toDouble();

    double compulsoryTotal =
        (summaryData['savings_summary']?['compulsory']?['total'] ?? 0)
            .toDouble();

    double compulsoryToday =
        (summaryData['savings_summary']?['compulsory']?['today'] ?? 0)
            .toDouble();

    int compulsoryMembers =
        summaryData['savings_summary']?['compulsory']?['members'] ?? 0;

    double voluntaryTotal =
        (summaryData['savings_summary']?['voluntary_total'] ?? 0).toDouble();

    double overdueAmount =
        (summaryData['overdue_summary']?['overdue_amount'] ?? 0).toDouble();

    String formattedStart = DateFormat('yyyy-MM-dd').format(startDate);
    String formattedEnd = DateFormat('yyyy-MM-dd').format(endDate);

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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildFilterPill("ဒီနေ့", () => _setQuickFilter('today')),
                                  const SizedBox(width: 8),
                                  _buildFilterPill("ဒီလ", () => _setQuickFilter('this_month')),
                                  const SizedBox(width: 8),
                                  _buildFilterPill("ဒီနှစ်", () => _setQuickFilter('this_year')),
                                ],
                              ),
                              InkWell(
                                onTap: () => _selectCustomDateRange(context),
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D4ED8),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        "ရက်စွဲ စိတ်ကြိုက်ရွေးရန်: $formattedStart မှ $formattedEnd",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  if (summaryData.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Data များ Load လုပ်နေဆဲဖြစ်သည် သို့မဟုတ် Data မရှိပါ"),
                                      ),
                                    );
                                  } else {
                                    _exportAndSavePdf();
                                  }
                                },
                                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                                label: Text(
                                  "PDF file သိမ်းမည်",
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
                                ),
                              )
                            : errorMessage.isNotEmpty
                                ? Center(
                                    child: Text(errorMessage,
                                        style: const TextStyle(color: Colors.red)))
                                : Column(
                                    children: [
                                      GridView.count(
                                        crossAxisCount:
                                            MediaQuery.of(context).size.width > 1200
                                                ? 4
                                                : MediaQuery.of(context).size.width > 800
                                                    ? 2
                                                    : 1,
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 2.3,
                                        children: [
                                          _buildKpiCard(
                                              "စုစုပေါင်းထုတ်ချေးငွေ",
                                              "${convertToMyanmarNumber(NumberFormat('#,###').format(totalLoan))} (ကျပ်)",
                                              Icons.assignment_outlined,
                                              const Color(0xFFF59E0B)),
                                          _buildKpiCard(
                                              "ပြန်လည်ရရှိငွေ",
                                              "${convertToMyanmarNumber(NumberFormat('#,###').format(periodRepaid))} (ကျပ်)",
                                              Icons.arrow_downward_rounded,
                                              const Color(0xFF10B981)),
                                          _buildKpiCard(
                                              "ကျန်ချေးငွေ",
                                              "${convertToMyanmarNumber(NumberFormat('#,###').format(remainingLoan))} (ကျပ်)",
                                              Icons.account_balance_wallet_outlined,
                                              const Color(0xFF0284C7)),
                                          _buildKpiCard(
                                              "ရက်လွန်ငွေပမာဏ",
                                              "${convertToMyanmarNumber(NumberFormat('#,###').format(overdueAmount))} (ကျပ်)",
                                              Icons.calendar_today_outlined,
                                              const Color(0xFFEF4444)),
                                          _buildKpiCard(
                                              "မဖစ်မနေရစုဆောင်းငွေ",
                                              "${convertToMyanmarNumber(NumberFormat('#,###').format(compulsoryTotal))} (ကျပ်)",
                                              Icons.savings_outlined,
                                              const Color(0xFF8B5CF6)),
                                          _buildKpiCard(
                                              "စုဆောင်းငွေစုစုပေါင်း",
                                              "${convertToMyanmarNumber(NumberFormat('#,###').format(compulsoryToday))} (ကျပ်)",
                                              Icons.today_outlined,
                                              const Color(0xFFF97316)),
                                          _buildKpiCard(
                                              "ငွေစုသူဦးရေ",
                                              convertToMyanmarNumber(NumberFormat('#,###').format(compulsoryMembers)),
                                              Icons.people_outline_rounded,
                                              const Color(0xFF6366F1)),
                                          _buildKpiCard(
                                              "ဆန္ဒအလျောက် စုဆောင်းငွေ",
                                              "${convertToMyanmarNumber(NumberFormat('#,###').format(voluntaryTotal))} (ကျပ်)",
                                              Icons.account_balance_outlined,
                                              const Color(0xFF14B8A6)),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      _buildSummaryCard(
                                        title: "ရွေးချယ်ထားသောကာလ($formattedStart မှ $formattedEnd) ငွေစာရင်းအသေးစိတ်ဖော်ပြချက် ",
                                        icon: Icons.bar_chart_rounded,
                                        color: const Color(0xFF1D4ED8),
                                        rows: [
                                          _buildDataRow(
                                              "သတ်မှတ်ကာလအတွင်း ထုတ်ချေးခဲ့သော ငွေ(ထွက်ငွေ)",
                                              "${convertToMyanmarNumber(NumberFormat('#,###').format(periodIssued))} (ကျပ်)",
                                              color: const Color(0xFFF59E0B)),
                                          _buildDataRow(
                                              "သတ်မှတ်ကာလအတွင်း ပြန်လည်ရရှိသော ချေးငွေ(ဝင်ငွေ)",
                                              "${convertToMyanmarNumber(NumberFormat('#,###').format(periodRepaid))} (ကျပ်)",
                                              isBold: true,
                                              color: const Color(0xFF10B981)),
                                          _buildDataRow(
                                              "သတ်မှတ်ကာလအတွင်း ကောက်ခံရရှိသောစုငွေ",
                                              "${summaryData['savings_summary']?['period_mandatory_savings'] ?? 0} (ကျပ်)",
                                              color: const Color(0xFF0284C7)),
                                          _buildDataRow(
                                              "လက်ရှိစုစုပေါင်းကြွေးကျန်ပမာဏ",
                                              "${convertToMyanmarNumber(NumberFormat('#,###').format(remainingLoan))} (ကျပ်)",
                                              color: const Color(0xFFEF4444)),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      _buildCompulsoryTable(),
                                    ],
                                  ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
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

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Text(
                //   "This Period",
                //   style: GoogleFonts.poppins(
                //     fontSize: 9,
                //     color: const Color(0xFF94A3B8),
                //   ),
                // ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      {required String title,
      required IconData icon,
      required Color color,
      required List<Widget> rows}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ?? const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompulsoryTable() {
    final List data = summaryData['compulsory_list'] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "မဖစ်မရေစုဆောင်းငွေစုသူဦးရေ",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF1F5F9)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              columns: const [
                DataColumn(
                  label: Text("အမည်", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text("ချေးငွေကြေးပမာဏ", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text("စုငွေပမာဏ", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
              rows: data.map<DataRow>((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item['name'] ?? "")),
                    DataCell(Text(
                      "${convertToMyanmarNumber(NumberFormat('#,###').format(item['loan_amount']))} ကျပ်",
                    )),
                    DataCell(Text(
                      "${convertToMyanmarNumber(NumberFormat('#,###').format(item['saving']))} ကျပ်",
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}