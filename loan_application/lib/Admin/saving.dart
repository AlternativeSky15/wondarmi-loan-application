import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loan_application/Admin/admin_category_screen.dart';
import 'package:loan_application/Admin/admin_dashboard.dart';
import 'package:loan_application/Admin/admin_seen_user.dart';
import 'package:loan_application/Admin/payment_schedule.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  List data = [];
  bool isLoading = true;

  final String apiUrl = "http://127.0.0.1:8000/api/voluntary-savings/";

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final res = await http.get(Uri.parse(apiUrl));

    if (res.statusCode == 200) {
      setState(() {
        data = jsonDecode(res.body);
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> withdrawMoney(
    String userId,
    double amount,
  ) async {
    final res = await http.post(
      Uri.parse("http://127.0.0.1:8000/api/withdraw/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "amount": amount}),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return body;
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(body['error'] ?? "Error")));
      return null;
    }
  }

  // ================= DEPOSIT =================
  Future<void> depositMoney(String userId, int amount) async {
    final res = await http.post(
      Uri.parse("http://127.0.0.1:8000/api/deposit/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "amount": amount}),
    );

    final body = jsonDecode(res.body);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(body['message'])));

      fetchData(); // UI refresh (no change UI)
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(body['error'])));
    }
  }

  // ================= DEPOSIT DIALOG =================
  void showDepositDialog(Map item) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "အစုငွေ ထည့်သွင်းခြင်း",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("နာမည် - ${item['username'] ?? ""}"),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Account - ${item['account_number'] ?? ""}"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "ငွေပမာဏ (MMK)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ပိတ်မည်"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        final amount = int.tryParse(amountController.text) ?? 0;

                        if (amount < 5000) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("အနည်းဆုံး 5000 MMK ထည့်ရမည်"),
                            ),
                          );
                          return;
                        }

                        depositMoney(item['user_id'].toString(), amount);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("အတည်ပြုမည်"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= WITHDRAW DIALOG =================
  void showWithdrawDialog(Map item, int index) {
    final TextEditingController amountController = TextEditingController();

    double totalSavings =
        double.tryParse(
          item['total_savings'].toString().replaceAll(',', '').split(' ')[0],
        ) ??
        0;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 400,

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "ငွေထုတ်ခြင်း",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text("နာမည် - ${item['username'] ?? ""}"),
                const SizedBox(height: 10),
                Text("လက်ကျန်ငွေ - ${item['total_savings'] ?? ""}"),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "ထုတ်မည့်ငွေပမာဏ",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ပိတ်မည်"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        double amount =
                            double.tryParse(amountController.text) ?? 0;

                        if (amount < 5000) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("အနည်းဆုံး 5000 ထုတ်ရမည်"),
                            ),
                          );
                          return;
                        }

                        if (amount > totalSavings) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("လက်ကျန်ငွေထက် များနေပါသည် ❌"),
                            ),
                          );
                          return;
                        }

                        final result = await withdrawMoney(
                          item['user_id'].toString(),
                          amount,
                        );

                        if (result != null) {
                          double newBalance =
                              double.tryParse(
                                result['remaining_balance'].toString(),
                              ) ??
                              0;

                          setState(() {
                            data[index]['total_savings'] =
                                newBalance.toStringAsFixed(2) + " MMK";

                            double monthlyInterest = (newBalance * 0.14) / 12;

                            data[index]['monthly_interest_14'] =
                                monthlyInterest.toStringAsFixed(2) + " MMK";
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("ထုတ်ယူမှု အောင်မြင်ပါသည်"),
                            ),
                          );
                        }

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("ထုတ်မည်"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            color: const Color(0xFF1B254B),
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text(
                  "WONNAMI Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _sidebarItem(
                  Icons.dashboard,
                  "မူလစာမျက်နှာ",
                  false,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDashboard()),
                    );
                  },
                ),
                _sidebarItem(
                  Icons.monetization_on,
                  "ချေးငွေအမျိုးအစားများ",
                  false,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoanCategoriesScreen(),
                      ),
                    );
                  },
                ),
                _sidebarItem(
                  Icons.people,
                  "အသုံးပြုသူများ",
                  false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminUsersScreen(),
                      ),
                    );
                  },
                ),
                _sidebarItem(
                  Icons.calendar_month,
                  "ပြန်ဆပ်ရမည့်ငွေဇယား",
                  false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RepaymentSchedulePage(),
                      ),
                    );
                  },
                ),
                _sidebarItem(
                  Icons.savings,
                  "ဆန္ဒအလျောက်စုငွေ",
                  false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔷 HEADER BAR
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "🐷 ဆန္ဒအလျောက် အစုငွေစာရင်းများ (ငွေသွင်း/ထုတ်)",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.person_add),
                                  label: const Text("စုဆောင်းသူအသစ်ထည့်"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // 🔷 TABLE HEADER
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: const [
                                  _Header("စဉ်", flex: 1),
                                  _Header("နာမည်", flex: 2),
                                  _Header("အကောင့်နံပါတ်", flex: 2),
                                  _Header("စုစုပေါင်းစုငွေ", flex: 2),
                                  _Header("လစဉ်အတိုး (၁၄%)", flex: 2),
                                  _Header("လုပ်ဆောင်ချက်", flex: 3),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // 🔷 DATA ROWS
                            Expanded(
                              child: ListView.builder(
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  final item = data[index];

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 5,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 5),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _Cell("${index + 1}", flex: 1),

                                        _Cell(item['username'] ?? "", flex: 2),
                                        _Cell(item['account_number'] ?? "", flex: 2),

                                        // Expanded(
                                        //   flex: 2,
                                        //   child: Container(
                                        //     padding: const EdgeInsets.symmetric(
                                        //       vertical: 5,
                                        //       horizontal: 2,
                                        //     ),
                                        //     decoration: BoxDecoration(
                                        //        color: Colors.cyan,
                                        //       borderRadius:
                                        //           BorderRadius.circular(10),
                                        //     ),
                                        //     child: Text(
                                        //       item['account_number'] ?? "",
                                        //       style: const TextStyle(
                                        //         color: Colors.white,
                                        //       ),
                                        //     ),
                                        //   ),
                                        // ),

                                        _Cell(
                                          item['total_savings'] ?? "",
                                          flex: 2,
                                        ),

                                        _Cell(
                                          item['monthly_interest_14'] ?? "",
                                          flex: 2,
                                        ),

                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  showDepositDialog(item);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text("+ ငွေသွင်း"),
                                              ),
                                              const SizedBox(width: 10),
                                              OutlinedButton(
                                                onPressed: () {
                                                  showWithdrawDialog(
                                                    item,
                                                    index,
                                                  );
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                    color: Colors.red,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  "- ငွေထုတ်",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
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
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sidebarItem(
  IconData icon,
  String title,
  bool isSelected, {
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: isSelected ? Colors.blue : Colors.white),
    title: Text(
      title,
      style: TextStyle(color: isSelected ? Colors.blue : Colors.white),
    ),
    onTap: onTap,
  );
}

class _Header extends StatelessWidget {
  final String text;
  final int flex;

  const _Header(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final int flex;

  const _Cell(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: Text(text));
  }
}
