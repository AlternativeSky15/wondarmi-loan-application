import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loan_application/Admin/admin_category_screen.dart';
import 'package:loan_application/Admin/admin_dashboard.dart';
import 'package:loan_application/Admin/admin_seen_user.dart';
import 'package:loan_application/Admin/admin_summary_screen.dart';
import 'package:loan_application/Admin/payment_schedule.dart';
import 'package:loan_application/constant.dart';

class AdminDocumentReviewScreen extends StatefulWidget {
  const AdminDocumentReviewScreen({super.key});

  @override
  State<AdminDocumentReviewScreen> createState() =>
      _AdminDocumentReviewScreenState();
}

class _AdminDocumentReviewScreenState extends State<AdminDocumentReviewScreen> {
  int _selectedIndex = 4; // Loan Transactions / Document Review Index

  List<dynamic> _documentList = [];
  bool _isLoading = true;
  dynamic _selectedDocumentId;
  Map<String, dynamic>? _selectedDocData;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _monthController = TextEditingController(
    text: "12",
  );
  final TextEditingController _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDocumentList();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _monthController.dispose();
    _remarkController.dispose();
    super.dispose();
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

  // 🔄 Fetch API Data
  Future<void> _fetchDocumentList() async {
    setState(() => _isLoading = true);
    try {
      String url = ApiConfig.documentreviewlist;
      if (url.contains('ngrok') && url.startsWith('http://')) {
        url = url.replaceFirst('http://', 'https://');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> listData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        setState(() {
          _documentList = listData;
          _isLoading = false;
          if (_documentList.isNotEmpty && _selectedDocumentId == null) {
            _selectDocument(_documentList.first);
          }
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _selectDocument(dynamic item) {
    setState(() {
      _selectedDocData = item;
      _selectedDocumentId = item['id'] ?? item['document_id'];
      _amountController.text = item['amount']?.toString() ?? "";
    });
  }

  // 💾 Approved / Rejected Decision
  Future<void> _submitDecision(String action) async {
    if (_selectedDocData == null) return;

    if (action == 'approved' &&
        (_amountController.text.trim().isEmpty ||
            _monthController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ခွင့်ပြုမည့် ပမာဏနှင့် သက်တမ်းလ ထည့်ပါ")),
      );
      return;
    }

    try {
      String apiEndpoint = ApiConfig.processloandecision;
      // 💡 Ngrok URL ဖြစ်မှသာ https:// သို့ ပြောင်းမည် (Local IP အတွက် http:// အတိုင်း ထားမည်)
      if (apiEndpoint.contains('ngrok') && apiEndpoint.startsWith('http://')) {
        apiEndpoint = apiEndpoint.replaceFirst('http://', 'https://');
      }

      final docId = _selectedDocData!['id'] ?? _selectedDocData!['document_id'];

      if (docId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Document ID ရှာမတွေ့ပါ")));
        return;
      }

      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          "document_id": docId,
          "action": action,
          "amount": _amountController.text.trim(),
          "month": _monthController.text.trim(),
          "remark": _remarkController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      action == 'approved' ? Icons.check_circle : Icons.cancel,
                      color: action == 'approved' ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      action == 'approved'
                          ? "အတည်ပြုပြီးပါပြီ"
                          : "ငြင်းပယ်ပြီးပါပြီ",
                    ),
                  ],
                ),
                content: Text(
                  action == 'approved'
                      ? "အသုံးပြုသူထံ အကြောင်းကြားစာ ပေးပို့လိုက်ပါပြီ"
                      : "အသုံးပြုသူထံ လျှောက်လွှာ ပယ်ဖျက်ကြောင်း အကြောင်းကြားစာ ပေးပို့လိုက်ပါပြီ။",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _fetchDocumentList();
                    },
                    child: const Text("အိုကေ"),
                  ),
                ],
              ),
        );
      } else {
        if (!mounted) return;
        String errorMsg = "Server Error: ${response.statusCode}";
        try {
          final resBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (resBody is Map) {
            errorMsg =
                resBody['error'] ??
                resBody['detail'] ??
                resBody['message'] ??
                errorMsg;
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Decision Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ကွန်ရက်ချိတ်ဆက်မှုကို စစ်ဆေးပါ: $e")),
      );
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
            // 1️⃣ LEFT SIDEBAR
            _buildSidebar(),

            // 2️⃣ MAIN CONTAINER
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Row(
                            children: [
                              _buildApplicationListPanel(),
                              Expanded(child: _buildApplicationDetailsPanel()),
                              _buildDecisionPanel(),
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

  // 📌 1. SIDEBAR DESIGN
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
          _sidebarMenuItem(
            Icons.grid_view_rounded,
            "မူလစာမျက်နှာ",
            0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboard()),
              );
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

  // 📌 2. LEFT PANEL - APPLICATION LIST
  Widget _buildApplicationListPanel() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ချေးငွေစာရွက်စာတမ်းများ",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _documentList.isEmpty
                    ? const Center(child: Text("လျှောက်လွှာများ မရှိသေးပါ"))
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: _documentList.length,
                      itemBuilder: (context, index) {
                        final item = _documentList[index];
                        final docId = item['id'] ?? item['document_id'];
                        final bool isSelected = docId == _selectedDocumentId;
                        final String status =
                            (item['status'] ?? 'pending')
                                .toString()
                                .toLowerCase();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                isSelected
                                    ? Border.all(color: const Color(0xFFBFDBFE))
                                    : null,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            onTap: () => _selectDocument(item),
                            title: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['full_name'] != null &&
                                            item['full_name']
                                                .toString()
                                                .isNotEmpty
                                        ? convertToMyanmarNumber(
                                          item['full_name'].toString(),
                                        )
                                        : 'U Aung',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(left: 16, top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        convertToMyanmarNumber(
                                          item['phone_number'] != null &&
                                                  item['phone_number']
                                                      .toString()
                                                      .isNotEmpty
                                              ? item['phone_number'].toString()
                                              : '09452480669',
                                        ),
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.monetization_on_outlined,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['amount'] != null &&
                                                item['amount']
                                                    .toString()
                                                    .isNotEmpty
                                            ? "${convertToMyanmarNumber(NumberFormat('#,###').format(num.tryParse(item['amount'].toString().replaceAll(',', '')) ?? 0))} (ကျပ်)"
                                            : "${convertToMyanmarNumber('400,000')} (ကျပ်)",
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        status == 'approved'
                                            ? const Color(0xFFDCFCE7)
                                            : status == 'rejected'
                                            ? const Color(0xFFFEE2E2)
                                            : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          status == 'approved'
                                              ? const Color(0xFF166534)
                                              : status == 'rejected'
                                              ? const Color(0xFF991B1B)
                                              : const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // 📌 3. MIDDLE PANEL - DETAILS & DOCUMENT IMAGES GRID
  Widget _buildApplicationDetailsPanel() {
    if (_selectedDocData == null) {
      return const Center(child: Text("ရွေးချယ်ထားသော လျှောက်လွှာမရှိပါ"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "တင်သွင်းထားသောစာရွက်စာတမ်းများ",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // Customer Profile Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFDBEAFE),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF2563EB),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDocData!['full_name'] ?? 'Aye Myat Thu',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "အလုပ်အကိုင်: ${_selectedDocData!['occupation'] ?? 'Audio Engineer'}   |   ဖုန်းနံပါတ်: ${convertToMyanmarNumber(_selectedDocData!['phone_number']?.toString() ?? '09979781236')}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Color(0xFF64748B)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section Title
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              Text(
                "တင်သွင်းထားသောစာရွက်စာတမ်းများ(ဓါတ်ပုံ)",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Document Cards Grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildDocumentCard(
                "မှတ်ပုံတင်(ရှေ့)",
                _selectedDocData!['nrc_photo_front'],
              ),
              _buildDocumentCard(
                "မှတ်ပုံတင်(နောက်)",
                _selectedDocData!['nrc_photo_back'],
              ),
              _buildDocumentCard(
                "အိမ်ထောင်စု(ရှေ့)",
                _selectedDocData!['household_list_photo_front'],
              ),
              _buildDocumentCard(
                "အိမ်ထောင်စု(နောက်)",
                _selectedDocData!['household_list_photo_back'],
              ),
              _buildDocumentCard(
                "ပိုင်ဆိုင်မှုစာရွက်",
                _selectedDocData!['ownership_image'],
              ),
              _buildDocumentCard(
                "လုပ်ငန်းလိုင်စင်",
                _selectedDocData!['business_license_photo_front'],
              ),
              _buildDocumentCard(
                "မျက်နှာစကန်",
                _selectedDocData!['face_scan_photo'],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String title, String? imageUrl) {
    bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              width: 140,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  style: BorderStyle.solid,
                ),
              ),
              child:
                  hasImage
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        // 💡 Image.network အစား Safe ဖြစ်သည့် NgrokImage Widget ကို အသုံးပြုထားပါသည်
                        child: NgrokImage(imageString: imageUrl),
                      )
                      : _uploadPlaceholder(),
            ),
            if (hasImage)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _uploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            color: Color(0xFF2563EB),
            size: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Upload Image",
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2563EB),
          ),
        ),
        Text(
          "PNG, JPG up to 5MB",
          style: GoogleFonts.poppins(
            fontSize: 8,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // 📌 4. RIGHT PANEL - APPLICATION DECISION
  Widget _buildDecisionPanel() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            "ခွင့်ပြုချက်သတ်မှတ်ပါ",
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 24),

          _buildInputField(
            "ခွင့်ပြုမည့်ပမာဏ (ကျပ်)",
            _amountController,
            icon: Icons.account_balance_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                return newValue.copyWith(
                  text: convertToMyanmarNumber(newValue.text),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          _buildInputField(
            "ဆပ်ရမည့်သက်တမ်း(လ)",
            _monthController,
            icon: Icons.account_balance_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                return newValue.copyWith(
                  text: convertToMyanmarNumber(newValue.text),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          const Spacer(),

          // REJECT Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () => _submitDecision('rejected'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.close, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "ငြင်းပယ်သည်",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // APPROVE Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () => _submitDecision('approved'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "လက်ခံသည်",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Opacity(
            opacity: 0.8,
            child: Image.network(
              "https://img.freepik.com/free-vector/blue-curve-background_53876-113112.jpg",
              height: 40,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

// 💡 Ngrok / CORS / HTTP Redirect များကို ကျော်လွှား၍ ပုံဆွဲယူပေးသော Widget
class NgrokImage extends StatefulWidget {
  final String? imageString;

  const NgrokImage({super.key, required this.imageString});

  @override
  State<NgrokImage> createState() => _NgrokImageState();
}

class _NgrokImageState extends State<NgrokImage> {
  Uint8List? _bytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant NgrokImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageString != widget.imageString) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final raw = widget.imageString;
    if (raw == null || raw.trim().isEmpty || raw == 'null') {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      return;
    }

    String imgData = raw.trim();

    // 1️⃣ Base64 String စစ်ဆေးခြင်း
    if (imgData.startsWith('data:image') ||
        (!imgData.startsWith('http') && !imgData.contains('/'))) {
      try {
        String pureBase64 =
            imgData.contains(',') ? imgData.split(',')[1] : imgData;
        final decoded = base64Decode(pureBase64);
        if (mounted) {
          setState(() {
            _bytes = decoded;
            _isLoading = false;
            _hasError = false;
          });
        }
        return;
      } catch (e) {
        if (mounted)
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        return;
      }
    }

    // 2️⃣ URL Format ပြင်ဆင်ခြင်း
    String url = imgData;
    if (!url.startsWith('http://') && !url.startsWith('http://')) {
      String baseUrl = ApiConfig.baseUrl;
      if (baseUrl.endsWith('/'))
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      if (!url.startsWith('/')) url = '/$url';
      url = '$baseUrl$url';
    }

    // 💡 Ngrok CORS Redirect Error မတက်အောင် http:// ကို https:// သို့ Force ပြောင်းခြင်း
    if (url.contains('ngrok') && url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }

    // 3️⃣ HTTP Request ဖြင့် ngrok Header ပါဝင်စွာ Bytes ဆွဲယူခြင်း
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _bytes = response.bodyBytes;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        if (mounted)
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFFEFF6FF),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_hasError || _bytes == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              color: Color(0xFF2563EB),
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Upload Image",
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2563EB),
            ),
          ),
          Text(
            "PNG, JPG up to 5MB",
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      );
    }

    return Image.memory(
      _bytes!,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFF94A3B8),
            size: 24,
          ),
    );
  }
}
