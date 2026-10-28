import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loan_application/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_languages.dart';

class CheckLoanPage extends StatefulWidget {
  const CheckLoanPage({Key? key}) : super(key: key);

  @override
  State<CheckLoanPage> createState() => _CheckLoanPageState();
}

class _CheckLoanPageState extends State<CheckLoanPage> {
  bool isLoading = true;
  String message = "";

  String loanAmount = "0";
  String remainAmount = "0";
  String remainMonth = "0";
  String nextPaymentAmount = "0";
  String nextPaymentDate = "-";
  String paidDate = "-";

  @override
  void initState() {
    super.initState();
    getLoan();
  }

  // 💡 ၁။ ဂဏန်းများကို မြန်မာဂဏန်း (၀-၉) အဖြစ် တိုက်ရိုက်ပြောင်းပေးသည့် Function
  String toMyanmarNum(dynamic input) {
    if (input == null || input.toString().isEmpty || input.toString() == "null")
      return "၀";
    String str = input.toString();
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const myanmarDigits = ['၀', '၁', '၂', '၃', '၄', '၅', '၆', '၇', '၈', '၉'];

    for (int i = 0; i < englishDigits.length; i++) {
      str = str.replaceAll(englishDigits[i], myanmarDigits[i]);
    }
    return str;
  }

  // 💡 ၂။ ထောင်ဂဏန်း ကော်မာပါဝင်သော မြန်မာဂဏန်း Format
  String formatCurrencyMyanmar(dynamic input) {
    if (input == null || input.toString().isEmpty) return "၀";
    int val = int.tryParse(input.toString()) ?? 0;
    final formatter = NumberFormat("#,##0", "en_US");
    String formatted = formatter.format(val);
    return toMyanmarNum(formatted);
  }

  int parseSafeInt(dynamic val) {
    if (val == null) return 0;
    return (double.tryParse(val.toString()) ?? 0).toInt();
  }

  String formatDateOnly(dynamic rawDate) {
    if (rawDate == null ||
        rawDate.toString().isEmpty ||
        rawDate.toString() == "null") {
      return "-";
    }
    try {
      DateTime parsedDate = DateTime.parse(rawDate.toString().trim());
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return rawDate.toString();
    }
  }

  Future<void> getLoan() async {
    setState(() {
      isLoading = true;
      message = "";
    });

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");

    print("=== DEBUG: USER EMAIL -> $email ===");

    if (email == null) {
      setState(() {
        isLoading = false;
        message = AppLanguage.text("User not found", "အသုံးပြုသူ မတွေ့ပါ");
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.usercheck),
        headers: {
          "Content-Type": "application/json",
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({"email": email}),
      );

      print("=== DEBUG: API RESPONSE STATUS -> ${response.statusCode} ===");
      print("=== DEBUG: API RESPONSE BODY -> ${response.body} ===");

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        setState(() {
          int loanAmt = parseSafeInt(data["loan_amount"]);
          int remainAmt = parseSafeInt(data["remain_amount"]);
          int remainMth = parseSafeInt(data["remain_month"]);
          int nextPayAmt = parseSafeInt(data["next_payment_amount"]);

          // Fallback Calculation
          if (nextPayAmt == 0 && remainMth > 0) {
            nextPayAmt = (remainAmt / remainMth).toInt();
          }

          loanAmount = loanAmt.toString();
          remainAmount = remainAmt.toString();
          remainMonth = remainMth.toString();
          nextPaymentAmount = nextPayAmt.toString();

          nextPaymentDate = formatDateOnly(data["next_payment_date"]);
          paidDate = formatDateOnly(data["paid_date"]);

          isLoading = false;
        });
      } else {
        setState(() {
          message = data["message"] ?? "အချက်အလက်များ ခေါ်ယူ၍ မရပါ။";
          isLoading = false;
        });
      }
    } catch (e) {
      print("=== DEBUG: FETCH ERROR -> $e ===");
      setState(() {
        message = AppLanguage.text(
          "Connection Error",
          "ချိတ်ဆက်မှု အမှားဖြစ်နေသည်",
        );
        isLoading = false;
      });
    }
  }

  Widget infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff0D47A1), Color(0xff1976D2)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 60,
          ),
          const SizedBox(height: 15),
          Text(
            AppLanguage.text("Current Loan", "မူလချေးငွေ"),
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            "${formatCurrencyMyanmar(loanAmount)} ကျပ်",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FC),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLanguage.text("Check Loan", "ချေးငွေစစ်ဆေးရန်"),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff0D47A1), Color(0xff1976D2)],
            ),
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : message.isNotEmpty
              ? Center(child: Text(message))
              : RefreshIndicator(
                onRefresh: getLoan,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    summaryCard(),
                    const SizedBox(height: 25),

                    // ၁။ ကျန်ရှိငွေပမာဏ
                    infoCard(
                      icon: Icons.payments,
                      color: Colors.red,
                      title: AppLanguage.text(
                        "Remaining Amount",
                        "ကျန်ရှိငွေပမာဏ",
                      ),
                      value: "${formatCurrencyMyanmar(remainAmount)} ကျပ်",
                    ),

                    // ၂။ ကျန်ရှိလ
                    infoCard(
                      icon: Icons.calendar_today,
                      color: Colors.orange,
                      title: AppLanguage.text("Remaining Months", "ကျန်ရှိလ"),
                      value: "${toMyanmarNum(remainMonth)} လ",
                    ),

                    // ၃။ ပြန်ဆပ်ရမည့်ပမာဏ
                    infoCard(
                      icon: Icons.monetization_on,
                      color: Colors.teal,
                      title: AppLanguage.text(
                        "Next Payment Amount",
                        "ပြန်ဆပ်ရမည့်ပမာဏ",
                      ),
                      value: "${formatCurrencyMyanmar(nextPaymentAmount)} ကျပ်",
                    ),

                    // ၄။ နောက်ထပ် ပေးချေရမည့်နေ့
                    infoCard(
                      icon: Icons.event_available,
                      color: Colors.green,
                      title: AppLanguage.text(
                        "Next Payment Date",
                        "နောက်ထပ်ပေးချေရမည့်နေ့",
                      ),
                      value: toMyanmarNum(nextPaymentDate),
                    ),

                    // ၅။ နောက်ဆုံး ပေးချေခဲ့သည့်နေ့
                    if (paidDate != "-")
                      infoCard(
                        icon: Icons.history,
                        color: Colors.purple,
                        title: AppLanguage.text(
                          "Last Paid Date",
                          "နောက်ဆုံး ပေးချေခဲ့သည့်နေ့",
                        ),
                        value: toMyanmarNum(paidDate),
                      ),
                  ],
                ),
              ),
    );
  }
}
