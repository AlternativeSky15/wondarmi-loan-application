// lib/Admin/admin_payment_request_detail.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:loan_application/constant.dart';

class AdminPaymentRequestDetailScreen extends StatefulWidget {
  final Map<String, dynamic> paymentRequest;

  const AdminPaymentRequestDetailScreen({
    Key? key,
    required this.paymentRequest,
  }) : super(key: key);

  @override
  State<AdminPaymentRequestDetailScreen> createState() =>
      _AdminPaymentRequestDetailScreenState();
}

class _AdminPaymentRequestDetailScreenState
    extends State<AdminPaymentRequestDetailScreen> {
  bool _isSubmitting = false;

  // 🎨 Modern Enterprise Design Tokens
  static const Color primaryColor = Color(0xFF0F43A2);
  static const Color primaryDark = Color(0xFF0A2E73);
  static const Color primaryAccent = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardBorderColor = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color successColor = Color(0xFF10B981);
  static const Color dangerColor = Color(0xFFEF4444);

  Future<void> _confirmReceived() async {
    final int id = widget.paymentRequest['id'];
    String url = ApiConfig.confirmpayment + "$id/";

    if (url.startsWith('http://') && url.contains('ngrok')) {
      url = url.replaceFirst('http://', 'https://');
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 200) {
        _showResultDialog(
          "ငွေပေးချေမှု အတည်ပြုခြင်း အောင်မြင်ပါသည်",
          success: true,
        );
      } else {
        _showResultDialog(
          "ငွေပေးချေမှုကို အတည်ပြုရန် မအောင်မြင်ပါ: ${response.body}",
          success: false,
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showResultDialog("Error: $e", success: false);
    }
  }

  Future<void> _rejectPayment(String reason) async {
    final int id = widget.paymentRequest['id'];
    String url = ApiConfig.rejectpayment + "$id/";

    if (url.startsWith('http://') && url.contains('ngrok')) {
      url = url.replaceFirst('http://', 'https://');
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
        body: {"admin_remark": reason},
      );

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 200) {
        _showResultDialog("ငွေပေးချေမှုကို ပယ်ချခဲ့သည်", success: true);
      } else {
        _showResultDialog(
          "ငွေပေးချေမှုကို အတည်ပြုရန် မအောင်မြင်ပါ: ${response.body}",
          success: false,
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showResultDialog("Error: $e", success: false);
    }
  }

  void _showResultDialog(String message, {required bool success}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color:
                      success
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: success ? successColor : dangerColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                success ? "အောင်မြင်ပါသည်" : "မအောင်မြင်ပါ",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (success) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: Text(
                    "အိုကေ",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRejectDialog() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: dangerColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "ငွေပေးချေမှုကို ငြင်းပယ်ပါ",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ငြင်းပယ်ခြင်းအတွက် အကြောင်းပြချက်ကို ထည့်သွင်းပါ:",
                style: GoogleFonts.poppins(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 13, color: textPrimary),
                decoration: InputDecoration(
                  hintText: "ဥပမာ - ငွေလွှဲပမာဏ မကိုက်ညီပါ",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: cardBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: cardBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: primaryAccent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "ပယ်ဖျက်ပါ",
                style: GoogleFonts.poppins(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("ကျေးဇူးပြု၍ အကြောင်းပြချက်တစ်ခုထည့်ပါ"),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
                _rejectPayment(reason);
              },
              child: Text(
                "ငြင်းပယ်သည်",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty || text == '-') return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label ကို ကူးယူပြီးပါပြီ"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: primaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.paymentRequest;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: false,
        title: Text(
          "ငွေပေးချေမှု အတည်ပြုခြင်း",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status Banner Card
                _buildAmountBanner(data),
                const SizedBox(height: 16),

                // Customer Info Card
                _sectionCard(
                  title: "ငွေချေးသူ အချက်အလက်",
                  icon: Icons.person_rounded,
                  badgeText: "Customer",
                  rows: [
                    _row("အမည်", "${data['customer_name'] ?? '-'}"),
                    _row(
                      "ဖုန်းနံပါတ်",
                      "${data['customer_phone'] ?? '-'}",
                      canCopy: true,
                    ),
                    _row("အီးမေးလ်လိပ်စာ", "${data['customer_email'] ?? '-'}"),
                  ],
                ),
                const SizedBox(height: 16),

                // Loan Account Details Card
                _sectionCard(
                  title: "ချေးငွေစာရင်း အသေးစိတ်",
                  icon: Icons.account_balance_rounded,
                  rows: [
                    _row("ချေးငွေအမှတ်စဉ်", "#${data['loan_id'] ?? '-'}"),
                    _row("ချေးငွေပမာဏ", "${data['loan_amount'] ?? '-'} ကျပ်"),
                    _row(
                      "ကျန်ရှိငွေပမာဏ",
                      "${data['remaining_amount'] ?? '-'} ကျပ်",
                      isHighlight: true,
                      highlightColor: dangerColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Payment Details Card
                _sectionCard(
                  title: "ငွေပေးချေမှု အသေးစိတ်",
                  icon: Icons.payments_rounded,
                  rows: [
                    _row(
                      "ငွေပေးချေမှုပမာဏ",
                      "${data['payment_amount'] ?? '-'} MMK",
                      isHighlight: true,
                    ),
                    _row("ငွေပေးချေစနစ်", "${data['payment_method'] ?? '-'}"),
                    _row(
                      "ဘဏ်အကောင့်/ဖုန်း",
                      "${data['bank_account_or_phone'] ?? '-'}",
                      canCopy: true,
                    ),
                    _row(
                      "ငွေလွှဲသည့်အမှတ်စဉ်",
                      "${data['transaction_id'] ?? '-'}",
                      canCopy: true,
                      isCode: true,
                    ),
                    _row(
                      "ငွေလွှဲသည့်ရက်စွဲ",
                      "${data['transfer_date'] ?? '-'}",
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Screenshot Payment Receipt Card
                _paymentImageCard(data['payment_image']),
                const SizedBox(height: 28),

                // Actions Button Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: successColor.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: successColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _confirmReceived,
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                          ),
                          label: Text(
                            "အတည်ပြုပါ",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: dangerColor.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: dangerColor,
                            elevation: 0,
                            side: const BorderSide(
                              color: dangerColor,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _showRejectDialog,
                          icon: const Icon(
                            Icons.cancel_rounded,
                            size: 20,
                            color: dangerColor,
                          ),
                          label: Text(
                            "ငြင်းပယ်ပါ",
                            style: GoogleFonts.poppins(
                              color: dangerColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        "လုပ်ဆောင်နေပါသည်...",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Modern Top Amount Highlight Card
  Widget _buildAmountBanner(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "အတည်ပြုရန် တောင်းဆိုထားသော ပမာဏ",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${data['payment_method'] ?? 'Payment'}",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${data['payment_amount'] ?? '0'}",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "MMK",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    String? badgeText,
    required List<Widget> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F43A2).withOpacity(0.03),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: primaryAccent),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              if (badgeText != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool isHighlight = false,
    Color? highlightColor,
    bool canCopy = false,
    bool isCode = false,
  }) {
    final displayColor =
        isHighlight ? (highlightColor ?? primaryAccent) : textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: displayColor,
                      fontWeight:
                          isHighlight ? FontWeight.bold : FontWeight.w600,
                      letterSpacing: isCode ? 0.5 : 0,
                    ),
                  ),
                ),
                if (canCopy && value != '-') ...[
                  InkWell(
                    onTap: () => _copyToClipboard(value, label),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 15,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentImageCard(String? imageUrl) {
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F43A2).withOpacity(0.03),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: primaryAccent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "ငွေပေးချေမှု စခရင်ရှော့",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          if (!hasImage)
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorderColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.no_photography_outlined,
                    color: Color(0xFF94A3B8),
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "စခရင်ရှော့ဓာတ်ပုံ အပ်လုဒ်မလုပ်ပါ။",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GestureDetector(
                onTap: () => _showFullImage(imageUrl),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // 💡 Ngrok Safe Image Widget
                    SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: NgrokImage(imageString: imageUrl),
                    ),
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "ကြည့်ရှုရန်နှိပ်ပါ",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  child: NgrokImage(imageString: imageUrl, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 💡 Ngrok / CORS / HTTP Redirect များကို ကျော်လွှား၍ ပုံဆွဲယူပေးသော Widget
class NgrokImage extends StatefulWidget {
  final String? imageString;
  final BoxFit fit;

  const NgrokImage({
    super.key,
    required this.imageString,
    this.fit = BoxFit.cover,
  });

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
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      String baseUrl = ApiConfig.baseUrl;
      if (baseUrl.endsWith('/'))
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      if (!url.startsWith('/')) url = '/$url';
      url = '$baseUrl$url';
    }

    // 💡 Ngrok CORS Redirect Error မတက်အောင် http:// ကို https:// သို့ Force ပြောင်းခြင်း
    // 💡 Ngrok CORS Redirect Error မတက်အောင် http:// ကို https:// သို့ Force ပြောင်းခြင်း
    // 💡 Ngrok CORS Redirect Error မတက်အောင် http:// ကို https:// သို့ Force ပြောင်းခြင်း
    if (url.startsWith('http://') && url.contains('ngrok')) {
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
        color: const Color(0xFFF8FAFC),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_hasError || _bytes == null) {
      return Container(
        color: const Color(0xFFF8FAFC),
        child: Center(
          child: Text(
            "ပုံတင်၍မရပါ",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    return Image.memory(
      _bytes!,
      fit: widget.fit,
      errorBuilder:
          (_, __, ___) => Container(
            color: const Color(0xFFF8FAFC),
            child: Center(
              child: Text(
                "ပုံတင်၍မရပါ",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ),
    );
  }
}
