import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loan_application/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'app_languages.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List histories = [];
  bool loading = true;
  String? errorMessage;
  String selectedFilter = AppLanguage.text(
    "All",
    "အားလုံး",
  );
  String searchQuery = '';

  @override
  void initState() {
    super.initState();

    selectedFilter = AppLanguage.text(
      "All",
      "အားလုံး",
    );

    fetchHistory();
  }

  Future<void> fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String email = prefs.getString("email") ?? "";

    final url = Uri.parse(
      ApiConfig.paymenthistory+"?email=$email",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          histories = json.decode(response.body);
          loading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          loading = false;
          errorMessage = "Failed to load history";
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = "Network error occurred";
      });
      print(e);
    }
  }

  int get countAll => histories.length;
  int get countApproved => histories.where((item) => item['status'].toString().toLowerCase() == 'approved').length;
  int get countPending => histories.where((item) => item['status'].toString().toLowerCase() == 'pending').length;
  int get countRejected => histories.where((item) => item['status'].toString().toLowerCase() == 'rejected').length;

  List get filteredHistories {
    List result = histories;

    String filter = "all";

    if (selectedFilter ==
        AppLanguage.text("Approved", "အတည်ပြုပြီး")) {

      filter = "approved";

    } else if (selectedFilter ==
        AppLanguage.text("Pending", "စောင့်ဆိုင်းဆဲ")) {

      filter = "pending";

    } else if (selectedFilter ==
        AppLanguage.text("Rejected", "ငြင်းပယ်")) {

      filter = "rejected";
    }


    if (filter != "all") {

      result = result.where((item) {

        return item['status']
            .toString()
            .toLowerCase() == filter;

      }).toList();

    }

    // Filter by search
    if (searchQuery.isNotEmpty) {
      result = result.where((item) {
        String paymentMethod =
            item['payment_method']?.toString().toLowerCase() ?? '';

        String amount =
            item['amount']?.toString() ?? '';

        return paymentMethod.contains(searchQuery.toLowerCase()) ||
            amount.contains(searchQuery);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Column(
          children: [
          // Blue Header Section
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xff1E4AA8),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    AppLanguage.text(
                      "Payment History",
                      "ငွေပေးချေမှု မှတ်တမ်း",
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1E4AA8),
                    ),
                  ),
                ],
              ),
            ),
          // White Content Section
          Expanded(
            child: Container(
              color: const Color(0xFFF5F7FA),
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE8ECF0),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xff1E4AA8),
                                  size: 22,
                                ),
                                hintText: AppLanguage.text(
                                  "Search by payment method or amount...",
                                  "ရှာဖွေပါ  ..",
                                ),
                                hintStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,

                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE8ECF0),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: Color(0xFF1A6DD4),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Filter Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          AppLanguage.text("All", "အားလုံး"),
                          selectedFilter == AppLanguage.text("All", "အားလုံး"),
                        ),

                        _buildFilterChip(
                          AppLanguage.text("Approved", "အတည်ပြုပြီး"),
                          selectedFilter == AppLanguage.text("Approved", "အတည်ပြုပြီး"),
                        ),

                        _buildFilterChip(
                          AppLanguage.text("Pending", "စောင့်ဆိုင်းဆဲ"),
                          selectedFilter == AppLanguage.text("Pending", "စောင့်ဆိုင်းဆဲ"),
                        ),

                        _buildFilterChip(
                          AppLanguage.text("Rejected", "ငြင်းပယ်"),
                          selectedFilter == AppLanguage.text("Rejected", "ငြင်းပယ်"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // History List
                  Expanded(
                    child: filteredHistories.isEmpty
                        ? Center(
                      child: Text(
                        AppLanguage.text(
                          "No history found",
                          "မှတ်တမ်းမတွေ့ပါ",
                        ),
                        style: const TextStyle(
                          color: Color(0xFF9AA6B5),
                          fontSize: 14,
                        ),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: filteredHistories.length,
                      itemBuilder: (context, index) {
                        var item = filteredHistories[index];
                        return _buildHistoryCard(item, index, filteredHistories.length);
                      },
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

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required Color countColor,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: bgColor == Colors.white
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 22),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: countColor,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7A8A),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A6DD4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A6DD4) : const Color(0xFFD0D5DD),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF344054),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Filter Bar Widget ( Overflow Error ကို ရှင်းရန် SingleChildScrollView သုံးထားပါသည် )
  Widget _buildFilterBar() {
    final List<String> filters = [
      'အားလုံး',
      'အတည်ပြုပြီး',
      'စောင့်ဆိုင်းဆဲ',
      'ငြင်းပယ်',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildFilterChip(filter, isSelected),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMiniCard(String value, String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, int index, int total) {
    String category = item['category']?.toString() ?? 'Loan';
    String amount = item['amount']?.toString() ?? '0';

    String paymentMethod =
        item['payment_method']?.toString() ?? '-';

    String transactionId =
        item['transaction_id']?.toString() ?? '-';

    String transferDate =
        item['transfer_date']?.toString() ?? '-';

    String remark =
        item['remark']?.toString() ?? '';

    String status =
        item['status']?.toString() ?? 'pending';

    String date =
        item['created_at']?.toString() ?? '';

    // Format date
    String formattedDate = '';
    try {
      if (date.isNotEmpty) {
        DateTime dt = DateTime.parse(date);
        formattedDate = DateFormat('dd MMM yyyy').format(dt);
      }
    } catch (e) {}

    // Format amount
    String formattedAmount = '';
    try {
      double numAmount = double.parse(amount.replaceAll(',', ''));
      formattedAmount = NumberFormat('#,##0').format(numAmount);
    } catch (e) {
      formattedAmount = amount;
    }

    // Format insurance


    // Status properties
    Map<String, dynamic> statusProps = _getStatusProperties(status);
    IconData categoryIcon = _getCategoryIcon(category);

    bool isLast = index == total - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline dots
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusProps['sideColor'],
                    border: Border.all(
                      color: statusProps['sideColor'],
                      width: 2,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE8ECF0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFF0F2F5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Icon, Title, Date, Status
                  // Row 1: Icon, Title, Date, Status
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF2FA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.payments_rounded,
                                color: Color(0xFF1A6DD4),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    paymentMethod,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A2B3C),
                                    ),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9AA6B5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusProps['bgColor'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusProps['icon'],
                              size: 14,
                              color: statusProps['color'],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status.toLowerCase() == "approved"
                                  ? AppLanguage.text(
                                "Approved",
                                "အတည်ပြုပြီး",
                              )
                                  : status.toLowerCase() == "pending"
                                  ? AppLanguage.text(
                                "Pending",
                                "စောင့်ဆိုင်းဆဲ",
                              )
                                  : status.toLowerCase() == "rejected"
                                  ? AppLanguage.text(
                                "Rejected",
                                "ငြင်းပယ်",
                              )
                                  : status,
                              style: TextStyle(
                                color: statusProps['color'],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Row 2: Amount + Details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Amount
                      SizedBox(
                        width: 90,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLanguage.text(
                                "MMK",
                                "ကျပ်",
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            Text(
                              formattedAmount,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A6DD4),
                              ),
                            ),
                          ],
                        ),
                      ),


                      const SizedBox(width: 12),


                      Container(
                        width: 1,
                        height: 85,
                        color: const Color(0xFFE8ECF0),
                      ),


                      const SizedBox(width: 12),


                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            _detailItem(
                              Icons.calendar_month_outlined,
                              paymentMethod,
                            ),


                            const SizedBox(height: 4),


                            _detailItem(
                              Icons.verified_outlined,
                              AppLanguage.text(
                                "TX: $transactionId",
                                "ငွေလွှဲအမှတ်: $transactionId",
                              ),
                            ),


                            const SizedBox(height: 4),


                            _detailItem(
                              Icons.access_time,
                              transferDate,
                            ),


                            const SizedBox(height: 4),


                            _detailItem(
                              Icons.comment_outlined,
                              remark.isEmpty
                                  ? AppLanguage.text(
                                "No Remark",
                                "မှတ်ချက်မရှိပါ",
                              )
                                  : remark,
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusProperties(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return {
          'icon': Icons.check_circle_outline,
          'color': const Color(0xFF0F9D58),
          'bgColor': const Color(0xFFE8F5E9),
          'sideColor': const Color(0xFF0F9D58),
        };
      case 'pending':
        return {
          'icon': Icons.hourglass_empty,
          'color': const Color(0xFFF4B400),
          'bgColor': const Color(0xFFFEF7E0),
          'sideColor': const Color(0xFFF4B400),
        };
      case 'rejected':
        return {
          'icon': Icons.cancel_outlined,
          'color': const Color(0xFFDB4437),
          'bgColor': const Color(0xFFFCE8E6),
          'sideColor': const Color(0xFFDB4437),
        };
      default:
        return {
          'icon': Icons.info_outline,
          'color': Colors.grey,
          'bgColor': const Color(0xFFF5F7FA),
          'sideColor': Colors.grey,
        };
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'personal loan':
        return Icons.person_outline;
      case 'business loan':
        return Icons.business_center_outlined;
      case 'education loan':
        return Icons.school_outlined;
      default:
        return Icons.attach_money;
    }
  }
}

Widget _detailItem(
    IconData icon,
    String text,
    ) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      Icon(
        icon,
        size: 14,
        color: Colors.black87,
      ),

      const SizedBox(width: 4),


      Expanded(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ),

    ],
  );
}